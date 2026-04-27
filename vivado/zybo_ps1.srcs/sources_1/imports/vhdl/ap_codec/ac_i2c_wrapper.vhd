-------------------------------------------------------------------------------
-- Project: DIDE Audio Processing
-- Entity : ac_i2c_wrapper
-- Author : SzP, Waj
-------------------------------------------------------------------------------
-- Description:
-- SSM2603 register-transfer interface above the generic I2C master
-- Notes:
-- * Write transactions transfer the register address plus the ninth data bit in
--   the first payload byte and the remaining eight data bits in the second byte
-- * Read transactions use a non-destructive pointer write followed by a
--   two-byte readback
-- * The interface presents a single-request / single-response handshake to
--   the codec-control state machine
-- * Write transaction format:
--        S  DEV_ADDR(W)  A(S)
--           B15..B8      A(S)
--           B7..B0       A(S)
--           P
--
--        Byte0 = reg_addr(6 downto 0) & req_data(8)
--        Byte1 = req_data(7 downto 0)
--
-- * Read transaction format:
--        1) Pointer write (non-destructive, 1 byte):
--           S DEV_ADDR(W) A(S)
--             B15..B9 0   A(S)
--           P  (STOP is equivalent to repeated START for this codec)
--
--        2) Readback (2-byte read):
--           S DEV_ADDR(R) A(S)
--             B7..B0      A(M)
--             0..0 B8     A(M) (NACK)
--           P
--
--        rsp_data(7 downto 0) <= first byte  (B7..B0)
--        rsp_data(8)          <= second(0)  (B8)
--
-- * Handshake:
--    req_start : pulse '1' for one clk to start a transaction
--    req_wr    : '1' = 9-bit write, '0' = 9-bit read
--    req_reg   : register address (B15..B9)
--    req_data  : 9-bit data value (B8 & B7..B0)
--
--    rsp_valid : pulses '1' for one clk when operation completes
--    rsp_addr  : echoed register address
--    rsp_data  : read data for read transactions,
--                or the written value for writes
--    rsp_error : '1' if i2c_master saw any ack_error
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ac_i2c_wrapper is
  port (
    clk_pi    : in  std_logic;                    -- control clock for the transfer state machine
    rst_pi    : in  std_logic;                    -- active-high reset for the transfer state machine

    -- Request side
    req_start  : in  std_logic;                    -- single-cycle request strobe
    req_wr     : in  std_logic;                    -- '1' = write, '0' = read
    req_reg    : in  std_logic_vector(6 downto 0); -- codec register address
    req_data   : in  std_logic_vector(8 downto 0); -- codec register data including bit 8

    -- Response side
    rsp_valid  : out std_logic;                    -- single-cycle response-valid strobe
    rsp_addr   : out std_logic_vector(6 downto 0); -- echoed register address
    rsp_data   : out std_logic_vector(8 downto 0); -- returned or written register data
    rsp_error  : out std_logic;                    -- high if the underlying I2C transfer saw an acknowledge error

    -- Physical I2C pins
    ac_sda     : inout std_logic;                  -- physical codec I2C SDA line
    ac_scl     : inout std_logic                   -- physical codec I2C SCL line
  );
end entity ac_i2c_wrapper;

architecture rtl of ac_i2c_wrapper is

  constant I2C_ADDR_CODEC : std_logic_vector(6 downto 0) := "0011010"; -- 0x1A

  signal i2c_ena      : std_logic;
  signal i2c_addr     : std_logic_vector(6 downto 0);
  signal i2c_rw       : std_logic;
  signal i2c_data_wr  : std_logic_vector(7 downto 0);
  signal i2c_busy     : std_logic;
  signal i2c_data_rd  : std_logic_vector(7 downto 0);
  signal i2c_ack_err  : std_logic;

  signal i2c_ena_q     : std_logic := '0';
  signal i2c_ena_d     : std_logic := '0';
  signal i2c_addr_q    : std_logic_vector(6 downto 0) := (others => '0');
  signal i2c_addr_d    : std_logic_vector(6 downto 0) := (others => '0');
  signal i2c_rw_q      : std_logic := '0';
  signal i2c_rw_d      : std_logic := '0';
  signal i2c_data_wr_q : std_logic_vector(7 downto 0) := (others => '0');
  signal i2c_data_wr_d : std_logic_vector(7 downto 0) := (others => '0');

  signal rsp_valid_q : std_logic := '0';
  signal rsp_valid_d : std_logic := '0';
  signal rsp_error_q : std_logic := '0';
  signal rsp_error_d : std_logic := '0';
  signal rsp_addr_q  : std_logic_vector(6 downto 0) := (others => '0');
  signal rsp_addr_d  : std_logic_vector(6 downto 0) := (others => '0');
  signal rsp_data_q  : std_logic_vector(8 downto 0) := (others => '0');
  signal rsp_data_d  : std_logic_vector(8 downto 0) := (others => '0');

  signal reg_addr_q  : std_logic_vector(6 downto 0) := (others => '0');
  signal reg_addr_d  : std_logic_vector(6 downto 0) := (others => '0');
  signal reg_data_q  : std_logic_vector(8 downto 0) := (others => '0');
  signal reg_data_d  : std_logic_vector(8 downto 0) := (others => '0');

  signal rd_byte0_q  : std_logic_vector(7 downto 0) := (others => '0');
  signal rd_byte0_d  : std_logic_vector(7 downto 0) := (others => '0');
  signal rd_byte1_q  : std_logic_vector(7 downto 0) := (others => '0');
  signal rd_byte1_d  : std_logic_vector(7 downto 0) := (others => '0');
  signal busy_prev_q : std_logic := '0';
  signal busy_prev_d : std_logic := '0';

  type state_t is (
    idle,

    -- WRITE path (2-byte control word)
    wr_send_hi,
    wr_wait_hi,
    wr_send_lo,
    wr_wait_lo,
    wr_done,

    -- READ path: pointer write (1 byte) + repeated start + 2-byte read
    rd_ptr_send,        -- start pointer byte (write)
    rd_ptr_inflight,    -- pointer byte in progress; flip rw->read to force repeated-start
    rd_restart_wait,    -- wait for read phase to start
    rd_wait_first,      -- capture first read byte (B7..B0)
    rd_wait_second,     -- capture second read byte (bit0 = B8), NACK+STOP
    rd_done
  );
  signal state_q, state_d : state_t := idle;

begin

  u_ac_i2c_master : entity work.ac_i2c_master
    generic map (
      input_clk => 100_000_000,
      bus_clk   => 400_000 -- ~396.8 kHz SCL (divider=63)
    )
    port map (
      clk_pi    => clk_pi,
      rst_pi    => rst_pi,
      ena       => i2c_ena,
      addr      => i2c_addr,
      rw        => i2c_rw,
      data_wr   => i2c_data_wr,
      busy      => i2c_busy,
      data_rd   => i2c_data_rd,
      ack_error => i2c_ack_err,
      sda       => ac_sda,
      scl       => ac_scl
    );

  --------------------------------------------------------------------
  -- State/register process
  --------------------------------------------------------------------
  p_reg : process(clk_pi, rst_pi)
  begin
    if rst_pi = '1' then
      state_q       <= idle;
      i2c_ena_q     <= '0';
      i2c_addr_q    <= (others => '0');
      i2c_rw_q      <= '0';
      i2c_data_wr_q <= (others => '0');

      rsp_valid_q   <= '0';
      rsp_error_q   <= '0';
      rsp_addr_q    <= (others => '0');
      rsp_data_q    <= (others => '0');

      reg_addr_q    <= (others => '0');
      reg_data_q    <= (others => '0');

      rd_byte0_q    <= (others => '0');
      rd_byte1_q    <= (others => '0');
      busy_prev_q   <= '0';

    elsif rising_edge(clk_pi) then
      state_q       <= state_d;
      i2c_ena_q     <= i2c_ena_d;
      i2c_addr_q    <= i2c_addr_d;
      i2c_rw_q      <= i2c_rw_d;
      i2c_data_wr_q <= i2c_data_wr_d;

      rsp_valid_q   <= rsp_valid_d;
      rsp_error_q   <= rsp_error_d;
      rsp_addr_q    <= rsp_addr_d;
      rsp_data_q    <= rsp_data_d;

      reg_addr_q    <= reg_addr_d;
      reg_data_q    <= reg_data_d;

      rd_byte0_q    <= rd_byte0_d;
      rd_byte1_q    <= rd_byte1_d;
      busy_prev_q   <= busy_prev_d;
    end if;
  end process p_reg;

  --------------------------------------------------------------------
  -- Next-state + register update logic
  --------------------------------------------------------------------
  p_cmb : process(all)
  begin
    state_d       <= state_q;
    i2c_ena_d     <= i2c_ena_q;
    i2c_addr_d    <= i2c_addr_q;
    i2c_rw_d      <= i2c_rw_q;
    i2c_data_wr_d <= i2c_data_wr_q;

    rsp_valid_d   <= '0';
    rsp_error_d   <= rsp_error_q;
    rsp_addr_d    <= rsp_addr_q;
    rsp_data_d    <= rsp_data_q;

    reg_addr_d    <= reg_addr_q;
    reg_data_d    <= reg_data_q;

    rd_byte0_d    <= rd_byte0_q;
    rd_byte1_d    <= rd_byte1_q;
    busy_prev_d   <= i2c_busy;

    case state_q is

      when idle =>
        i2c_ena_d <= '0';
        if req_start = '1' then
          reg_addr_d  <= req_reg;
          reg_data_d  <= req_data;

          rsp_error_d <= '0';
          i2c_addr_d  <= I2C_ADDR_CODEC;

          if req_wr = '1' then
            -- WRITE: byte0 = reg_addr & data[8]
            i2c_rw_d      <= '0';
            i2c_data_wr_d <= req_reg & req_data(8);
            i2c_ena_d     <= '1';
            state_d       <= wr_send_hi;
          else
            -- READ: pointer byte = reg_addr & '0' (no STOP, followed by repeated START)
            i2c_rw_d      <= '0';
            i2c_data_wr_d <= req_reg & '0';
            i2c_ena_d     <= '1';
            state_d       <= rd_ptr_send;
          end if;
        end if;

      ----------------------------------------------------------------
      -- WRITE
      ----------------------------------------------------------------
      when wr_send_hi =>
        if i2c_busy = '1' then
          -- load byte1 ahead of time (core latches next byte at slv_ack2)
          i2c_data_wr_d <= reg_data_q(7 downto 0);
          state_d       <= wr_wait_hi;
        end if;

      when wr_wait_hi =>
        if i2c_busy = '0' then
          state_d <= wr_send_lo;
        end if;

      when wr_send_lo =>
        if i2c_busy = '1' then
          i2c_ena_d <= '0'; -- stop after byte1
          state_d   <= wr_wait_lo;
        end if;

      when wr_wait_lo =>
        if i2c_busy = '0' then
          state_d <= wr_done;
        end if;

      when wr_done =>
        rsp_addr_d  <= reg_addr_q;
        rsp_data_d  <= reg_data_q;
        rsp_error_d <= i2c_ack_err;
        rsp_valid_d <= '1';
        state_d     <= idle;

      ----------------------------------------------------------------
      -- READ: pointer byte + repeated START + 2-byte read
      ----------------------------------------------------------------
      when rd_ptr_send =>
        -- wait until pointer-write transaction is actually in progress
        if i2c_busy = '1' then
          -- IMPORTANT: switch rw to READ *during* the pointer byte
          -- so the core will issue a repeated START after this byte
          i2c_rw_d <= '1';
          state_d  <= rd_ptr_inflight;
        end if;

      when rd_ptr_inflight =>
        -- after the pointer byte completes, the core will do repeated START into READ
        if i2c_busy = '0' then
          state_d <= rd_restart_wait;
        end if;

      when rd_restart_wait =>
        -- wait until the READ phase starts
        if i2c_busy = '1' then
          state_d <= rd_wait_first;
        end if;

      when rd_wait_first =>
        -- first data byte complete (core ACKs because i2c_ena is still '1')
        if (busy_prev_q = '1' and i2c_busy = '0') then
          rd_byte0_d <= i2c_data_rd; -- B7..B0
          -- make next byte the last: NACK + STOP after second byte
          i2c_ena_d  <= '0';
          state_d    <= rd_wait_second;
        end if;

      when rd_wait_second =>
        -- second data byte complete (contains B8 in bit0); STOP will follow
        if (busy_prev_q = '1' and i2c_busy = '0') then
          rd_byte1_d <= i2c_data_rd; -- 0..0 B8
          state_d    <= rd_done;
        end if;

      when rd_done =>
        rsp_addr_d             <= reg_addr_q;
        rsp_data_d(7 downto 0) <= rd_byte0_q;
        rsp_data_d(8)          <= rd_byte1_q(0);
        rsp_error_d            <= i2c_ack_err;
        rsp_valid_d            <= '1';
        state_d                <= idle;

    end case;
  end process p_cmb;

  --------------------------------------------------------------------
  -- Output decode (Moore)
  --------------------------------------------------------------------
  p_out : process(all)
  begin
    i2c_ena     <= i2c_ena_q;
    i2c_addr    <= i2c_addr_q;
    i2c_rw      <= i2c_rw_q;
    i2c_data_wr <= i2c_data_wr_q;

    rsp_valid   <= rsp_valid_q;
    rsp_error   <= rsp_error_q;
    rsp_addr    <= rsp_addr_q;
    rsp_data    <= rsp_data_q;
  end process p_out;

end architecture rtl;
