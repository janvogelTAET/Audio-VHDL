-------------------------------------------------------------------------------
-- Project: DIDE Audio Processing
-- Entity : fir_sel
-- Author : VJA
-------------------------------------------------------------------------------
-- Description:
-- FIR filter bank with filter selection for stereo audio channels.
-- Instantiates LP9 and HP9 transposed FIR filters for left and right channels.
-- The active filter is selected via sel_pi:
--   "00" = bypass (unfiltered pass-through)
--   "01" = Low-Pass  9-tap (C_FIR_LP9)
--   "10" = High-Pass 9-tap (C_FIR_HP9)
--   "11" = bypass (default)
-- Output is combinatorial after filter quantisation; registration is done
-- by the calling entity (ap_user_top) synchronised with adc_enb.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ap_design_pkg.all;
use work.ap_fir_pkg.all;

entity fir_sel is
  port (
    clk_pi    : in  std_logic;                     -- 100 MHz system clock
    ce_pi     : in  std_logic;                     -- clock enable (ADC sample rate)
    sel_pi    : in  std_logic_vector(1 downto 0);  -- filter selection
    din_l_pi  : in  signed(ADC_DW-1 downto 0);    -- left  channel ADC input
    din_r_pi  : in  signed(ADC_DW-1 downto 0);    -- right channel ADC input
    dout_l_po : out signed(ADC_DW-1 downto 0);    -- left  channel output
    dout_r_po : out signed(ADC_DW-1 downto 0)     -- right channel output
  );
end entity fir_sel;

architecture rtl of fir_sel is

  ---------------------------------------------------------------------------
  -- FIR parameters (matching ap_user_top template convention)
  ---------------------------------------------------------------------------
  constant C_TAPS       : natural := 9;
  constant C_FIR_OUT_DW : natural := f_fir_out_dw(C_TAPS);  -- = 36 bits
  constant C_RND_OFF    : natural := FIR_COEF_DW - 5;       -- = 11 bits

  ---------------------------------------------------------------------------
  -- Full-precision FIR outputs
  ---------------------------------------------------------------------------
  signal lp9_full_l : signed(C_FIR_OUT_DW-1 downto 0);
  signal lp9_full_r : signed(C_FIR_OUT_DW-1 downto 0);
  signal hp9_full_l : signed(C_FIR_OUT_DW-1 downto 0);
  signal hp9_full_r : signed(C_FIR_OUT_DW-1 downto 0);

  ---------------------------------------------------------------------------
  -- Quantised (rounded + saturated) FIR outputs
  ---------------------------------------------------------------------------
  signal lp9_qnt_l  : signed(ADC_DW-1 downto 0);
  signal lp9_qnt_r  : signed(ADC_DW-1 downto 0);
  signal hp9_qnt_l  : signed(ADC_DW-1 downto 0);
  signal hp9_qnt_r  : signed(ADC_DW-1 downto 0);

begin

  ---------------------------------------------------------------------------
  -- FIR instance: Low-Pass 9-tap, left channel
  ---------------------------------------------------------------------------
  u_fir_lp9_l : entity work.fir_trn
    generic map (
      g_coef => C_FIR_LP9,
      g_taps => C_TAPS
    )
    port map (
      clk_pi  => clk_pi,
      ce_pi   => ce_pi,
      din_pi  => din_l_pi,
      dout_po => lp9_full_l
    );

  ---------------------------------------------------------------------------
  -- FIR instance: Low-Pass 9-tap, right channel
  ---------------------------------------------------------------------------
  u_fir_lp9_r : entity work.fir_trn
    generic map (
      g_coef => C_FIR_LP9,
      g_taps => C_TAPS
    )
    port map (
      clk_pi  => clk_pi,
      ce_pi   => ce_pi,
      din_pi  => din_r_pi,
      dout_po => lp9_full_r
    );

  ---------------------------------------------------------------------------
  -- FIR instance: High-Pass 9-tap, left channel
  ---------------------------------------------------------------------------
  u_fir_hp9_l : entity work.fir_trn
    generic map (
      g_coef => C_FIR_HP9,
      g_taps => C_TAPS
    )
    port map (
      clk_pi  => clk_pi,
      ce_pi   => ce_pi,
      din_pi  => din_l_pi,
      dout_po => hp9_full_l
    );

  ---------------------------------------------------------------------------
  -- FIR instance: High-Pass 9-tap, right channel
  ---------------------------------------------------------------------------
  u_fir_hp9_r : entity work.fir_trn
    generic map (
      g_coef => C_FIR_HP9,
      g_taps => C_TAPS
    )
    port map (
      clk_pi  => clk_pi,
      ce_pi   => ce_pi,
      din_pi  => din_r_pi,
      dout_po => hp9_full_r
    );

  ---------------------------------------------------------------------------
  -- Combinatorial rounding + saturation of FIR outputs
  -- Identical to the convention used in the ap_user_top template.
  ---------------------------------------------------------------------------
  lp9_qnt_l <= f_sat(f_rnd(lp9_full_l, C_FIR_OUT_DW - C_RND_OFF), ADC_DW);
  lp9_qnt_r <= f_sat(f_rnd(lp9_full_r, C_FIR_OUT_DW - C_RND_OFF), ADC_DW);
  hp9_qnt_l <= f_sat(f_rnd(hp9_full_l, C_FIR_OUT_DW - C_RND_OFF), ADC_DW);
  hp9_qnt_r <= f_sat(f_rnd(hp9_full_r, C_FIR_OUT_DW - C_RND_OFF), ADC_DW);

  ---------------------------------------------------------------------------
  -- Combinatorial output multiplexer
  -- (Registration with adc_enb is handled in ap_user_top)
  ---------------------------------------------------------------------------
  with sel_pi select dout_l_po <=
    lp9_qnt_l when "01",
    hp9_qnt_l when "10",
    din_l_pi  when others;

  with sel_pi select dout_r_po <=
    lp9_qnt_r when "01",
    hp9_qnt_r when "10",
    din_r_pi  when others;

end architecture rtl;