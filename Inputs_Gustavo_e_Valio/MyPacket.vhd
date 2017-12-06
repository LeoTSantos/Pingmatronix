LIBRARY ieee;
USE ieee.std_logic_1164.all;

package MyPacket is
	type SSD is array (6 downto 0) of std_logic;
	type SSDArray is array (NATURAL range <>) of SSD;
END package;