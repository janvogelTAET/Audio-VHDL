-------------------------------------------------------------------------------
-- Project: DIDE Audio Processing
-- Entity : rst_gen
-- Author : Waj
-------------------------------------------------------------------------------
-- Description:
-- The reset generator module generates two active-high reset signals that are 
-- asynchronously asserted and synchronously de-asserted to the system clock under
-- the following conditions.
-- Codec I2C I/F reset rst_ac_i2c (used for all AC I2C I/F logic running on clk_sys):
--  * async assert when:
--    - the clock manager loses lock, or 
--    - on external reset activation
--  * sync de-assert when:
--    - clock manager locked, and 
--    - external reset is deasserted
-- Global system reset rst_sys (used for all user logic running on clk_sys):
--  * async assert when:
--    - the clock manager loses lock, or 
--    - on external reset activation, or
--    - codec initialization not yet done
--  * sync de-assert when:
--    - clock manager locked, and 
--    - external reset is deasserted, and
--    - codec initialization done
-- Notes:
-- * It is ensured that the generated reset pulses on rst_sys and rst_ac_if 
-- are always at least 3 sys_clk cycles long.
-- * There is no reset used for the logic running on BCLK = MCLK within the I2S
--   interface of the AC. Only the data registers within I2S running on sysclk
--   are reset with the rst_sys.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity rst_gen is
  port (
    clk_sys_pi     : in  std_logic;  -- system clock input 
    rst_ext_pi     : in  std_logic;  -- external active-high reset input
    clk_locked_pi  : in std_logic;   -- clock locked status
    ac_init_ok_pi  : in std_logic;   -- codec init done status  
    rst_ac_i2c_po  : out std_logic;  -- active-high audio codec I2C I/F reset  
    rst_sys_po     : out std_logic   -- active-high system reset
  );
end entity rst_gen;

architecture rtl of rst_gen is

  -- system/ac_if reset synchronization shift register
  signal rst_sys_sync     : std_logic_vector(2 downto 0);
  signal rst_ac_i2c_sync  : std_logic_vector(2 downto 0);
  -- asynchronous system/ac_if reset signal (active high)
  signal rst_sys_async    : std_logic; 
  signal rst_ac_i2c_async : std_logic;


begin

  -- Async assert system reset
  rst_sys_async <= rst_ext_pi or (not clk_locked_pi) or (not ac_init_ok_pi);
  -- Async assert system reset
  rst_ac_i2c_async <= rst_ext_pi or (not clk_locked_pi);

  -----------------------------------------------------------------------------
  -- Synchronize de-activating edge of system reset to clock signal
  -----------------------------------------------------------------------------    
  P0_sync_rst: process(clk_sys_pi, rst_sys_async)
  begin
    if rst_sys_async = '1' then
      rst_sys_sync  <= (others => '1');
      rst_sys_po    <= '1';
    elsif rising_edge(clk_sys_pi) then
      rst_sys_sync(0)          <= '0';
      rst_sys_sync(2 downto 1) <= rst_sys_sync(1 downto 0);
      rst_sys_po               <= rst_sys_sync(2);          
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Synchronize de-activating edge of AC I2C I/F reset to clock signal
  -----------------------------------------------------------------------------    
  P1_sync_rst: process(clk_sys_pi, rst_ac_i2c_async)
  begin
    if rst_ac_i2c_async = '1' then
      rst_ac_i2c_sync  <= (others => '1');
      rst_ac_i2c_po    <= '1';
    elsif rising_edge(clk_sys_pi) then
      rst_ac_i2c_sync(0)          <= '0';
      rst_ac_i2c_sync(2 downto 1) <= rst_ac_i2c_sync(1 downto 0);
      rst_ac_i2c_po               <= rst_ac_i2c_sync(2);          
    end if;
  end process;

end architecture rtl;
