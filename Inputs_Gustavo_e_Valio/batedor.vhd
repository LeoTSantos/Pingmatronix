library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity batedor is
	generic (
		MAX_LIMIT: NATURAL := 44;
		MIN_LIMIT: NATURAL := 3
	);
	
	port (
		clk: IN STD_LOGIC;
		clkrot: IN STD_LOGIC; --clk pin (rotary encoder)
		dtrot: IN STD_LOGIC;  --dt pin (rotary encoder)
		position: OUT NATURAL range MIN_LIMIT to MAX_LIMIT
	);
end entity;

architecture batedor of batedor IS
	signal clkrotSignal: std_logic;
	
	begin
	batedorLbl: entity work.debounce PORT MAP (clk => CLK, input => clkrot, output => clkrotSignal); 

	process (all)
	begin 
	if falling_edge(clkrotSignal) then
	--checks the dt level when the clock pin has a falling edge
	--to determine the clock direction (clockwise or counterclockwise)
			if dtrot = '0' then
				if position > MIN_LIMIT then
					position <= position-1;
				else
					position <= 3;
				end if;
			elsif dtrot = '1' then
				if position < MAX_LIMIT then
					position <= position+1;
				else
					position <= 44;
				end if;
			end if;
	end if;	
	end process;
	
end architecture;