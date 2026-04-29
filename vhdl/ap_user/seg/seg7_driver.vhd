-------------------------------------------------------------------------------
-- Project: DIDE Audio Processing
-- Entity : seg7_driver
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity seg7_driver is
  port (
    clk_pi    : in  std_logic;
    rst_pi    : in  std_logic;
    digit0_pi : in  std_logic_vector(3 downto 0);
    digit1_pi : in  std_logic_vector(3 downto 0);
    seg_po    : out std_logic_vector(6 downto 0);
    an_po     : out std_logic_vector(1 downto 0)
  );
end entity seg7_driver;

architecture rtl of seg7_driver is

  type t_seg7_rom is array (0 to 15) of std_logic_vector(6 downto 0);
  constant C_SEG7_ROM : t_seg7_rom := (
    0  => "0111111",
    1  => "0000110",
    2  => "1011011",
    3  => "1001111",
    4  => "1100110",
    5  => "1101101",
    6  => "1111101",
    7  => "0000111",
    8  => "1111111",
    9  => "1101111",
    10 => "1110111",
    11 => "1111100",
    12 => "0111001",
    13 => "1011110",
    14 => "1111001",
    15 => "1110001"
  );

begin

  -- Drive segments statically to prevent ghosting on single-digit active displays
  seg_po <= C_SEG7_ROM(to_integer(unsigned(digit0_pi)));

  -- Drive anodes low to ensure activation 
  an_po  <= "00";

end architecture rtl;