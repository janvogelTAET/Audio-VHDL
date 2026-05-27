-------------------------------------------------------------------------------
-- Project: DIDE Audio Processing
-- Entity : audio_ram
-- Author : VJA
-------------------------------------------------------------------------------
-- Description: 1.36s Audio Recorder/Player using Block-RAM (Requirement 5).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity audio_ram is
  port (
    clk_pi     : in  std_logic;
    ce_pi      : in  std_logic;  -- ADC/DAC enable (48 kHz)
    rec_pi     : in  std_logic;  -- Start recording (e.g. Button 1)
    play_pi    : in  std_logic;  -- Start playback (e.g. Button 2)
    din_pi     : in  signed(15 downto 0); -- Input from ADC
    dout_po    : out signed(15 downto 0); -- Output to DAC
    playing_po : out std_logic            -- '1' while playback is active
  );
end entity audio_ram;

architecture rtl of audio_ram is
  -- 2^16 = 65536 Samples (ca. 1.36s @ 48kHz)
  type t_mem is array (0 to 65535) of signed(15 downto 0);
  signal ram : t_mem := (others => (others => '0'));
  
  -- Attribut f�r Xilinx Vivado, um echtes Block-RAM zu erzwingen
  attribute ram_style : string;
  attribute ram_style of ram : signal is "block";

  signal addr_cnt   : unsigned(15 downto 0) := (others => '0');
  signal playing    : std_logic := '0';
  signal recording  : std_logic := '0';
  signal dout_reg   : signed(15 downto 0) := (others => '0');
  -- Flankenerkennung: Zustandswechsel nur bei steigender Flanke auslösen,
  -- damit addr_cnt nicht bei gehaltenem Knopf in jedem Takt zurückgesetzt wird.
  signal rec_prev   : std_logic := '0';
  signal play_prev  : std_logic := '0';
begin

  dout_po    <= dout_reg;
  playing_po <= playing;

  P_ctrl : process(clk_pi)
  begin
    if rising_edge(clk_pi) then
      if ce_pi = '1' then
        -- Vorherige Pegel für Flankenerkennung aktualisieren
        rec_prev  <= rec_pi;
        play_prev <= play_pi;

        -- Prioritätskette: Flanken > aktiver Modus > Leerlauf.
        -- Einheitliche if-elsif-Kette verhindert konkurrierende addr_cnt-Zuweisungen.
        if rec_pi = '1' and rec_prev = '0' then
          recording <= '1';
          playing   <= '0';
          addr_cnt  <= (others => '0');
        elsif play_pi = '1' and play_prev = '0' then
          recording <= '0';
          playing   <= '1';
          addr_cnt  <= (others => '0');
        elsif recording = '1' then
          ram(to_integer(addr_cnt)) <= din_pi;
          addr_cnt <= addr_cnt + 1;
          if addr_cnt = 65535 then
            recording <= '0';
          end if;
        elsif playing = '1' then
          dout_reg <= ram(to_integer(addr_cnt));
          addr_cnt <= addr_cnt + 1;
          if addr_cnt = 65535 then
            playing <= '0';
          end if;
        else
          dout_reg <= (others => '0');
        end if;

      end if;
    end if;
  end process;

end architecture rtl;