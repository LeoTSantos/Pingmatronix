library ieee;
use ieee.std_logic_1164.all;
use IEEE.math_real.ceil;
use IEEE.math_real.log10;
use ieee.numeric_std.all;
use work.deb_button;
use work.ssd;
use work.SSDefinitions.all;
USE work.PongDefinitions.all;


entity placar is

	port(
        pontos: in NATURAL RANGE 0 TO MAX_PONTOS;
			ssds_out: out SSD_ARRAY(natural(ceil(log10(real(MAX_PONTOS))))-1 downto 0));
end entity;

architecture arch of placar is
	constant N_ssd: natural := natural(ceil(log10(real(MAX_PONTOS))));
	
	type array_decimal is array (0 to N_ssd-1) of natural range 0 to 9;
	signal valor_decimal : array_decimal;
	
	

begin

-- conversao decimal

	GEN_CONV:
	for i in 0 to N_ssd-1 generate
	begin
		valor_decimal(i) <= (pontos mod (10**(i+1)))/(10**(i));
	end generate GEN_CONV;

-- ssds

   GEN_SSD: 
   for i in 0 to N_ssd-1 generate
	begin
		ssd_entity : entity work.ssd port map(std_logic_vector(to_unsigned(valor_decimal(i), 4)),ssds_out(i));
	end generate GEN_SSD;
end architecture;