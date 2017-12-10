library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.math_real.ceil;
USE work.PongDefinitions.all;


entity batedor is

	port (
		clock: IN STD_LOGIC;
		clkrot: IN STD_LOGIC; --clk pin (rotary encoder)
		dtrot: IN STD_LOGIC;  --dt pin (rotary encoder)
		position: out NATURAL range MIN_RACKET_Y to MAX_RACKET_Y
	);
end entity;

architecture batedor of batedor IS


	TYPE state is (c0d0, c1d0, c0d1, c1d1);
	signal pr_state : state := c0d0;
	
	signal pos_sig : NATURAL range MIN_RACKET_Y to MAX_RACKET_Y := MIN_RACKET_Y;
	
	signal clkrotSignal, dtrotSignal: std_logic;
	
	function dec(position: in  NATURAL range MIN_RACKET_Y to MAX_RACKET_Y)
		return NATURAL is
		
		variable p : NATURAL range MIN_RACKET_Y to MAX_RACKET_Y;
	begin
			if position - 1 > MIN_RACKET_Y then
					p := position - 1;
			else
					p := MIN_RACKET_Y;
			end if;
	return p;
	end;
	
	function inc(position: in  NATURAL range MIN_RACKET_Y to MAX_RACKET_Y)
		return NATURAL  is
		
		variable p : NATURAL range MIN_RACKET_Y to MAX_RACKET_Y;	begin
			if position + 1 < MAX_RACKET_Y then
					p := position + 1;
			else
					p := MAX_RACKET_Y;
			end if;
	return p;
	end;
	
	
	begin
	batedorLbl: entity work.debouncer PORT MAP (clock => clock, input => clkrot, output => clkrotSignal); 
	batedorLb2: entity work.debouncer PORT MAP (clock => clock, input => dtrot, output => dtrotSignal); 

	process (all)
	begin 
	
	position <= pos_sig;
	
	if falling_edge(clock) then
			case pr_state is
			when c1d1 => -- 
				if clkrotSignal = '0' and dtrotSignal = '1' then
					pos_sig <= inc(pos_sig);
					pr_state <= c0d1;
				elsif clkrotSignal = '1' and dtrotSignal = '0' then
					pos_sig <= dec(pos_sig);
					pr_state <= c1d0;
				elsif clkrotSignal = '0' and dtrotSignal = '0' then
					pos_sig <= pos_sig;
					pr_state <= c0d0;
				elsif clkrotSignal = '1' and dtrotSignal = '1' then
					pos_sig <= pos_sig;
					pr_state <= c1d1;
				end if;
			when c0d1 =>
				pos_sig <= pos_sig;
				if clkrotSignal = '0' and dtrotSignal = '1' then
					pr_state <= c0d1;
				elsif clkrotSignal = '1' and dtrotSignal = '0' then
					pr_state <= c1d0;
				elsif clkrotSignal = '0' and dtrotSignal = '0' then
					pr_state <= c0d0;
				elsif clkrotSignal = '1' and dtrotSignal = '1' then
					pr_state <= c1d1;
				end if;
			when c0d0 =>
				if clkrotSignal = '0' and dtrotSignal = '1' then
					pos_sig <= dec(pos_sig);
					pr_state <= c0d1;
				elsif clkrotSignal = '1' and dtrotSignal = '0' then
					pos_sig <= inc(pos_sig);
					pr_state <= c1d0;
				elsif clkrotSignal = '0' and dtrotSignal = '0' then
					pos_sig <= pos_sig;
					pr_state <= c0d0;
				elsif clkrotSignal = '1' and dtrotSignal = '1' then
					pos_sig <= pos_sig;
					pr_state <= c1d1;
				end if;
			when c1d0 =>
				pos_sig <= pos_sig;
				if clkrotSignal = '0' and dtrotSignal = '1' then
					pr_state <= c0d1;
				elsif clkrotSignal = '1' and dtrotSignal = '0' then
					pr_state <= c1d0;
				elsif clkrotSignal = '0' and dtrotSignal = '0' then
					pr_state <= c0d0;
				elsif clkrotSignal = '1' and dtrotSignal = '1' then
					pr_state <= c1d1;
				end if;
			end case;
	end if;

	end process;
	
end architecture;