-------------------------------------------------------------------------------
-- Project: DIDE Audio Processing
-- Entity : ap_user_top
-- Author : Waj, VJA
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
    
    -- Audio codec data interface
    adc_data_pi : in  t_adc_smpl;
    adc_enb_pi  : in  std_logic;
    dac_data_po : out t_dac_smpl;
    dac_enb_pi  : in  std_logic;
    
    -- Zybo base interfaces
    sw_pi       : in  std_logic_vector(2 downto 0); 
    led_po      : out std_logic_vector(2 downto 0);
    
    -- Expansion interfaces
    btn_pi      : in  std_logic_vector(2 downto 1) := "00";
    rot_a_pi    : in  std_logic := '0';
    rot_b_pi    : in  std_logic := '0';
    seg_po      : out std_logic_vector(6 downto 0);
    an_po       : out std_logic_vector(1 downto 0)
  );
end entity ap_user_top;

architecture rtl of ap_user_top is

  -- FIR and IIR constants
  constant FIR_COEF     : t_fir_coef := C_FIR_HP9;         
  constant N_TAPS       : natural := 9;                    
  constant FIR_OUT_DW   : natural := f_fir_out_dw(N_TAPS); 
  constant RND_OFF_BITS : natural := FIR_COEF_DW-5;        
  
  constant IIR_MA1      : signed(FIR_COEF_DW   downto 0) :=  to_signed(64683, 17);
  constant IIR_S1_INIT  : signed(FIR_COEF_DW-1 downto 0) := -to_signed( 5270, 16);
  constant IIR_S2_INIT  : signed(FIR_COEF_DW-1 downto 0) := -to_signed(10403, 16);

  -- Data pipelines
  signal adc_r_smpl_reg : signed(ADC_DW-1 downto 0);
  signal adc_l_smpl_reg : signed(ADC_DW-1 downto 0);
  signal iir_out_reg    : signed(DAC_DW-1 downto 0);
  signal s1_reg, s2_reg : signed(DAC_DW-1 downto 0);

  signal fir_bank_out_l : signed(ADC_DW-1 downto 0);
  signal fir_bank_out_r : signed(ADC_DW-1 downto 0);
  signal tone_out_l     : signed(15 downto 0);
  signal tone_out_r     : signed(15 downto 0);
  signal ram_out        : signed(15 downto 0);
  signal ram_playing    : std_logic;

  -- UI and control signals
  signal rot_count_s    : std_logic_vector(1 downto 0);

begin

  -- Map switch states to LEDs for visual confirmation
  led_po <= sw_pi;

  --------------------------------------------------------------------------
  -- Input registration and live audio routing
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
  -- Output multiplexer and priority routing
  --------------------------------------------------------------------------
  P_lr_ch: process(clk_pi, rst_pi)
  begin
    if rst_pi = '1' then
      dac_data_po.l <= (others => '0');
      dac_data_po.r <= (others => '0');
    elsif rising_edge(clk_pi) then
      if dac_enb_pi = '1' then
        
        if ram_playing = '1' then
          -- Priority 1: Audio RAM playback
          dac_data_po.l <= resize(ram_out, DAC_DW);
          dac_data_po.r <= resize(ram_out, DAC_DW);
        elsif sw_pi(2) = '1' then
          -- Priority 2: Tone generator output
          dac_data_po.l <= resize(tone_out_l, DAC_DW);
          dac_data_po.r <= resize(tone_out_r, DAC_DW);
        else
          -- Priority 3: Live audio pass-through
          dac_data_po.l <= adc_l_smpl_reg;
          dac_data_po.r <= adc_r_smpl_reg;
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
    variable v_sat_rnd : signed(DAC_DW-1 downto 0);
  begin
    if rst_pi = '1' then
      iir_out_reg <= (others => '0');
      s1_reg      <= IIR_S1_INIT;
      s2_reg      <= IIR_S2_INIT;
    elsif rising_edge(clk_pi) then
      if adc_enb_pi = '1' then
        v_prod    := s1_reg * IIR_MA1;  
        v_add     := resize(v_prod, 34) - shift_left(resize(s2_reg, 34), 15);
        
        v_sat_rnd := f_sat(f_rnd(v_add, 19), DAC_DW);  
        
        s1_reg      <= v_sat_rnd;
        s2_reg      <= s1_reg;
        iir_out_reg <= v_sat_rnd;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------
  -- Submodule instantiations
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
      freq_sel_pi => rot_count_s, 
      tone_l_po   => tone_out_l, 
      tone_r_po   => tone_out_r
    );

  u_audio_ram : entity work.audio_ram
    port map (
      clk_pi     => clk_pi,
      ce_pi      => adc_enb_pi,
      rec_pi     => btn_pi(1),
      play_pi    => btn_pi(2),
      din_pi     => adc_data_pi.l(ADC_DW-1 downto ADC_DW-16),
      dout_po    => ram_out,
      playing_po => ram_playing
    );

  u_seg7 : entity work.seg7_driver
    port map (
      clk_pi    => clk_pi, 
      rst_pi    => rst_pi,
      digit0_pi => "00" & rot_count_s, 
      digit1_pi => "0" & sw_pi,    
      seg_po    => seg_po, 
      an_po     => an_po
    );

  u_rotary_encoder : entity work.rotary_encoder_ctrl
    port map (
      clk_i   => clk_pi,
      rst_i   => rst_pi,
      rot_a_i => rot_a_pi,
      rot_b_i => rot_b_pi,
      count_o => rot_count_s
    );  

end architecture rtl;