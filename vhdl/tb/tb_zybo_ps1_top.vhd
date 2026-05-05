-------------------------------------------------------------------------------
-- Project: DIDE Audio Processing
-- Entity : tb_zybo_ps1_top
-- Author : Waj
-------------------------------------------------------------------------------
-- Description:
-- Testbench for the audio processing design.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ap_design_pkg.all;

entity tb_zybo_ps1_top is
  generic(
    CLK_FRQ : integer := 125_000_000);
end tb_zybo_ps1_top;

architecture TB of tb_zybo_ps1_top is

  -- TB infrastructure signals
  signal rst      : std_logic;
  signal clk      : std_logic := '0';
  signal sim_done : boolean := false;
  
  -- AC I2S interface signals
  signal bclk, reclrc, recdat : std_logic; 
  
  -- Zybo Control/status signals (angepasst auf 3 Bit)
  signal sw       : std_logic_vector(2 downto 0) := "000";
  
  -- Neue Signale für die erweiterten Inputs, damit der Compiler nicht meckert
  signal btn_pi   : std_logic_vector(2 downto 1) := "00";
  signal rot_a_pi : std_logic := '1'; -- Pull-Up Standard
  signal rot_b_pi : std_logic := '1'; -- Pull-Up Standard

  -- AC I2S interface constants
  type t_adc_dat_array is array (natural range 0 to 7) of signed(ADC_DW-1 downto 0);
  constant c_adc_data_l : t_adc_dat_array := ( -- left data
      0 => to_signed(   -3, ADC_DW), 
      1 => to_signed(   -2, ADC_DW), 
      2 => to_signed(   -1, ADC_DW), 
      3 => to_signed(    0, ADC_DW), 
      4 => to_signed(    1, ADC_DW),
      5 => to_signed(    2, ADC_DW), 
      6 => to_signed(    3, ADC_DW), 
      7 => to_signed(    4, ADC_DW)
    );
  constant c_adc_data_r : t_adc_dat_array := ( -- right data
      0 => to_signed(    1, ADC_DW), 
      1 => to_signed(    0, ADC_DW), 
      2 => to_signed(    0, ADC_DW), 
      3 => to_signed(    0, ADC_DW), 
      4 => to_signed(    0, ADC_DW),
      5 => to_signed(    0, ADC_DW), 
      6 => to_signed(    0, ADC_DW), 
      7 => to_signed(12345, ADC_DW)
    );

begin

  -- instantiate MUT
  MUT : entity work.zybo_ps1_top
    port map(
      clk_pi        => clk,          
      rst_pi        => rst,          
      
      -- Neue Inputs mappen
      btn_pi        => btn_pi,
      rot_a_pi      => rot_a_pi,
      rot_b_pi      => rot_b_pi,
      
      -- Neue Outputs mappen (bleiben offen)
      seg_po        => open,
      an_po         => open,
      
      -- I2C to SSM2603 codec
      ac_sda_pio    => open,          
      ac_scl_pio    => open,          
      -- I2S to SSM2603 codec
      ac_mclk_po    => open,          
      ac_bclk_po    => bclk,          
      ac_pbdat_po   => open,          
      ac_pblrc_po   => open,          
      ac_recdat_pi  => recdat,         
      ac_reclrc_po  => reclrc,          
      ac_mute_n_po  => open,          
      -- Status LEDs & Switches
      sw_pi         => sw,
      led4_po       => open,
      led8_po       => open          
      );

  -- clock generation
  p_clk: process
  begin
    if not sim_done then
      wait for 1 sec / CLK_FRQ/2;
      clk <= not clk;
    else
      wait;
    end if;
  end process;

  -- apply asynchronous stimuli
  rst <= '1', '0' after 5 us;
  sw <= "000", "011" after 6*TS_US, "010" after 9*TS_US, "100" after 12*TS_US;

  -- AC Serial ADC data generation
  P_ADC: process
    -- stimuli application procedure
    procedure p_stim_app(smpl : in natural) is
    begin
      -- wait for start of left channel, sample with rising edge
      wait until bclk = '1' and reclrc = '0'; 
      -- generate next recdat input bit with falling edge, MSB first
      for k in ADC_DW-1 downto 0 loop
        wait until bclk = '0'; 
        recdat <= c_adc_data_l(smpl)(k);
        wait until bclk = '1';
      end loop;
      -- wait for start of right channel, sample with rising edge
      wait until bclk = '1' and reclrc = '1'; 
      -- generate next recdat input bit with falling edge, MSB first
      for k in ADC_DW-1 downto 0 loop
       wait until bclk = '0'; 
        recdat <= c_adc_data_r(smpl)(k);
        wait until bclk = '1';
      end loop;
    end procedure;

  begin
    for s in 0 to c_adc_data_l'length-1 loop
      p_stim_app(s);
    end loop;
    wait for 1000 us;
    sim_done <= true;
    report ">>> Simulation stopped. No response checked." severity failure;
    wait;
  end process;
  
end TB;