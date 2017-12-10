--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.math_real.ceil;

--

entity debouncer is
	generic(
		freq: natural := 50_000_000;
		tdebounce: real := 0.0035); 
	port(
		clock: in std_logic;
		input: in std_logic;
		output: out std_logic);
end entity;
--

architecture arch of debouncer is
	constant N_paces: natural := natural(ceil(real(freq)*tdebounce));

	signal counter: natural range 0 to N_paces := 0;	
	signal output_temp  : std_logic := '0';
	signal change  : std_logic := '0';

begin

output <= output_temp;


process (clock, input, counter, change)
begin



	if falling_edge(clock) then
		if input /= output_temp and change = '0' then
					
				counter <= 0;
				change <= '1';
		end if;
	
		if change = '1' then
			counter <= counter+1;
		end if;
	
	
		if counter = N_paces and change = '1' then
			
			output_temp <= input;
			
			counter <= 0;			
			change <= '0';
		end if;
	end if;

	
end process;


end architecture;
--