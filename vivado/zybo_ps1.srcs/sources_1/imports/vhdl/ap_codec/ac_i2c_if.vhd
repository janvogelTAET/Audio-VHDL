-------------------------------------------------------------------------------
-- Project: DIDE Audio Processing
-- Entity : ac_i2c_if
-- Author : SzP, Waj
-------------------------------------------------------------------------------
-- Description:
-- I2C interface for initializing the SSM2603 audio codec.
-- Notes:
-- * ac_status (LED) encoding:
--      led(0): init + verify OK, no errors
--      led(1): write_error
--      led(2): read_error
--      led(3): verify_error
-- * The codec can be reconfigured during runtime at ac_mode_pi to:
--   - analog loopback
--   - digital line input
--   - digital microphone input
-- * Soft mute can be enabled via ac_dac_mute_pi
-- * While codec reconfig is ongoing, ac_recfg_busy_po will be '1'.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.ac_ssm2603_pkg.all;
use work.ap_design_pkg.all;

entity ac_i2c_if is
  generic (
    g_init_idx  : natural := 1;                   -- index of init sequence to use (see ac_ssm2603_pkg)
    g_read_back : boolean := false;               -- 'true' = read back and verify init registers
    g_powup_wait_cycles : positive := 33_554_432; -- initial codec power-up settle wait at 100 MHz
    g_vmid_wait_cycles  : positive := 16_777_216  -- VMID settle wait before R9 activation at 100 MHz
  );
  port (
    clk_pi           : in  std_logic;                    -- 100 MHz system clock
    rst_pi           : in  std_logic;                    -- active-high ac_if reset
    ac_sda_pio       : inout std_logic;                  -- I2C SDA
    ac_scl_pio       : inout std_logic;                  -- I2C SCL
    ac_init_ok_po    : out std_logic;                    -- init + verify ok
    ac_status_po     : out std_logic_vector(3 downto 0); -- init status
    ac_mode_pi       : in t_codec_mode_sel;              -- requested codec operation mode
    ac_dac_mute_pi   : in std_logic;                     -- '1' = request DAC soft-mute
    ac_recfg_busy_po : out std_logic                     -- '1' while codec reconfig ongoing   
  );
end entity ac_i2c_if;

architecture rtl of ac_i2c_if is

  -- Mealy FSM state signals
  type state_t is (
    wait_powerup,
    start_write, wait_write,
    next_reg,
    wait_vmid,start_post_vmid, wait_post_vmid,
    start_read, wait_read, check_read,
    start_mute_write, wait_mute_write,
    done
  );
  signal state_q, state_d : state_t := wait_powerup;

  function max_positive(a : positive; b : positive) return positive is
  begin
    if a >= b then
      return a;
    else
      return b;
    end if;
  end function max_positive;

  -- Map the power-up init profile to the corresponding codec mode
  function select_initial_codec_mode return t_codec_mode_sel is
  begin
    case g_init_idx is
      when 0 =>
        return codec_mode_analog_loopback;
      when 2 =>
        return codec_mode_digital_mic;
      when others =>
        return codec_mode_digital_line;
    end case;
  end function select_initial_codec_mode;

  function map_codec_mode_to_init_index(
    c_mode : t_codec_mode_sel
  ) return natural is
  begin
    case c_mode is
      when codec_mode_analog_loopback =>
        return 0;
      when codec_mode_digital_mic =>
        return 2;
      when others =>
        return 1;
    end case;
  end function map_codec_mode_to_init_index;

  function select_init_reg_data(
    c_init_idx  : natural;
    c_reg_idx   : natural;
    c_dac_mute  : std_logic
  ) return reg_data_t is
    variable v_data : reg_data_t;
  begin
    v_data := c_ac_init(c_init_idx)(c_reg_idx).data;

    -- In analog loopback mode, muting must disable the analog bypass path
    -- itself because the digital DAC soft mute does not affect that route
    -- Keep the analog path otherwise quiet by ensuring bypass is off and the
    -- microphone input stays muted
    if (c_ac_init(c_init_idx)(c_reg_idx).addr = R4_ANALOG_PATH) and
       (c_init_idx = 0) and
       (c_dac_mute = '1') then
      v_data := "000000010";
    end if;

    -- SSM2603 R5 bit 3 is DAC soft mute. Keep the base init tables as the
    -- source of truth and only override that one runtime-controlled bit
    if c_ac_init(c_init_idx)(c_reg_idx).addr = R5_DIGITAL_PATH then
      v_data(3) := c_dac_mute;
    end if;

    return v_data;
  end function select_init_reg_data;

  constant C_INIT_CODEC_MODE : t_codec_mode_sel := select_initial_codec_mode;
  constant C_WAIT_CYCLES_MAX : positive := max_positive(
    g_powup_wait_cycles,
    g_vmid_wait_cycles
  );
  constant C_WAIT_CNT_W : positive := natural(ceil(log2(real(C_WAIT_CYCLES_MAX + 1))));

  -- index/counters
  signal init_idx_q, init_idx_d : integer range 0 to c_ac_init'high := g_init_idx;
  signal reg_idx_q, reg_idx_d : integer range 0 to c_ac_init(0)'high;
  signal counter_q, counter_d : unsigned(C_WAIT_CNT_W-1 downto 0) := (others => '0');

  -- sticky status flags
  signal write_error_q,  write_error_d  : std_logic := '0';
  signal read_error_q,   read_error_d   : std_logic := '0';
  signal verify_error_q, verify_error_d : std_logic := '0';
  signal init_complete_q, init_complete_d : std_logic := '0';
  signal verify_done_q,  verify_done_d  : std_logic := '0';
  signal init_ok_q : std_logic;
  signal active_mode_q, active_mode_d : t_codec_mode_sel := C_INIT_CODEC_MODE;
  signal target_mode_q, target_mode_d : t_codec_mode_sel := C_INIT_CODEC_MODE;
  signal active_dac_mute_q, active_dac_mute_d : std_logic := '0';

  --------------------------------------------------------------------
  -- i2c_wrapper interface (Mealy outputs)
  --------------------------------------------------------------------
  signal req_start : std_logic := '0';
  signal req_wr    : std_logic := '0';  -- '1' = write, '0' = read
  signal req_reg   : reg_addr_t := (others => '0');
  signal req_data  : reg_data_t := (others => '0');

  signal rsp_valid : std_logic;
  signal rsp_addr  : reg_addr_t;
  signal rsp_data  : reg_data_t;
  signal rsp_error : std_logic;

begin

  --------------------------------------------------------------------
  -- i2c_wrapper instance
  --------------------------------------------------------------------
  u_ac_i2c_wrapper : entity work.ac_i2c_wrapper
    port map (
      clk_pi    => clk_pi,
      rst_pi   => rst_pi,
      req_start => req_start,
      req_wr    => req_wr,
      req_reg   => req_reg,
      req_data  => req_data,
      rsp_valid => rsp_valid,
      rsp_addr  => rsp_addr,
      rsp_data  => rsp_data,
      rsp_error => rsp_error,
      ac_sda    => ac_sda_pio,
      ac_scl    => ac_scl_pio
    );

  -- assign status outputs
  ac_init_ok_po   <= init_ok_q;
  ac_status_po(0) <= init_ok_q;
  ac_status_po(1) <= write_error_q;
  ac_status_po(2) <= read_error_q;
  ac_status_po(3) <= verify_error_q;
  -- Treat only full mode rewrites as "reconfiguration busy". DAC soft-mute
  -- register writes are intentionally excluded so user mute stays responsive:
  ac_recfg_busy_po <= '1' when
    ((state_q /= done) and (state_q /= start_mute_write) and (state_q /= wait_mute_write)) or
    (ac_mode_pi /= active_mode_q) else '0';

  --------------------------------------------------------------------
  -- verification done register 
  -- generated only if read_back is used to avoid synthesis warning
  --------------------------------------------------------------------
  gen_ver: if g_read_back generate
    p_ver_reg : process(clk_pi, rst_pi)
    begin
      if rst_pi = '1' then
        verify_done_q   <= '0';
      elsif rising_edge(clk_pi) then
        verify_done_q   <= verify_done_d;
      end if;
    end process p_ver_reg;
  end generate gen_ver;

  --------------------------------------------------------------------
  -- State/Staus/register process
  --------------------------------------------------------------------
  p_reg : process(clk_pi, rst_pi)
  begin
    if rst_pi = '1' then
      state_q     <= wait_powerup;
      reg_idx_q   <= 0;
      counter_q       <= (others => '0');

      write_error_q     <= '0';
      read_error_q      <= '0';
      verify_error_q    <= '0';
      init_complete_q   <= '0';
      init_idx_q        <= g_init_idx;
      active_mode_q     <= C_INIT_CODEC_MODE;
      target_mode_q     <= C_INIT_CODEC_MODE;
      active_dac_mute_q <= '0';

      init_ok_q <= '0';

    elsif rising_edge(clk_pi) then
      state_q         <= state_d;
      reg_idx_q       <= reg_idx_d;
      counter_q       <= counter_d;

      write_error_q     <= write_error_d;
      read_error_q      <= read_error_d;
      verify_error_q    <= verify_error_d;
      init_complete_q   <= init_complete_d;
      init_idx_q        <= init_idx_d;
      active_mode_q     <= active_mode_d;
      target_mode_q     <= target_mode_d;
      active_dac_mute_q <= active_dac_mute_d;

      if g_read_back then
        -- check init_ok only after verify done
        if (init_complete_d = '1' and verify_done_d = '1' and
            write_error_d = '0' and read_error_d = '0' and
            verify_error_d = '0') then
          init_ok_q <= '1';
        end if;
      else
        -- check init_ok after init complete, no readback
        if (init_complete_d = '1' and write_error_d = '0') then
          init_ok_q <= '1';
        end if;
      end if;
      -- synthesis translate_off
      -- in simulation without I2C set init_ok after 2 sample periods 
      -- after reset
      init_ok_q <= '1' after 1 * TS_US; 
      -- synthesis translate_on
    end if;
  end process p_reg;

  --------------------------------------------------------------------
  -- Next-state + Mealy output logic
  --------------------------------------------------------------------
  p_cmb : process(all)
  begin
    -- Defaults (hold)
    state_d         <= state_q;
    reg_idx_d       <= reg_idx_q;
    counter_d       <= counter_q;

    write_error_d   <= write_error_q;
    read_error_d    <= read_error_q;
    verify_error_d  <= verify_error_q;
    init_complete_d <= init_complete_q;
    verify_done_d   <= verify_done_q;
    init_idx_d       <= init_idx_q;
    active_mode_d   <= active_mode_q;
    target_mode_d   <= target_mode_q;
    active_dac_mute_d <= active_dac_mute_q;

    case state_q is

      when wait_powerup =>
        if counter_q = to_unsigned(g_powup_wait_cycles - 1, C_WAIT_CNT_W) then
          counter_d <= (others => '0');
          reg_idx_d <= 0;
          state_d   <= start_write;
        else
          counter_d <= counter_q + 1;
        end if;

      ------------------------------------------------------------------
      -- Write ac_init registers up to VMID delay (R15, R0-R8)
      ------------------------------------------------------------------
      when start_write =>
        state_d <= wait_write;

      when wait_write =>
        if rsp_valid = '1' then
          if rsp_error = '1' then
            write_error_d <= '1';
          end if;
          state_d <= next_reg;
        end if;

      when next_reg =>
        if reg_idx_q >= (c_ac_init(init_idx_q)'high)-1 then
          counter_d  <= (others => '0');  -- reuse for VMID delay
          reg_idx_d  <= reg_idx_q + 1;    -- used after VMID delay
          state_d    <= wait_vmid;
        else
          reg_idx_d <= reg_idx_q + 1;
          state_d   <= start_write;
        end if;

      ------------------------------------------------------------------
      -- VMID delay (delay always included)
      ------------------------------------------------------------------
      when wait_vmid =>
        if counter_q = to_unsigned(g_vmid_wait_cycles - 1, C_WAIT_CNT_W) then
          counter_d <= (others => '0');
          state_d <= start_post_vmid;
        else
          counter_d <= counter_q + 1;
        end if;

      ------------------------------------------------------------------
      -- Write last ac_init register to enable digital core 
      -- (except in analog loopback) after VMID delay
      ------------------------------------------------------------------
      when start_post_vmid =>
        state_d <= wait_post_vmid;

      when wait_post_vmid =>
        if rsp_valid = '1' then
          if rsp_error = '1' then
            write_error_d <= '1';
          else
            init_complete_d <= '1';
            active_mode_d   <= target_mode_q;
            active_dac_mute_d <= ac_dac_mute_pi;
          end if;
          if g_read_back then
            state_d <= start_read;
          else
            state_d <= done;
          end if;
        end if;

      ------------------------------------------------------------------
      -- Read back and compare
      ------------------------------------------------------------------
      when start_read =>
        state_d <= wait_read;

      when wait_read =>
        if rsp_valid = '1' then
          if rsp_error = '1' then
            read_error_d <= '1';
          end if;
          state_d <= check_read;
        end if;

      when check_read =>
        if rsp_data = c_ac_init(init_idx_q)(5).data then
          verify_error_d <= '0';
        else
          verify_error_d <= '1';
        end if;
        verify_done_d <= '1';
        state_d       <= done;

      when done =>
        if ac_mode_pi /= active_mode_q then
          target_mode_d     <= ac_mode_pi;
          init_idx_d       <= map_codec_mode_to_init_index(ac_mode_pi);
          reg_idx_d        <= 0;
          counter_d        <= (others => '0');
          init_complete_d  <= '0';
          verify_done_d    <= '0';
          state_d          <= start_write;
        elsif ac_dac_mute_pi /= active_dac_mute_q then
          state_d <= start_mute_write;
        end if;

      when start_mute_write =>
        state_d <= wait_mute_write;

      when wait_mute_write =>
        if rsp_valid = '1' then
          if rsp_error = '1' then
            write_error_d <= '1';
          else
            active_dac_mute_d <= ac_dac_mute_pi;
          end if;
          state_d <= done;
        end if;

      when others =>
        state_d <= wait_powerup;

    end case;
  end process p_cmb;

  --------------------------------------------------------------------
  -- Output decode (Moore)
  --------------------------------------------------------------------
  p_out : process(all)
  begin
    req_start <= '0';
    req_wr    <= '0';
    req_reg   <= (others => '0');
    req_data  <= (others => '0');

    case state_q is
      when start_write | start_post_vmid =>
        req_wr    <= '1';
        req_reg   <= c_ac_init(init_idx_q)(reg_idx_q).addr;
        req_data  <= select_init_reg_data(init_idx_q, reg_idx_q, ac_dac_mute_pi);
        req_start <= '1';
      when start_mute_write =>
        req_wr    <= '1';
        if init_idx_q = 0 then
          req_reg  <= R4_ANALOG_PATH;
          req_data <= select_init_reg_data(init_idx_q, 5, ac_dac_mute_pi);
        else
          req_reg  <= R5_DIGITAL_PATH;
          req_data <= select_init_reg_data(init_idx_q, 6, ac_dac_mute_pi);
        end if;
        req_start <= '1';
      when start_read =>
        req_wr    <= '0';
        req_reg   <= c_ac_init(init_idx_q)(5).addr;
        req_data  <= (others => '0');
        req_start <= '1';
      when others =>
        null;
    end case;
  end process p_out;

end architecture rtl;
