----------------------------------------------------------------------------------
-- Rotary Encoder Interface
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity rotary_encoder_ctrl is
    Port (
        clk_i   : in  std_logic;
        rst_i   : in  std_logic;
        rot_a_i : in  std_logic;
        rot_b_i : in  std_logic;
        count_o : out std_logic_vector(1 downto 0)
    );
end rotary_encoder_ctrl;

architecture rtl of rotary_encoder_ctrl is

    -- Timer definition for 1ms sampling at 125 MHz clock
    constant DEBOUNCE_MAX : integer := 125000;
    signal timer_r        : integer range 0 to DEBOUNCE_MAX := 0;
    signal sample_en      : std_logic := '0';

    -- Synchronization and edge detection registers
    signal sync_a_r       : std_logic_vector(1 downto 0) := (others => '1');
    signal sync_b_r       : std_logic_vector(1 downto 0) := (others => '1');

    -- Internal counter mapped to 2 bits for automatic 0-3 wrap-around
    signal count_r        : unsigned(1 downto 0) := (others => '0');

begin

    -- Generates a single cycle enable pulse every 1ms
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                timer_r   <= 0;
                sample_en <= '0';
            else
                if timer_r = DEBOUNCE_MAX then
                    timer_r   <= 0;
                    sample_en <= '1';
                else
                    timer_r   <= timer_r + 1;
                    sample_en <= '0';
                end if;
            end if;
        end if;
    end process;

    -- Evaluates encoder state at debounced rate
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                sync_a_r <= (others => '1');
                sync_b_r <= (others => '1');
                count_r  <= (others => '0');
            elsif sample_en = '1' then
                -- Shift current pin values into the registers
                sync_a_r <= sync_a_r(0) & rot_a_i;
                sync_b_r <= sync_b_r(0) & rot_b_i;

                -- Detect falling edge on channel A
                if sync_a_r = "10" then
                    -- Evaluate channel B state to determine rotation direction
                    if sync_b_r(0) = '1' then
                        count_r <= count_r + 1;
                    else
                        count_r <= count_r - 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    count_o <= std_logic_vector(count_r);

end rtl;