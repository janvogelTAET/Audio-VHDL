-------------------------------------------------------------------------------
-- Project: DIDE Audio Processing
-- Entity : zybo_ps1_top
-- Author : Waj
-------------------------------------------------------------------------------
-- Description:
-- Top-level entity of the audio processing reference design (ZYBO PS1), 
-- including the the clock/reset generation and SSM2603 codec interface with
-- initialization via I2C and I2S audio interface logic.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.ap_design_pkg.all;

entity zybo_ps1_top is
  port (
    clk_pi : in  std_logic;  -- external 125 MHz clock input 
    rst_pi : in  std_logic;  -- active high reset input (BTN_0)
    -- I2C to SSM2603 codec
    ac_sda_pio : inout std_logic; -- I2C data
    ac_scl_pio : inout std_logic; -- I2C clock
    -- I2S to SSM2603 codec
    ac_mclk_po   : out std_logic; -- master clock to codec (12.288 MHz)
    ac_bclk_po   : out std_logic; -- bit clock to codec (12.288 MHz)
    ac_pbdat_po  : out std_logic; -- audio data to codec (playback)
    ac_pblrc_po  : out std_logic; -- left/right clock to codec (playback)
    ac_recdat_pi : in std_logic;  -- audio data from codec (record) 
    ac_reclrc_po : out std_logic; -- left/right clock to codec (record)   
    ac_mute_n_po : out std_logic; -- DAC output mute, active-low, PD on board
    -- Control  & Status
    sw_pi   : in  std_logic_vector(2 downto 0);
    led4_po : out std_logic_vector(3 downto 0);
    led8_po : out std_logic_vector(2 downto 0);  -- <--- HIER WAR DER FEHLER (Semikolon fehlte)

    -- IO for Semester Project
    btn_pi   : in  std_logic_vector(2 downto 1);
    rot_a_pi : in  std_logic;
    rot_b_pi : in  std_logic;
    seg_po   : out std_logic_vector(6 downto 0);
    an_po    : out std_logic_vector(1 downto 0)
  );
end entity zybo_ps1_top;

architecture rtl of zybo_ps1_top is

  -- Internal clck/rst signals
  signal clk_sys    : std_logic;  -- 100 MHz system clock
  signal rst_sys    : std_logic;  -- active-high system reset
  signal rst_ac_i2c : std_logic;  -- active-high audio codec interface reset
  signal ac_mclk    : std_logic;  -- 12.288 MHz codec master clock
  signal ac_init_ok : std_logic;  -- codec init done status
  -- Internal ADC/DAC data signals
  signal adc_enb    : std_logic;
  signal dac_enb    : std_logic;
  signal adc_data   : t_adc_smpl;
  signal dac_data   : t_dac_smpl;

begin

  -- Assign outputs
  ac_bclk_po   <= ac_mclk;    -- 12.288 MHz bit clock to codec (same as master clock)
  ac_mclk_po   <= ac_mclk;    -- 12.288 MHz master clock to codec
  ac_mute_n_po <= ac_init_ok; -- active-low mute released after codec init done
  
  ------------------------------------------------------------------
  -- clock/reset generator
  ------------------------------------------------------------------
  u_clk_rst : entity work.clk_rst_gen
    port map (
      clk_pi        => clk_pi,
      rst_pi        => rst_pi,
      ac_init_ok_pi => ac_init_ok,
      clk_sys_po    => clk_sys,
      rst_sys_po    => rst_sys,
      rst_ac_i2c_po => rst_ac_i2c,
      ac_mclk_po    => ac_mclk
    );

  ------------------------------------------------------------------
  -- Audio Codec Interfaces
  ------------------------------------------------------------------
  u_ap_codec_if : entity work.ap_codec_if
    port map (
      clk_sys_pi       => clk_sys,         -- 100 MHz system clock
      rst_sys_pi       => rst_sys,         -- system reset
      rst_i2c_pi       => rst_ac_i2c,      -- active-high AC I2C I/F reset
      -- I2C init interface: codec side
      ac_sda_pio       => ac_sda_pio,
      ac_scl_pio       => ac_scl_pio,
      -- I2C init interface: user side
      ac_init_ok_po    => ac_init_ok,
      ac_status_po     => led4_po,
      ac_mode_pi       => codec_mode_digital_line,  -- fix Codec mode 
      ac_dac_mute_pi   => '0',                      -- '1' = activate DAC soft mute
      ac_recfg_busy_po => open,                     -- '1' = codec reconfog ongoing
      -- I2S audio interface: codec side
      ac_bclk_pi       => ac_mclk,         -- 12.288 MHz codec bit clock
      ac_pbdat_po      => ac_pbdat_po, 
      ac_pblrc_po      => ac_pblrc_po,
      ac_recdat_pi     => ac_recdat_pi,
      ac_reclrc_po     => ac_reclrc_po, 
      -- I2S audio interface: user side
      adc_data_po      => adc_data,
      adc_enb_po       => adc_enb, 
      dac_data_pi      => dac_data, 
      dac_enb_po       => dac_enb
    );

  ------------------------------------------------------------------
  -- Audio Processor User Top-Level 
  ------------------------------------------------------------------
  u_ap_user_top : entity work.ap_user_top
    port map (
      clk_pi       => clk_sys,
      rst_pi       => rst_sys,
      -- Audio Codec data interface
      adc_data_pi  => adc_data,
      adc_enb_pi   => adc_enb,
      dac_data_po  => dac_data,
      dac_enb_pi   => dac_enb,
      -- Zybo interfaces
      sw_pi        => sw_pi,
      led_po       => led8_po,  -- <--- HIER WAR DER 2. FEHLER (Komma fehlte)
      -- IO for Semester Project
      btn_pi       => btn_pi,
      rot_a_pi     => rot_a_pi,
      rot_b_pi     => rot_b_pi,
      seg_po       => seg_po,
      an_po        => an_po
    );

end architecture rtl;