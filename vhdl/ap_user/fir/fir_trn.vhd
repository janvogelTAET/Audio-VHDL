-------------------------------------------------------------------------------
-- Project: DIDE Audio Processing/FIR
-- Entity : fir_trn
-- Author : VJA
-------------------------------------------------------------------------------
-- Description:
-- Transposed FIR filter with generic coefficients.
-- This is an alias/wrapper for fir_par architecture trn.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ap_design_pkg.all;
use work.ap_fir_pkg.all;

entity fir_trn is
  generic (
    g_coef : t_fir_coef;
    g_taps : natural range 2 to 128
  );
  port (
    clk_pi  : in  std_logic;
    ce_pi   : in  std_logic;
    din_pi  : in  signed(ADC_DW-1 downto 0);
    dout_po : out signed(f_fir_out_dw(g_taps)-1 downto 0)
  );
end entity fir_trn;

architecture trn of fir_trn is
  type t_stage is array (g_taps-1 downto 0) of signed(dout_po'range);
  signal inreg : signed(dout_po'length-FIR_COEF_DW-1 downto 0) := (others => '0');
  signal stage : t_stage := (others => (others => '0'));
begin
  dout_po <= stage(0);
  
  p_fir : process (clk_pi)
  begin
    if rising_edge(clk_pi) then
      if ce_pi = '1' then
        inreg <= resize(din_pi, inreg'length);
        stage(g_taps-1) <= inreg * g_coef(g_taps-1);
        for k in g_taps-2 downto 0 loop
          stage(k) <= (inreg * g_coef(k)) + stage(k+1);
        end loop;
      end if;
    end if;
  end process p_fir;
end architecture trn;