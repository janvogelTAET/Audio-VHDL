-------------------------------------------------------------------------------
-- Project: DIDE Audio Processing
-- Entity : audio_ram
-- Author : VJA
-------------------------------------------------------------------------------$
-- Description: 1.36s Audio Recorder/Player using Block-RAM (Requirement 5).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity audio_ram is
  port (
    clk_pi   : in  std_logic;
    ce_pi    : in  std_logic;  -- ADC/DAC enable (48 kHz)
    rec_pi   : in  std_logic;  -- Start recording (e.g. Button 1)
    play_pi  : in  std_logic;  -- Start playback (e.g. Button 2)
    din_pi   : in  signed(15 downto 0); -- Input from ADC
    dout_po  : out signed(15 downto 0)  -- Output to DAC
  );
end entity audio_ram;

architecture rtl of audio_ram is
  -- 2^16 = 65536 Samples (ca. 1.36s @ 48kHz)
  type t_mem is array (0 to 65535) of signed(15 downto 0);
  -- Attribut für Xilinx Vivado, um echtes Block-RAM zu erzwingen
  attribute ram_style : string;
  shared variable ram : t_mem;
  attribute ram_style of ram : variable is "block";

  signal addr_cnt : unsigned(15 downto 0) := (others => '0');
  signal playing  : std_logic := '0';
  signal recording : std_logic := '0';
begin

  P_ctrl : process(clk_pi)
  begin
    if rising_edge(clk_pi) then
      if ce_pi = '1' then
        
        -- Steuerung der Modi
        if rec_pi = '1' then
          recording <= '1';
          playing   <= '0';
          addr_cnt  <= (others => '0');
        elsif play_pi = '1' then
          recording <= '0';
          playing   <= '1';
          addr_cnt  <= (others => '0');
        end if;

        -- Zähler-Logik und RAM-Zugriff
        if recording = '1' then
          ram(to_integer(addr_cnt)) := din_pi;
          addr_cnt <= addr_cnt + 1;
          if addr_cnt = 65535 then recording <= '0'; end if;
        elsif playing = '1' then
          dout_po  <= ram(to_integer(addr_cnt));
          addr_cnt <= addr_cnt + 1;
          if addr_cnt = 65535 then playing <= '0'; end if;
        else
          dout_po <= (others => '0');
        end if;
        
      end if;
    end if;
  end process;

end architecture rtl;
