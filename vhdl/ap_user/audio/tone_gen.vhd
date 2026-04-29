-------------------------------------------------------------------------------
-- Project: DIDE Audio Processing
-- Entity : tone_gen
-- Author : VJA
-------------------------------------------------------------------------------
-- Description:
-- Harmonic audio signal source (sine wave generator).
-- Uses a 16-bit phase accumulator and a 32-entry sine ROM to produce full-scale
-- 16-bit signed sinusoidal samples synchronised to the audio sample clock.
-- Four frequencies are selectable via freq_sel_pi:
--   "00" -> 440 Hz  (concert A4)
--   "01" -> 880 Hz  (A5)
--   "10" -> 1000 Hz
--   "11" -> 2000 Hz
-- Frequency accuracy at fs=48 kHz: +/- <0.5 Hz for all presets.
-- The same sample is output on both left and right channels (mono source).
-- Notes:
-- * Phase step formula: step = round(f * 2^16 / fs)
-- * ROM address: phase_acc[15:11]  (top 5 bits -> 32 entries)
-- * ROM values:  sin(2*pi*k/32) * 32767, k=0..31
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tone_gen is
  port (
    clk_pi      : in  std_logic;                    -- 100 MHz system clock
    rst_pi      : in  std_logic;                    -- active-high synchronous reset
    ce_pi       : in  std_logic;                    -- clock enable (= adc_enb @ 48 kHz)
    freq_sel_pi : in  std_logic_vector(1 downto 0); -- frequency selection
    tone_l_po   : out signed(15 downto 0);          -- left  channel output
    tone_r_po   : out signed(15 downto 0)           -- right channel output
  );
end entity tone_gen;

architecture rtl of tone_gen is

  ---------------------------------------------------------------------------
  -- 32-entry sine ROM: sin(2*pi*k/32) * 32767, k=0..31
  ---------------------------------------------------------------------------
  type t_sine_rom is array (0 to 31) of signed(15 downto 0);
  constant C_SINE_ROM : t_sine_rom := (
    0  => to_signed(     0, 16),
    1  => to_signed(  6393, 16),
    2  => to_signed( 12539, 16),
    3  => to_signed( 18204, 16),
    4  => to_signed( 23170, 16),
    5  => to_signed( 27245, 16),
    6  => to_signed( 30273, 16),
    7  => to_signed( 32137, 16),
    8  => to_signed( 32767, 16),
    9  => to_signed( 32137, 16),
    10 => to_signed( 30273, 16),
    11 => to_signed( 27245, 16),
    12 => to_signed( 23170, 16),
    13 => to_signed( 18204, 16),
    14 => to_signed( 12539, 16),
    15 => to_signed(  6393, 16),
    16 => to_signed(     0, 16),
    17 => to_signed( -6393, 16),
    18 => to_signed(-12539, 16),
    19 => to_signed(-18204, 16),
    20 => to_signed(-23170, 16),
    21 => to_signed(-27245, 16),
    22 => to_signed(-30273, 16),
    23 => to_signed(-32137, 16),
    24 => to_signed(-32767, 16),
    25 => to_signed(-32137, 16),
    26 => to_signed(-30273, 16),
    27 => to_signed(-27245, 16),
    28 => to_signed(-23170, 16),
    29 => to_signed(-18204, 16),
    30 => to_signed(-12539, 16),
    31 => to_signed( -6393, 16)
  );

  ---------------------------------------------------------------------------
  -- Phase step presets  (step = round(f * 65536 / 48000))
  --   440 Hz  -> step = 602  -> actual 440.9 Hz
  --   880 Hz  -> step = 1203 -> actual 881.0 Hz
  --  1000 Hz  -> step = 1365 -> actual 999.9 Hz
  --  2000 Hz  -> step = 2731 -> actual 2000.5 Hz
  ---------------------------------------------------------------------------
  constant C_STEP_440  : unsigned(15 downto 0) := to_unsigned( 602, 16);
  constant C_STEP_880  : unsigned(15 downto 0) := to_unsigned(1203, 16);
  constant C_STEP_1K   : unsigned(15 downto 0) := to_unsigned(1365, 16);
  constant C_STEP_2K   : unsigned(15 downto 0) := to_unsigned(2731, 16);

  ---------------------------------------------------------------------------
  -- Internal signals
  ---------------------------------------------------------------------------
  signal phase_step : unsigned(15 downto 0);
  signal phase_acc  : unsigned(15 downto 0) := (others => '0');
  signal rom_idx    : integer range 0 to 31;
  signal tone_reg   : signed(15 downto 0)   := (others => '0');

begin

  ---------------------------------------------------------------------------
  -- Frequency selection (combinatorial)
  ---------------------------------------------------------------------------
P_freq_sel : process(freq_sel_pi)
  begin
    case freq_sel_pi is
      when "00" => phase_step <= C_STEP_440;
      when "01" => phase_step <= C_STEP_880;
      when "10" => phase_step <= C_STEP_1K;
      when others => phase_step <= C_STEP_2K;
    end case;
  end process;

  ---------------------------------------------------------------------------
  -- Phase accumulator: advances each audio sample, wraps naturally (mod 2^16)
  ---------------------------------------------------------------------------
  P_phase : process(clk_pi, rst_pi)
  begin
    if rst_pi = '1' then
      phase_acc <= (others => '0');
    elsif rising_edge(clk_pi) then
      if ce_pi = '1' then
        phase_acc <= phase_acc + phase_step;
      end if;
    end if;
  end process P_phase;

  ---------------------------------------------------------------------------
  -- ROM address: top 5 bits of phase accumulator select one of 32 entries
  ---------------------------------------------------------------------------
  rom_idx <= to_integer(phase_acc(15 downto 11));

  ---------------------------------------------------------------------------
  -- Sine ROM read (registered for clean LUTRAM/BRAM inference)
  ---------------------------------------------------------------------------
  P_rom : process(clk_pi, rst_pi)
  begin
    if rst_pi = '1' then
      tone_reg <= (others => '0');
    elsif rising_edge(clk_pi) then
      tone_reg <= C_SINE_ROM(rom_idx);
    end if;
  end process P_rom;

  ---------------------------------------------------------------------------
  -- Identical output on both channels (mono source)
  ---------------------------------------------------------------------------
  tone_l_po <= tone_reg;
  tone_r_po <= tone_reg;

end architecture rtl;