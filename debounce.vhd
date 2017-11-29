LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE work.meupacote.all;
USE ieee.math_real.all;

ENTITY debounce IS
GENERIC(
	FCLK: NATURAL := 50_000_000
);
PORT (
	clk: IN STD_LOGIC;
	input: IN STD_LOGIC;
	output: OUT STD_LOGIC
);
END ENTITY;

architecture arch of debounce is
	constant TEMPO_25MS: NATURAL := FCLK / 40;	-- 100ms
	signal aux_output: STD_LOGIC;
begin
process(clk)
variable counter: natural range 0 to TEMPO_25MS;
variable old_input: STD_LOGIC;
begin
	if rising_edge(clk) then
		if old_input = input then
			counter := counter + 1;
			if counter = TEMPO_25MS - 1 then
				aux_output <= input;
			end if;
		else
			counter := 0;
		end if;
		old_input := input;	
	end if;	
end process;

process(clk)
variable old_input: STD_LOGIC;
begin
	if rising_edge(clk) then
		if aux_output = '1' and old_input = '0' then
			output <= '1';
		else
			output <= '0';
		end if;
		old_input := aux_output;	
	end if;
end process;
end architecture;