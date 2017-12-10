--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.math_real.ceil;

--

entity deb_button is
	generic(
		freq: natural := 50000000;
		tdebounce: real := 0.05); 
	port(
		clock: in std_logic;
		input: in std_logic;
		output: out std_logic);
end entity;
--

architecture arch of deb_button is
	constant N_paces: natural := natural(ceil(real(freq)*tdebounce));

	signal counter: natural range 0 to N_paces := 0;
	signal count_on: std_logic := '0';
	signal old_button: std_logic := '0';
	
	signal out_but_temp  : std_logic := '0';
	signal was_zero  : std_logic := '0';


begin

output <= out_but_temp;


process (clock, input, counter, count_on)
begin



	if falling_edge(clock) then
		if input = '1' then
			if count_on = '0' then
				count_on <= '1';
				counter <= 0;
			else
				counter <= counter+1;
			end if;
		else
			out_but_temp <= '0';
			count_on <= '0';
			was_zero <= '1';
		end if;
	
	
	
		if counter = N_paces and was_zero = '1' then
		
			if  input = '1' then
				out_but_temp <= '1';
			end if;
			
			count_on <= '0';
			counter <= 0;
			was_zero <= '0';
		else
			out_but_temp <= '0';
		end if;
	end if;

	
end process;


end architecture;
--