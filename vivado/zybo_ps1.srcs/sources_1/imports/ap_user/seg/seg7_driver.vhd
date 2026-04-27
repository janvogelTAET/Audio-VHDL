-------------------------------------------------------------------------------
-- Project: DIDE Audio Processing
-- Entity : seg7_driver
-- Author : VJA
-------------------------------------------------------------------------------
-- Description:
-- Time-multiplexed two-digit 7-segment display driver (common anode, active low).
-- Displays two 4-bit hex values on two digits, alternating at ~763 Hz per digit.
-- Segment encoding (bit 6 = segment a, bit 0 = segment g, active LOW):
--   0->0000001  1->1001111  2->0010010  3->0000110
--   4->1001100  5->0100100  6->0100000  7->0001111
--   8->0000000  9->0000100  A->0001000  b->1100000
--   C->0110001  d->1000010  E->0110000  F->0111000
-- Anode select: an_po="10" -> digit1 active, an_po="01" -> digit0 active.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity seg7_driver is
  generic (
    G_DIV_LOG2 : natural := 16  -- refresh divider: 2^16 cycles = ~655 us @ 100 MHz
  );
  port (
    clk_pi    : in  std_logic;                    -- 100 MHz system clock
    rst_pi    : in  std_logic;                    -- active-high synchronous reset
    digit0_pi : in  std_logic_vector(3 downto 0); -- right digit value (0-F)
    digit1_pi : in  std_logic_vector(3 downto 0); -- left  digit value (0-F)
    seg_po    : out std_logic_vector(6 downto 0); -- segment outputs (active LOW)
    an_po     : out std_logic_vector(1 downto 0)  -- digit anodes (active LOW)
  );
end entity seg7_driver;

architecture rtl of seg7_driver is

  ---------------------------------------------------------------------------
  -- 7-segment ROM: maps 4-bit hex digit to 7-bit active-low segment pattern
  -- Bit order: {a, b, c, d, e, f, g} = {bit6, ..., bit0}
  ---------------------------------------------------------------------------
  type t_seg7_rom is array (0 to 15) of std_logic_vector(6 downto 0);
  constant C_SEG7_ROM : t_seg7_rom := (
    0  => "0000001",  -- 0: a,b,c,d,e,f on; g off
    1  => "1001111",  -- 1: b,c on
    2  => "0010010",  -- 2: a,b,d,e,g on
    3  => "0000110",  -- 3: a,b,c,d,g on
    4  => "1001100",  -- 4: b,c,f,g on
    5  => "0100100",  -- 5: a,c,d,f,g on
    6  => "0100000",  -- 6: a,c,d,e,f,g on
    7  => "0001111",  -- 7: a,b,c on
    8  => "0000000",  -- 8: all on
    9  => "0000100",  -- 9: a,b,c,d,f,g on
    10 => "0001000",  -- A
    11 => "1100000",  -- b
    12 => "0110001",  -- C
    13 => "1000010",  -- d
    14 => "0110000",  -- E
    15 => "0111000"   -- F
  );

  ---------------------------------------------------------------------------
  -- Refresh counter and digit select
  ---------------------------------------------------------------------------
  signal div_cnt   : unsigned(G_DIV_LOG2-1 downto 0) := (others => '0');
  signal sel       : std_logic := '0';  -- '0' = digit0, '1' = digit1

begin

  ---------------------------------------------------------------------------
  -- Refresh divider: toggle digit select at 2^G_DIV_LOG2 rate
  ---------------------------------------------------------------------------
  P_div : process(clk_pi, rst_pi)
  begin
    if rst_pi = '1' then
      div_cnt <= (others => '0');
      sel     <= '0';
    elsif rising_edge(clk_pi) then
      div_cnt <= div_cnt + 1;
      if div_cnt = (div_cnt'range => '1') then
        sel <= not sel;
      end if;
    end if;
  end process P_div;

  ---------------------------------------------------------------------------
  -- Segment and anode combinatorial drive
  ---------------------------------------------------------------------------
  P_drive : process(sel, digit0_pi, digit1_pi)
  begin
    if sel = '0' then
      seg_po <= C_SEG7_ROM(to_integer(unsigned(digit0_pi)));
      an_po  <= "10";   -- digit0 active (right), digit1 disabled
    else
      seg_po <= C_SEG7_ROM(to_integer(unsigned(digit1_pi)));
      an_po  <= "01";   -- digit1 active (left), digit0 disabled
    end if;
  end process P_drive;

end architecture rtl;