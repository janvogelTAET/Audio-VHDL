-------------------------------------------------------------------------------
-- Project: DIDE Audio Processing/FIR
-- Entity : dds
-- Author : WaJ
-------------------------------------------------------------------------------
-- Description:
-- Simple DDS implementation to generate sample values of harmonic signals.
-- It uses fix N=13 and W=16
-- Notes:
-- * The lookup table holds 2^12 sample values of the first two quadrants of a 
--   sinusoidal signal (instead of only one quadrant). This allows to implement 
--   the phase acculuator as free-running modulo counter and only conditionally
--   invert the sign at the output of the lookup table.
-- * Phase quantization is currently not implemented. Instead, the phase accu
--   quantized with 12 bits is directly addressing the lookup table.
-- * Also see ap_dds_pkg.vhd
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ap_design_pkg.all;
use work.ap_dds_pkg.all;

entity dds is
  port(
    clk_pi      : in  std_logic;
    ce_pi       : in  std_logic;
    rst_pi      : in  std_logic;
    phs_seed_pi : in  unsigned(DDS_PSW-1 downto 0);
    dds_po      : out signed(DAC_DW-1 downto 0)
    );
end dds;

architecture rtl of dds is

  -- signal declarations
  signal phs_accu_reg : unsigned(DDS_N-2 downto 0);
  signal dds_lut_reg  : unsigned(DDS_W-1 downto 0);
  signal dds_out_reg  : signed(DAC_DW-1 downto 0);
  signal quadr_reg1   : std_logic; -- Quadrant state: '0' = 1st/2nd; '1' = 3rd/4th
  signal quadr_reg2   : std_logic; -- 1cc delayed version of quadr_reg1

begin 
  
  -- output assignments
  dds_po <= dds_out_reg;

  -- sequential process
  P_dds: process(clk_pi, rst_pi)
    variable v_phs_accu_new : unsigned(DDS_N-2 downto 0);
  begin
    if rst_pi = '1' then
      phs_accu_reg <= (others => '0');
      dds_lut_reg  <= (others => '0');
      dds_out_reg  <= (others => '0');
      quadr_reg1   <= '0';
      quadr_reg2   <= '0';
    elsif rising_edge(clk_pi) then
      if ce_pi = '1' then
        -- phase accumulator and quadrant tracking
        v_phs_accu_new := phs_accu_reg + phs_seed_pi;
        phs_accu_reg <= v_phs_accu_new;
        -- quadrant tracking
        if phs_accu_reg > v_phs_accu_new then
          -- change to 3rd/1st quadrant upon wrap-around of phase accu
          quadr_reg1 <= not quadr_reg1;
        end if;
        quadr_reg2 <= quadr_reg1;
        -- read from DDS lookup table
        dds_lut_reg <= to_unsigned(DDS_LUT(to_integer(phs_accu_reg)),DDS_W);
        -- conditionally invert sign
        if quadr_reg2 = '1' then
          -- invert sign if phase is in 3rd or 4th quadrant
          dds_out_reg <= to_signed(-to_integer(dds_lut_reg),DAC_DW);
        else
          -- do not invert sign if phase is in 1st or 2nd quadrant
          dds_out_reg <= to_signed(to_integer(dds_lut_reg),DAC_DW);
        end if;
      end if;
    end if;
  end process;
  
end rtl;
