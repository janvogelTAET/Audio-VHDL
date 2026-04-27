-------------------------------------------------------------------------------
-- Project: DIDE Audio Processing
-- Entity : ap_user_top
-- Author : Waj
-------------------------------------------------------------------------------
-- Description:
-- Integrated top-level module for the ZYBO Playstation 1.
-- Includes FIR-Bank, Tone Generator, Audio RAM (1.3s), Rotary Encoder 
-- and 7-Segment display driver.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ap_design_pkg.all;
use work.ap_fir_pkg.all;

entity ap_user_top is
  port (
    clk_pi      : in  std_logic;  
    rst_pi      : in  std_logic;  
    -- Audio Codec data interface
    adc_data_pi : in  t_adc_smpl;
    adc_enb_pi  : in  std_logic;
    dac_data_po : out t_dac_smpl;
    dac_enb_pi  : in  std_logic;
    -- Zybo interfaces
    sw_pi       : in  std_logic_vector(3 downto 0);
    btn_pi      : in  std_logic_vector(3 downto 0);
    led_po      : out std_logic_vector(3 downto 0);
    -- Rotary encoder interface
    rot_a_pi    : in  std_logic;
    rot_b_pi    : in  std_logic;
    -- 7-Segment display interface
    seg_po      : out std_logic_vector(6 downto 0);
    an_po       : out std_logic_vector(1 downto 0)
  );
end entity ap_user_top;

architecture rtl of ap_user_top is

  -- FIR filter configuration
  constant FIR_COEF     : t_fir_coef := C_FIR_HP9;         
  constant N_TAPS       : natural := 9;                    
  constant FIR_OUT_DW   : natural := f_fir_out_dw(N_TAPS); 
  constant RND_OFF_BITS : natural := FIR_COEF_DW-5;        
  
  -- IIR Osci configuration (f = 1234 Hz)
  constant IIR_MA1     : signed(FIR_COEF_DW   downto 0) :=  to_signed(64683, 17); 
  constant IIR_S1_INIT : signed(FIR_COEF_DW-1 downto 0) := -to_signed( 5270, 16); 
  constant IIR_S2_INIT : signed(FIR_COEF_DW-1 downto 0) := -to_signed(10403, 16); 

  -- Signal declarations
  signal adc_r_smpl_reg : signed(ADC_DW-1 downto 0);
  signal adc_l_smpl_reg : signed(ADC_DW-1 downto 0);
  signal iir_out_reg    : signed(DAC_DW-1 downto 0);
  signal s1_reg, s2_reg : signed(DAC_DW-1 downto 0);

  signal fir_bank_out_l : signed(ADC_DW-1 downto 0);
  signal fir_bank_out_r : signed(ADC_DW-1 downto 0);
  signal tone_out_l     : signed(15 downto 0);
  signal tone_out_r     : signed(15 downto 0);
  
  signal mux_out_l      : signed(ADC_DW-1 downto 0);
  signal mux_out_r      : signed(ADC_DW-1 downto 0);
  signal ram_out        : signed(15 downto 0);
  
  signal tick_l         : std_logic;
  signal tick_r         : std_logic;
  signal rot_count      : unsigned(3 downto 0) := (others => '0');

begin

  -- Assign switches to LEDs for basic status indication
  led_po <= sw_pi;

  --------------------------------------------------------------------------
  -- Input registration and default routing
  --------------------------------------------------------------------------
  P_adc_avg: process(clk_pi, rst_pi)
  begin
    if rst_pi = '1' then
      adc_r_smpl_reg <= (others => '0');
      adc_l_smpl_reg <= (others => '0');
    elsif rising_edge(clk_pi) then
      if adc_enb_pi = '1' then
        adc_l_smpl_reg <= fir_bank_out_l; 
        
        -- Filter selection for right channel
        if sw_pi(2) = '1' then
          adc_r_smpl_reg <= fir_bank_out_r;
        else
          adc_r_smpl_reg <= adc_data_pi.r;
        end if;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------
  -- Audio multiplexing and channel routing to DAC
  --------------------------------------------------------------------------
  P_lr_ch: process(clk_pi, rst_pi)
  begin
    if rst_pi = '1' then
      dac_data_po.l <= (others => '0');
      dac_data_po.r <= (others => '0');
    elsif rising_edge(clk_pi) then
      if dac_enb_pi = '1' then
        
        -- Source multiplexer
        if sw_pi(3) = '1' then 
             mux_out_l <= resize(ram_out, ADC_DW);
             mux_out_r <= resize(ram_out, ADC_DW);
        elsif btn_pi(3) = '1' then 
             mux_out_l <= resize(tone_out_l, ADC_DW);
             mux_out_r <= resize(tone_out_r, ADC_DW);
        else
             mux_out_l <= adc_l_smpl_reg;
             mux_out_r <= adc_r_smpl_reg;
        end if;

        -- Channel routing 
        if sw_pi(1 downto 0) = "01" then
          dac_data_po.l <= mux_out_l;
          dac_data_po.r <= (others => '0');
        elsif sw_pi(1 downto 0) = "10" then
          dac_data_po.l <= (others => '0');
          dac_data_po.r <= mux_out_r;
        elsif sw_pi(1 downto 0) = "11" then
          dac_data_po.l <= mux_out_r;
          dac_data_po.r <= mux_out_l;
        else
          dac_data_po.l <= mux_out_l;
          dac_data_po.r <= mux_out_r;
        end if; 
      end if;     
    end if;
  end process;

  --------------------------------------------------------------------------
  -- IIR oscillator
  --------------------------------------------------------------------------
  P_iir_osci: process(clk_pi, rst_pi)
    variable v_prod    : signed(32 downto 0);
    variable v_add     : signed(33 downto 0);
    variable v_sat_rnd : signed(15 downto 0);
  begin
    if rst_pi = '1' then
      iir_out_reg <= (others => '0');
      s1_reg <= IIR_S1_INIT;
      s2_reg <= IIR_S2_INIT;
    elsif rising_edge(clk_pi) then
      if adc_enb_pi = '1' then
        -- Multiplier yields 33 bits (16 bits data + 17 bits coefficient)
        v_prod := s1_reg * IIR_MA1;  
        -- Align fractional points before subtraction
        v_add  := resize(v_prod, 34) - shift_left(resize(s2_reg, 34), 15);
        -- Round off 15 fractional bits and saturate to 16-bit output
        v_sat_rnd := f_sat(f_rnd(v_add, 15), DAC_DW);  
        
        s1_reg <= v_sat_rnd;
        s2_reg <= s1_reg;
        iir_out_reg <= v_sat_rnd;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------
  -- Rotary encoder pulse counter
  --------------------------------------------------------------------------
  P_rot_cnt : process(clk_pi)
  begin
    if rising_edge(clk_pi) then
      if tick_r = '1' then 
        rot_count <= rot_count + 1; 
      end if;
      if tick_l = '1' then 
        rot_count <= rot_count - 1; 
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------
  -- Component instantiations
  --------------------------------------------------------------------------
  u_fir_bank : entity work.fir_sel
    port map (
      clk_pi    => clk_pi, 
      ce_pi     => adc_enb_pi,
      sel_pi    => sw_pi(1 downto 0),
      din_l_pi  => adc_data_pi.l, 
      din_r_pi  => adc_data_pi.r,
      dout_l_po => fir_bank_out_l, 
      dout_r_po => fir_bank_out_r
    );

  u_tone_gen : entity work.tone_gen
    port map (
      clk_pi      => clk_pi, 
      rst_pi      => rst_pi, 
      ce_pi       => dac_enb_pi,
      freq_sel_pi => std_logic_vector(rot_count(1 downto 0)), 
      tone_l_po   => tone_out_l, 
      tone_r_po   => tone_out_r
    );

  u_audio_ram : entity work.audio_ram
    port map (
      clk_pi  => clk_pi, 
      ce_pi   => adc_enb_pi,
      rec_pi  => btn_pi(1), 
      play_pi => btn_pi(2), 
      din_pi  => adc_data_pi.l(ADC_DW-1 downto ADC_DW-16), 
      dout_po => ram_out
    );

  u_rot_dec : entity work.enc_decoder
    port map (
      clk_pi        => clk_pi, 
      rot_a_pi      => rot_a_pi, 
      rot_b_pi      => rot_b_pi,
      tick_left_po  => tick_l, 
      tick_right_po => tick_r
    );

  u_seg7 : entity work.seg7_driver
    port map (
      clk_pi    => clk_pi, 
      rst_pi    => rst_pi,
      digit0_pi => std_logic_vector(rot_count), 
      digit1_pi => "00" & sw_pi(1 downto 0),    
      seg_po    => seg_po, 
      an_po     => an_po
    );

end architecture rtl;