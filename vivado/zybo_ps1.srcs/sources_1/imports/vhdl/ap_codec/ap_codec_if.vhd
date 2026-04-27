-------------------------------------------------------------------------------
-- Project: DIDE Audio Processing
-- Entity : ap_codec_if
-- Author : Waj
-------------------------------------------------------------------------------
-- Description:
-- Top-level module for audio codec interface (I2C initialization and I2S audio
-- interface)
-- Notes:
-- * The codec can be reconfigured during runtime at ac_mode_pi to:
--   - analog loopback
--   - digital line input
--   - digital microphone input
-- * Soft mute can be enabled via ac_dac_mute_pi
-- * While codec reconfig is ongoing, ac_recfg_busy_po will be '1'.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.ap_design_pkg.all;

entity ap_codec_if is
  port (
    clk_sys_pi : in std_logic;  -- 100 MHz system clock input 
    rst_sys_pi : in std_logic;  -- system reset
    rst_i2c_pi : in std_logic;  -- active high AC I2C I/F reset
    -- I2C init interface: codec side
    ac_sda_pio       : inout std_logic; -- I2C data
    ac_scl_pio       : inout std_logic; -- I2C clock
    -- I2C init interface: user side
    ac_init_ok_po    : out std_logic;  
    ac_status_po     : out std_logic_vector(3 downto 0);  
    ac_mode_pi       : in t_codec_mode_sel;
    ac_dac_mute_pi   : in std_logic; 
    ac_recfg_busy_po : out std_logic;    
    -- I2S audio interface: codec side
    ac_bclk_pi        : in  std_logic;
    ac_pbdat_po       : out std_logic;
    ac_pblrc_po       : out  std_logic; 
    ac_recdat_pi      : in  std_logic;
    ac_reclrc_po      : out  std_logic; 
    -- I2S audio interface: user side
    adc_data_po       : out t_adc_smpl;
    adc_enb_po        : out std_logic;
    dac_data_pi       : in t_dac_smpl; 
    dac_enb_po        : out std_logic
  );
end entity ap_codec_if;

architecture rtl of ap_codec_if is

begin

  ------------------------------------------------------------------
  -- I2C to user iterface 
  ------------------------------------------------------------------
  u_ac_i2c_if : entity work.ac_i2c_if
    port map (
      clk_pi  => clk_sys_pi,
      rst_pi  => rst_i2c_pi,
      -- I2C audio interface: codec side
      ac_sda_pio  => ac_sda_pio,
      ac_scl_pio  => ac_scl_pio,
      -- I2C audio interface: user side
      ac_init_ok_po    => ac_init_ok_po,
      ac_status_po     => ac_status_po,
      ac_mode_pi       => ac_mode_pi,
      ac_dac_mute_pi   => ac_dac_mute_pi,
      ac_recfg_busy_po => ac_recfg_busy_po
    );

  ------------------------------------------------------------------
  -- I2S to user iterface 
  ------------------------------------------------------------------
  u_ac_i2s_if : entity work.ac_i2s_if
    port map (
      clk_sys_pi    => clk_sys_pi,
      rst_sys_pi    => rst_sys_pi,
      -- I2S audio interface: codec side
      ac_bclk_pi    => ac_bclk_pi,
      ac_pbdat_po   => ac_pbdat_po,
      ac_pblrc_po   => ac_pblrc_po,
      ac_recdat_pi  => ac_recdat_pi,
      ac_reclrc_po  => ac_reclrc_po,
      -- I2S audio interface: user side
      adc_data_po   => adc_data_po,
      adc_enb_po    => adc_enb_po,
      dac_data_pi   => dac_data_pi,
      dac_enb_po    => dac_enb_po
    );

end architecture rtl;
