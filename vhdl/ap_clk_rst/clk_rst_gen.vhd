-------------------------------------------------------------------------------
-- Project: DIDE Audio Processing
-- Entity : clk_rst_gen
-- Author : Waj
-------------------------------------------------------------------------------
-- Description:
-- Instantiation of clock and reset generator modules.
-- Notes:
-- * 
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity clk_rst_gen is
  port (
    clk_pi         : in  std_logic;  -- external 125 MHz clock input 
    rst_pi         : in  std_logic;  -- active high reset input (BTN_0)
    -- status input
    ac_init_ok_pi  : in std_logic;   -- codec init done status
    -- clock/reset outputs
    clk_sys_po     : out std_logic; -- 100 MHz system clock
    rst_sys_po     : out std_logic; -- active high system reset
    rst_ac_i2c_po  : out std_logic; -- active high audio codec I2C interface reset
    ac_mclk_po     : out std_logic  -- master clock to codec (12.288 MHz)
  );
end entity clk_rst_gen;

architecture rtl of clk_rst_gen is

  -- internal signals
  signal clk_sys    : std_logic;
  signal clk_locked : std_logic;

begin

  -- Output assignments
  clk_sys_po <= clk_sys;

  ------------------------------------------------------------------
  -- MMCM clock generator
  ------------------------------------------------------------------
  u_clk_gen : entity work.clk_gen
    port map (
      clk_pi        => clk_pi,
      clk_sys_po    => clk_sys,
      ac_mclk_po    => ac_mclk_po,
      clk_locked_po => clk_locked
    );

  ------------------------------------------------------------------
  -- Reset generator
  ------------------------------------------------------------------
  u_rst_gen : entity work.rst_gen
    port map (
      clk_sys_pi    => clk_sys,
      rst_ext_pi    => rst_pi,
      clk_locked_pi => clk_locked,
      ac_init_ok_pi => ac_init_ok_pi,
      rst_ac_i2c_po => rst_ac_i2c_po,
      rst_sys_po    => rst_sys_po
    );

end architecture rtl;
