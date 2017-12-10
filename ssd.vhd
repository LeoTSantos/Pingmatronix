--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--
entity ssd is

  port(
  valor_in: in std_logic_vector(3 downto 0);
  ssd_out: out std_logic_vector(0 to 6)); --ssd vai mostrar em hexa

end entity;

architecture arch of ssd is

begin
ssd_out <= "0000001" when (valor_in = "0000")
  else
         "1001111" when (valor_in = "0001")
  else
         "0010010" when (valor_in = "0010")
  else
         "0000110" when (valor_in = "0011")
  else
         "1001100" when (valor_in = "0100")
  else
         "0100100" when (valor_in = "0101")
  else
         "0100000" when (valor_in = "0110")
  else
         "0001111" when (valor_in = "0111")
  else
         "0000000" when (valor_in = "1000")
  else
         "0000100" when (valor_in = "1001") 
  else
         "0001000" when (valor_in = "1010")--
  else
         "1100000" when (valor_in = "1011")	
  else
         "0110001" when (valor_in = "1100")	
  else
         "1000010" when (valor_in = "1101")	
  else
         "0110000" when (valor_in = "1110")	
  else
         "0111000" when (valor_in = "1111")		
  else
			"-------";



end architecture;
