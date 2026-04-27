-------------------------------------------------------------------------------
-- Project: DIDE Audio Processing
-- Entity : clk_gen
-- Author : SzP, Waj
-------------------------------------------------------------------------------
-- Description:
-- Clock generator using 2 MMCME2_BASE instances to generate the required clocks:
--   clk_sys: 100 MHz    - system clock
--   ac_mclk: 12.288 MHz - audio codec master clock (48 kHz * 256 = 96 kHz * 128)
--                         (also used as bclk in I2S interface)
-- Notes:
-- * Uses two MMCME2_BASE instances to enable exact generation of 12.288 MHz clock
--   Stage 1: 125 MHz -> VCO=600 MHz -> 100 MHz
--   Stage 2: 100 MHz -> VCO=960 MHz -> 12.288 MHz
-- * Both MMCM lock after power-up, no external reset is used for MMCMs
-- * References:
--   - AMD Vivado 7-Series Libraries Guide (UG953)
--   - Digilent Zybo Z7 Reference Manual: SSM2603 MCLK requirements
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;

entity clk_gen is
  port (
    clk_pi        : in  std_logic;  -- external 125 MHz clock input 
    clk_sys_po    : out std_logic;  -- 100 MHz system clock
    ac_mclk_po    : out std_logic;  -- 12.288 MHz master clock to codec 
    clk_locked_po : out std_logic   -- clock locked status
  );
end entity clk_gen;

architecture rtl of clk_gen is

  -- Input clock buffering
  signal clk_in_bufg : std_logic;

  -- MMCM #1 (125 MHz -> 100 MHz & 10 MHz)
  signal mmcm1_clkfbout  : std_logic;
  signal mmcm1_clkfb     : std_logic;
  signal mmcm1_clkout0   : std_logic;
  signal mmcm1_locked    : std_logic;
  signal clk_sys_bufg    : std_logic;

  -- MMCM #2 (100 MHz -> 12.288 MHz)
  signal mmcm2_clkfbout  : std_logic;
  signal mmcm2_clkfb     : std_logic;
  signal mmcm2_clkout0   : std_logic;
  signal mmcm2_locked    : std_logic;
  signal ac_mclk_bufg    : std_logic;

  -- Resets (MMCM reset ports are active-high, async assert)
  signal rst_mmcm1 : std_logic;
  signal rst_mmcm2 : std_logic;

begin

  ----------------------------------------------------------------------------
  -- Output assignments
  ----------------------------------------------------------------------------
  clk_sys_po    <= clk_sys_bufg;
  ac_mclk_po    <= ac_mclk_bufg;
  clk_locked_po <= mmcm1_locked and mmcm2_locked;

  ----------------------------------------------------------------------------
  -- MMCM Reset signals
  ----------------------------------------------------------------------------
  rst_mmcm1 <= '0';               -- No external reset.
  rst_mmcm2 <= not mmcm1_locked;  -- Hold MMCM2 in reset until MMCM1 is locked.

  ----------------------------------------------------------------------------
  -- Global clock buffer for input clock
  ----------------------------------------------------------------------------
  u_bufg_clk_in : BUFG
    port map (
      I => clk_pi,
      O => clk_in_bufg
    );

  ----------------------------------------------------------------------------
  -- MMCM #1 : 125 MHz -> VCO=600 MHz -> 100 MHz
  --   DIVCLK_DIVIDE      = 5      (125 / 5 = 25 MHz PFD)
  --   CLKFBOUT_MULT_F    = 24.0   (25 * 24 = 600 MHz VCO)
  --   CLKOUT0_DIVIDE_F   = 6.0    (600 / 6 = 100 MHz)
  ----------------------------------------------------------------------------
  u_mmcm1 : MMCME2_BASE
    generic map (
      BANDWIDTH => "OPTIMIZED",
      CLKFBOUT_MULT_F => 24.0,
      CLKFBOUT_PHASE  => 0.0,
      CLKIN1_PERIOD   => 8.0, -- 125 MHz input
      CLKOUT0_DIVIDE_F => 6.0,
      CLKOUT1_DIVIDE  => 1,
      CLKOUT2_DIVIDE  => 1,
      CLKOUT3_DIVIDE  => 1,
      CLKOUT4_DIVIDE  => 1,
      CLKOUT5_DIVIDE  => 1,
      CLKOUT6_DIVIDE  => 1,
      CLKOUT0_DUTY_CYCLE => 0.5,
      CLKOUT1_DUTY_CYCLE => 0.5,
      CLKOUT2_DUTY_CYCLE => 0.5,
      CLKOUT3_DUTY_CYCLE => 0.5,
      CLKOUT4_DUTY_CYCLE => 0.5,
      CLKOUT5_DUTY_CYCLE => 0.5,
      CLKOUT6_DUTY_CYCLE => 0.5,
      CLKOUT0_PHASE => 0.0,
      CLKOUT1_PHASE => 0.0,
      CLKOUT2_PHASE => 0.0,
      CLKOUT3_PHASE => 0.0,
      CLKOUT4_PHASE => 0.0,
      CLKOUT5_PHASE => 0.0,
      CLKOUT6_PHASE => 0.0,
      CLKOUT4_CASCADE => FALSE,
      DIVCLK_DIVIDE => 5,
      REF_JITTER1 => 0.010,
      STARTUP_WAIT => FALSE
    )
    port map (
      -- Clock Outputs
      CLKOUT0  => mmcm1_clkout0,
      CLKOUT0B => open,
      CLKOUT1  => open,
      CLKOUT1B => open,
      CLKOUT2  => open,
      CLKOUT2B => open,
      CLKOUT3  => open,
      CLKOUT3B => open,
      CLKOUT4  => open,
      CLKOUT5  => open,
      CLKOUT6  => open,
      -- Feedback
      CLKFBOUT  => mmcm1_clkfbout,
      CLKFBOUTB => open,
      CLKFBIN   => mmcm1_clkfb,
      -- Status
      LOCKED => mmcm1_locked,
      -- Inputs / Control
      CLKIN1  => clk_in_bufg,
      PWRDWN  => '0',
      RST     => rst_mmcm1
    );

  -- Global buffer for MMCM1 feedback
  u_mmcm1_fb_bufg : BUFG
    port map (
      I => mmcm1_clkfbout,
      O => mmcm1_clkfb
    );

  -- Global buffers for MMCM1 output 0
  u_bufg_clk_sys: BUFG
    port map (
      I => mmcm1_clkout0,
      O => clk_sys_bufg
    );

  ----------------------------------------------------------------------------
  -- MMCM #2 : 100 MHz -> VCO=960 MHz -> 12.288 MHz (exact)
  --   DIVCLK_DIVIDE      = 5        (100 / 5 = 20 MHz PFD)
  --   CLKFBOUT_MULT_F    = 48.0     (20 * 48 = 960 MHz VCO)
  --   CLKOUT0_DIVIDE_F   = 78.125   (960 / 78.125 = 12.288 MHz)
  ----------------------------------------------------------------------------
  u_mmcm2 : MMCME2_BASE
    generic map (
      BANDWIDTH => "OPTIMIZED",
      CLKFBOUT_MULT_F => 48.0,
      CLKFBOUT_PHASE  => 0.0,
      CLKIN1_PERIOD   => 10.0,  -- 100 MHz input
      CLKOUT0_DIVIDE_F => 78.125,
      CLKOUT1_DIVIDE  => 1,
      CLKOUT2_DIVIDE  => 1,
      CLKOUT3_DIVIDE  => 1,
      CLKOUT4_DIVIDE  => 1,
      CLKOUT5_DIVIDE  => 1,
      CLKOUT6_DIVIDE  => 1,
      CLKOUT0_DUTY_CYCLE => 0.5,
      CLKOUT1_DUTY_CYCLE => 0.5,
      CLKOUT2_DUTY_CYCLE => 0.5,
      CLKOUT3_DUTY_CYCLE => 0.5,
      CLKOUT4_DUTY_CYCLE => 0.5,
      CLKOUT5_DUTY_CYCLE => 0.5,
      CLKOUT6_DUTY_CYCLE => 0.5,
      CLKOUT0_PHASE => 0.0,
      CLKOUT1_PHASE => 0.0,
      CLKOUT2_PHASE => 0.0,
      CLKOUT3_PHASE => 0.0,
      CLKOUT4_PHASE => 0.0,
      CLKOUT5_PHASE => 0.0,
      CLKOUT6_PHASE => 0.0,
      CLKOUT4_CASCADE => FALSE,
      DIVCLK_DIVIDE => 5,
      REF_JITTER1 => 0.010,
      STARTUP_WAIT => FALSE
    )
    port map (
      -- Clock Outputs
      CLKOUT0  => mmcm2_clkout0,
      CLKOUT0B => open,
      CLKOUT1  => open,
      CLKOUT1B => open,
      CLKOUT2  => open,
      CLKOUT2B => open,
      CLKOUT3  => open,
      CLKOUT3B => open,
      CLKOUT4  => open,
      CLKOUT5  => open,
      CLKOUT6  => open,
      -- Feedback
      CLKFBOUT  => mmcm2_clkfbout,
      CLKFBOUTB => open,
      CLKFBIN   => mmcm2_clkfb,
      -- Status
      LOCKED => mmcm2_locked,
      -- Inputs / Control
      CLKIN1  => clk_sys_bufg,
      PWRDWN  => '0',
      RST     => rst_mmcm2
    );

  -- Global buffer for MMCM2 feedback
  u_mmcm2_fb_bufg : BUFG
    port map (
      I => mmcm2_clkfbout,
      O => mmcm2_clkfb
    );

  -- Global buffer for MMCM2 output
  u_bufg_ac_mclk: BUFG
    port map (
      I => mmcm2_clkout0,
      O => ac_mclk_bufg
    );

end architecture rtl;
