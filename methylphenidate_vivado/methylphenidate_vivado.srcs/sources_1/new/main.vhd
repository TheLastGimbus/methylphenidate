library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity main is
  Port (
    CLK : in std_logic;
    LED : out std_logic_vector(3 downto 0)
  );
end main;

architecture Behavioral of main is

    signal state : std_logic := '0';

begin

    blink : process(CLK) begin
        if(rising_edge(CLK)) then
            state <= not state;
        else
            state <= state;
        end if;
    end process blink;
    
    LED(0) <= state;
    
end Behavioral;
