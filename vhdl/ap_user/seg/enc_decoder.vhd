-------------------------------------------------------------------------------
-- Project: DIDE Audio Processing
-- Entity : enc_decoder
-- Author : VJA
-------------------------------------------------------------------------------
-- Description:
-- Rotary encoder decoder with quadrature phase detection.
-- Generates tick_left_po and tick_right_po pulses for counter direction.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity enc_decoder is
  port (
    clk_pi        : in  std_logic;
    rot_a_pi      : in  std_logic;
    rot_b_pi      : in  std_logic;
    tick_left_po  : out std_logic;
    tick_right_po : out std_logic
  );
end entity enc_decoder;

architecture rtl of enc_decoder is
  signal rot_a_sync : std_logic_vector(2 downto 0) := (others => '0');
  signal rot_b_sync : std_logic_vector(2 downto 0) := (others => '0');
  signal rot_a_prev : std_logic := '0';
begin

  -- Synchronizer and edge detection
  p_sync : process(clk_pi)
  begin
    if rising_edge(clk_pi) then
      -- Double-synchronize inputs
      rot_a_sync <= rot_a_sync(1 downto 0) & rot_a_pi;
      rot_b_sync <= rot_b_sync(1 downto 0) & rot_b_pi;
      rot_a_prev <= rot_a_sync(2);
      
      -- Detect edges and direction
      tick_left_po  <= '0';
      tick_right_po <= '0';
      
      -- Rising edge on A
      if rot_a_sync(2) = '1' and rot_a_prev = '0' then
        if rot_b_sync(2) = '0' then
          tick_right_po <= '1';  -- Clockwise
        else
          tick_left_po <= '1';   -- Counter-clockwise
        end if;
      end if;
    end if;
  end process p_sync;

end architecture rtl;