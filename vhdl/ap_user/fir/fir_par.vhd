-------------------------------------------------------------------------------
-- Project: DIDE Audio Processing/FIR
-- Entity : fir_par
-- Author : WaJ, SzP
-------------------------------------------------------------------------------
-- Description:
-- Transposed FIR with package-defined data word widths and generic coefficients.
-- Different parallel FIR architectures are implemented using individual VHDL
-- architectures.
-- Notes:
-- * The filter output is computed with full precision. The corresponding data
--   output width is calculated automatically from input data and coefficent
--   word widths and filter order.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ap_design_pkg.all;
use work.ap_fir_pkg.all;

entity fir_par is
  generic (
    g_coef : t_fir_coef;             -- select coefficient set
    g_taps : natural range 2 to 128  -- number of filter taps
  );
  port (
    clk_pi  : in  std_logic; -- clock
    ce_pi   : in  std_logic; -- clock enable
    din_pi  : in  signed(ADC_DW-1 downto 0);
    dout_po : out signed(f_fir_out_dw(g_taps)-1 downto 0)
  );
end entity fir_par;

-------------------------------------------------------------------------------
-- transposed FIR architecture ------------------------------------------------
architecture trn of fir_par is

  -- type declarations
  type t_stage is array (g_taps-1 downto 0) of signed(dout_po'range);

  -- signal declarations (init values for simulation only!!!)
  signal inreg : signed(dout_po'length-FIR_COEF_DW-1 downto 0) := (others => '0');
  signal stage : t_stage := (others => (others => '0'));

begin

  -- comb. output assignment (full result data width)
  dout_po <= stage(0);

  -- sequential process
  p_fir : process (clk_pi)
  begin
    if rising_edge(clk_pi) then
      if ce_pi = '1' then
        -- sign-extend input sample to internal multiply width
        inreg <= resize(din_pi, inreg'length);
        -- compute filter taps
        stage(g_taps-1) <= inreg * g_coef(g_taps-1);
        for k in g_taps-2 downto 0 loop
          stage(k) <= (inreg * g_coef(k)) + stage(k+1);
        end loop;
      end if;
    end if;
  end process p_fir;

end architecture trn;

-------------------------------------------------------------------------------
-- direct FIR architecture ----------------------------------------------------
architecture dir of fir_par is

  -- Subtyp für die Bitbreite vor der Multiplikation
  subtype t_mult_in is signed(dout_po'length-FIR_COEF_DW-1 downto 0);
  
  -- Array-Typ für die Verzögerungskette (x[n], x[n-1], ...)
  type t_delay_line is array (0 to g_taps-1) of t_mult_in;

begin

  -- sequential process
  p_fir : process (clk_pi)
    variable v_delay : t_delay_line := (others => (others => '0'));
    variable v_acc   : signed(dout_po'range);
  begin
    if rising_edge(clk_pi) then
      if ce_pi = '1' then
        
        -- 1. Verzögerungskette weiterschieben
        for i in g_taps-1 downto 1 loop
          v_delay(i) := v_delay(i-1);
        end loop;
        
        -- Neuen Wert einspeichern
        v_delay(0) := resize(din_pi, t_mult_in'length);

        -- 2. Summe aus (Daten * Koeffizienten) bilden
        v_acc := (others => '0');
        for i in 0 to g_taps-1 loop
          v_acc := v_acc + (v_delay(i) * g_coef(i));
        end loop;

        -- 3. Auf den Ausgang schreiben
        dout_po <= v_acc;

      end if;
    end if;
  end process p_fir;

end architecture dir;
