library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;
use work.MyPackage.all;

entity int2disp is
	generic (
		MIN_VALUE:integer := 0;
		MAX_VALUE:integer := 99
	);
	
	port (
		numValue: in integer range MIN_VALUE to MAX_VALUE;
		ssds: out SSDArray(NATURAL(FLOOR (LOG10(REAL(MAX_VALUE))) + 1.0) DOWNTO 0)
	);
end entity;
--
architecture int2disp of int2disp IS
	CONSTANT SDD_N: NATURAL := NATURAL(FLOOR (LOG10(REAL(MAX_VALUE))) + 1.0);

	TYPE div_array IS ARRAY (SDD_N + 1 DOWNTO 0) OF NATURAL;
	SIGNAL disp, div: div_array;
	signal posValue: integer range MIN_VALUE to MAX_VALUE;
	
begin
	

	
	posValue <= abs(numValue);
	
	disp(0) <= posValue mod 10;
	div(0) <= posValue / 10;
	DIVISOR: FOR k IN 0 TO SDD_N -1 GENERATE
	
		ssds(k) <= NUM_0 WHEN disp(k) = 0 ELSE
					  NUM_1 WHEN disp(k) = 1 ELSE
					  NUM_2 WHEN disp(k) = 2 ELSE
					  NUM_3 WHEN disp(k) = 3 ELSE
					  NUM_4 WHEN disp(k) = 4 ELSE
					  NUM_5 WHEN disp(k) = 5 ELSE
					  NUM_6 WHEN disp(k) = 6 ELSE
					  NUM_7 WHEN disp(k) = 7 ELSE
					  NUM_8 WHEN disp(k) = 8 ELSE
					  NUM_9 WHEN disp(k) = 9;
					  
					  
		disp(k+1) <= div(k) mod 10;
		div(k+1) <= div(k) / 10;
	
	END GENERATE DIVISOR;
	
	ssds(SDD_N) <= NEG_SINE when numValue < 0 else
						BLANK;
	
end architecture;

