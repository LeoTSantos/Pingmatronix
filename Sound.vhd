library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;
--use ieee.math_real.all;

entity Sound is
	GENERIC
	(
		N : natural := 8; --Numero de bits do DAC
		SAMPLES : natural := 50
	);
	port
	(
		clock_in  : in std_logic;
		-- bater na raquete (bounce)
		racket : in std_logic;
		-- aconteceu um ponto
		point : in std_logic;
		-- míssel acertou
		bullet : in std_logic;
		-- fim de jogo
		endGame : in std_logic;
		-- Saida DAC
		music : out std_logic_vector(N-1 downto 0)
	);	
end entity Sound;
--
architecture arch of Sound is

	-- Essas constantes vao determinar as notas musicais
	constant DO : natural := 189394;
--	constant RE : natural := 168350;
	constant MI : natural := 151515;
--	constant FA : natural := 142045;
	constant SOL : natural := 126263;
	constant LA : natural := 113636;
--	constant SI : natural := 94697;

	-- Numero de bits do DAC precisa ser maior ou igual a 8
	constant MULTIPLIER : natural := 2**(N - 8);
	-- tempo de som - 400 ms
	constant TIME_COUNTER : natural := 20000000;

	type memory_type is array (0 to (SAMPLES - 1)) of integer range 0 to ((2**N) - 1); 
	-- Sinal senoidal gerado no Matlab
	-- 50 amostras | 8 bits
	-- t = 0 : pi/25 : (2*pi - pi/25);
	-- y = int32(sin(t)*16256/128) >> 128 para 8 bis | 8 para 12 bits | etc
	signal sine : memory_type :=(128,144,160,175,189,203,215,226,235,243,249,253,255,255,
	253,249,243,235,226,215,203,189,175,160,144,128,112,96,81,67,53,41,30,21,13,7,3,1,1,
	3,7,13,21,30,41,53,67,81,96,112);
	
	signal counterFreq : natural range 0 TO 200000 := 0;
	signal counterTime : natural range 0 TO 20000000 := 0;
	signal index : integer range 0 to (SAMPLES - 1) := 0;
	signal busy : std_logic  := '0';
	signal maxCounter : natural range 0 TO 200000 := 0;
	signal outputValue : natural range 0 TO ((2**N) - 1) := 0;

begin
-------------------------------------------------------------------------
-- Processo que 
-------------------------------------------------------------------------
process(clock_in)
begin

	-- Se nao tem nenhuma musica tocando, verifica se houve evento
	if(busy = '0') then
		if (racket = '1' ) then
			busy <= '1';
			maxCounter <= DO;
		elsif (point = '1' ) then
			busy <= '1';
			maxCounter <= MI;
		elsif (bullet = '1' ) then
			busy <= '1';
			maxCounter <= SOL;
		elsif (endGame = '1' ) then
			busy <= '1';
			maxCounter <= LA;
		end if;
	-- Senao, toca a musica
	else
		if (counterTime < TIME_COUNTER) then
			counterTime <= counterTime + 1;
			-- Aguarda delay -- frequencia
			if (counterFreq < LA) then
					counterFreq <= counterFreq + 1;			
			else
				counterFreq <= 0;
				outputValue <= MULTIPLIER * sine(index);
				index <= (index + 1) mod SAMPLES;
				music <= std_logic_vector(to_unsigned(outputValue, music'length));
			end if;
		else
			counterFreq <= 0;
			busy <= '0';
		end if;
	end if;
end process;
end architecture arch;