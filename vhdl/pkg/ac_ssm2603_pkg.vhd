-------------------------------------------------------------------------------
-- Project: DIDE Audio Processing
-- Entity : ac_ssm2603_pkg
-- Author : SzP, Waj
-------------------------------------------------------------------------------
-- Description:
-- Contains definition for the SSM2603 audio codec.
-- Notes:
-- * 
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package ac_ssm2603_pkg is

  subtype reg_addr_t is std_logic_vector(6 downto 0);
  subtype reg_data_t is std_logic_vector(8 downto 0);

  type reg_entry_t is record
    addr : reg_addr_t;
    data : reg_data_t;
  end record reg_entry_t;

  -- Note: Unconstraint array types still not supported by Vivado Sim
  type reg_array_t is array (natural range 0 to 10) of reg_entry_t;
  type init_array_t is array (natural range 0 to 3) of reg_array_t;

  -- Register address constants (7-bit)
  constant R0_LEFT_ADC_VOL   : reg_addr_t := "0000000"; -- 0x00
  constant R1_RIGHT_ADC_VOL  : reg_addr_t := "0000001"; -- 0x01
  constant R2_LEFT_DAC_VOL   : reg_addr_t := "0000010"; -- 0x02
  constant R3_RIGHT_DAC_VOL  : reg_addr_t := "0000011"; -- 0x03
  constant R4_ANALOG_PATH    : reg_addr_t := "0000100"; -- 0x04
  constant R5_DIGITAL_PATH   : reg_addr_t := "0000101"; -- 0x05
  constant R6_POWER_MGMT     : reg_addr_t := "0000110"; -- 0x06
  constant R7_DIGITAL_IF     : reg_addr_t := "0000111"; -- 0x07
  constant R8_SAMPLE_RATE    : reg_addr_t := "0001000"; -- 0x08
  constant R9_ACTIVE         : reg_addr_t := "0001001"; -- 0x09
  constant R15_SW_RESET      : reg_addr_t := "0001111"; -- 0x0F
  constant R16_ALC_CONTROL_1 : reg_addr_t := "0010000"; -- 0x10
  constant R17_ALC_CONTROL_2 : reg_addr_t := "0010001"; -- 0x11
  constant R18_ALC_CONTROL_2 : reg_addr_t := "0010010"; -- 0x12

  ---------------------------------------------------------------
  -- Register config init sets, see SSM2603 datasheet.
  -- Each init set must contain the same # of config registers,
  -- even if default values are used for some registers. 
  -- For each register in a set a contant value with 9 bits is defined.
  ---------------------------------------------------------------
  constant c_ac_init : init_array_t := (
    ---------------------------------------------------
    -- Init 0: Analaog Loopback (Line In to HP Out, Mic Off)
    ---------------------------------------------------
    (
      -- R15: (!) SW Reset
      (addr => R15_SW_RESET, data     => "000000000"),
      -- R0: default
      (addr => R0_LEFT_ADC_VOL, data  => "010010111"),
      -- R1: default
      (addr => R1_RIGHT_ADC_VOL, data => "010010111"),
      -- R2: default
      (addr => R2_LEFT_DAC_VOL, data  => "001111001"),
      -- R3: default
      (addr => R3_RIGHT_DAC_VOL, data => "001111001"), 
      -- R4: (!) BYPASS=1, mix line-in into HP out
      (addr => R4_ANALOG_PATH, data   => "000001000"),
      -- R5: default
      (addr => R5_DIGITAL_PATH, data  => "000001000"),
      -- R6: (!) [0 PWROFF CLKOUT OSC OUT DAC ADC MIC LINEIN]
      (addr => R6_POWER_MGMT, data    => "001101110"),
      -- R7: default
      (addr => R7_DIGITAL_IF, data    => "000001010"),
      -- R8: default
      (addr => R8_SAMPLE_RATE, data   => "000000000"),
      --------- VMID Delay ---------------------------
      -- R9: default
      (addr => R9_ACTIVE, data        => "000000000")
    ),
    ---------------------------------------------------
    -- Init 1: Normal Operation (DAC out/ADC in enabled, 
    --         Line-In on, Mic muted, HP out enabled)
    --         fS = 48 kHz, 16-bit, I2S format
    ---------------------------------------------------
    (
      -- R15: (!) SW Reset
      (addr => R15_SW_RESET, data     => "000000000"),
      -- R0: (!) Left ADC volume = 0 dB, smultan. L/R control disabled
      (addr => R0_LEFT_ADC_VOL, data  => "000010111"),
      -- R1: (!) Right ADC volume = 0 dB, smultan. L/R control disabled
      (addr => R1_RIGHT_ADC_VOL, data => "000010111"),
      -- R2: (!) Left DAC volume = 0 dB, smultan. L/R control enabled
      (addr => R2_LEFT_DAC_VOL, data  => "101111001"),
      -- R3: (!) Right DAC volume = 0 dB, smultan. L/R control enabled
      (addr => R3_RIGHT_DAC_VOL, data => "101111001"),
      -- R4: (!) DAC output to HP on, line-in enabled, Mic mute on
      (addr => R4_ANALOG_PATH, data   => "000010010"),
      -- R5: (!) ADC high pass filter enabled, DAC digital mute off
      (addr => R5_DIGITAL_PATH, data  => "000000000"),
      -- R6: (!) [0 PWROFF CLKOUT OSC OUT DAC ADC MIC LINEIN]
      (addr => R6_POWER_MGMT, data    => "001100000"),
      -- R7: (!) I2S, 16-bit word length, slave mode
      (addr => R7_DIGITAL_IF, data    => "000000010"),
      -- R8: (!) 48 kHz sample rate, USB mode off
      (addr => R8_SAMPLE_RATE, data   => "000000000"),
      --------- VMID Delay ---------------------------
      -- R9: (!) Activate digital core
      (addr => R9_ACTIVE, data        => "000000001")
     ),
    ---------------------------------------------------
    -- Init 2: Normal Operation (DAC out/ADC in enabled, 
    --         Line-In off, Mic on, HP out enabled)
    --         fS = 48 kHz, 16-bit, I2S format
    ---------------------------------------------------
    (
      -- R15: (!) SW Reset
      (addr => R15_SW_RESET, data     => "000000000"),
      -- R0: (!) Left ADC volume = 0 dB, smultan. L/R control disabled
      (addr => R0_LEFT_ADC_VOL, data  => "000010111"),
      -- R1: (!) Right ADC volume = 0 dB, smultan. L/R control disabled
      (addr => R1_RIGHT_ADC_VOL, data => "000010111"),
      -- R2: (!) Left DAC volume = 0 dB, smultan. L/R control enabled
      (addr => R2_LEFT_DAC_VOL, data  => "101111001"),
      -- R3: (!) Right DAC volume = 0 dB, smultan. L/R control enabled
      (addr => R3_RIGHT_DAC_VOL, data => "101111001"),
      -- R4: (!) DAC output to HP on, line-in off, Mic on
      (addr => R4_ANALOG_PATH, data   => "000010100"),
      -- R5: (!) ADC high pass filter enabled, DAC digital mute off
      (addr => R5_DIGITAL_PATH, data  => "000000000"),
      -- R6: (!) [0 PWROFF CLKOUT OSC OUT DAC ADC MIC LINEIN]
      (addr => R6_POWER_MGMT, data    => "001100000"),
      -- R7: (!) I2S, 16-bit word length, slave mode
      (addr => R7_DIGITAL_IF, data    => "000000010"),
      -- R8: (!) 48 kHz sample rate, USB mode off
      (addr => R8_SAMPLE_RATE, data   => "000000000"),
      --------- VMID Delay ---------------------------
      -- R9: (!) Activate digital core
      (addr => R9_ACTIVE, data        => "000000001")
     ),
    ---------------------------------------------------
    -- Init 3: DIGITAL Loopback
    --         (DAC out/ADC in enabled, Line-In on, Mic off, HP out enabled)
    --         fS = 48 kHz, 16-bit, I2S format
    ---------------------------------------------------
    (
      -- R15: (!) SW Reset
      (addr => R15_SW_RESET, data     => "000000000"),
      -- R0: (!) Left ADC volume = 0 dB, smultan. L/R control disabled
      (addr => R0_LEFT_ADC_VOL, data  => "000010111"),
      -- R1: (!) Right ADC volume = 0 dB, smultan. L/R control disabled
      (addr => R1_RIGHT_ADC_VOL, data => "000010111"),
      -- R2: (!) Left DAC volume = 0 dB, smultan. L/R control enabled
      (addr => R2_LEFT_DAC_VOL, data  => "101111001"),
      -- R3: (!) Right DAC volume = 0 dB, smultan. L/R control enabled
      (addr => R3_RIGHT_DAC_VOL, data => "101111001"),
      -- R4: (!) DAC output to HP on, line-in enabled, Mic mute on
      (addr => R4_ANALOG_PATH, data   => "000010010"),
      -- R5: (!) ADC high pass filter disabled, no de-emphasis, DAC digital mute off
      (addr => R5_DIGITAL_PATH, data  => "000000001"),
      -- R6: (!) [0 PWROFF CLKOUT OSC OUT DAC ADC MIC LINEIN]
      (addr => R6_POWER_MGMT, data    => "001100000"),
      -- R7: (!) I2S, 16-bit word length, slave mode
      (addr => R7_DIGITAL_IF, data    => "000000010"),
      -- R8: (!) 48 kHz sample rate, USB mode off
      (addr => R8_SAMPLE_RATE, data   => "000000000"),
      --------- VMID Delay ---------------------------
      -- R9: (!) Activate digital core
      (addr => R9_ACTIVE, data        => "000000001")
    )
  );

end package ac_ssm2603_pkg;
