library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;

package MyPackage is
	type SSD is array (6 downto 0) of STD_LOGIC;
	type SSDArray is array(natural range <>) of SSD;
	
	CONSTANT NUM_0: SSD := "1000000";
	CONSTANT NUM_1: SSD := "1111001";
	CONSTANT NUM_2: SSD := "0100100";
	CONSTANT NUM_3: SSD := "0110000";
	CONSTANT NUM_4: SSD := "0011001";
	CONSTANT NUM_5: SSD := "0010010";
	CONSTANT NUM_6: SSD := "0000010";
	CONSTANT NUM_7: SSD := "1111000";
	CONSTANT NUM_8: SSD := "0000000";
	CONSTANT NUM_9: SSD := "0010000";
	CONSTANT NUM_A: SSD := "0001000";
	CONSTANT NUM_B: SSD := "0000011";
	CONSTANT NUM_C: SSD := "1000110";
	CONSTANT NUM_D: SSD := "0100001";
	CONSTANT NUM_E: SSD := "0000110";
	CONSTANT NUM_F: SSD := "0001110";
	
	CONSTANT NEG_SINE: SSD := "0111111";
	CONSTANT BLANK: SSD := "1111111";
	
end package;