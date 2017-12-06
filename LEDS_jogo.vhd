


-- import std_logic from the IEEE library
library IEEE;
use IEEE.std_logic_1164.all;

entity LEDS_jogo is
	GENERIC
	(
		
		N_LEDS : natural := 10
	);
	port
	(
		-- INPUTS
		
		-- clock da placa
		clock_in      : in std_logic;
		
		--Eventos de entrada
		Raquete		: in std_logic;
		Ponto		: in std_logic;
		Missel		: in std_logic;
		Fim			: in std_logic;
		
		
		--Leds
		LEDS         : out std_logic_vector(N_LEDS - 1 DOWNTO 0)
	);	
end entity LEDS_jogo;

architecture arch of LEDS_jogo is


	-- Sinal que vai contar o tempo de espera na leitura dos inputs
	signal Counter : natural range 0 TO 100000000;	
	-- Esse sinal vai determinar o limite ate onde o contador deve contar
	
	
	signal Delay      : natural range 0 TO 100000000;-- range de 0 a 200ms para clock de 50MHz
	
	
	
	----------------------Flags que verificam sinal enviado
	signal  	Raquete_aux			: std_logic;
	signal	Ponto_aux			: std_logic;
	signal	Missel_aux			: std_logic;
	signal	Fim_aux				: std_logic;
	
	signal busy : std_logic  := '0';
	
	
	

begin







-------------------------------------------------------------------------
-- Processo que atualiza as variaveis
-------------------------------------------------------------------------
process(clock_in)
begin
	
	Delay <= 100000000;
	-- O processo ocorrera em toda borda de subida do clock
	if rising_edge(clock_in) then
		
		if(busy = '0') then
			if (Raquete	 = '1') then---switch 3
				busy <= '1';
				Raquete_aux <= '1';
			elsif (Ponto = '1') then---switch 2
				busy <= '1';
				Ponto_aux <= '1';
			elsif (Missel = '1') then---switch 1
				busy <= '1';
				Missel_aux <= '1';
			elsif (Fim = '1') then---switch 0	
				busy <= '1';
				Fim_aux <= '0';
			end if;
		else
			if (Counter < Delay) THEN
				Counter <= Counter + 1;
			-- -- Aguarda delay -- 200ms
			else
				Counter <= 0;
				LEDS <= (others => '0');
			
				if (Raquete_aux = '1') then
					Raquete_aux <= '0';
					busy <= '0';
					Leds(N_LEDS - 1) <= '1';
					
				elsif(Ponto_aux<= '1') then
					Ponto_aux <= '0';
					busy <= '0';
					Leds(N_LEDS - 3) <= '1';
				
				elsif(Missel_aux = '1') then
					Missel_aux <= '0';
					busy <= '0';
					Leds(N_LEDS - 5) <= '1';
					
				elsif(Fim_aux <= '0') then	
					Fim_aux <= '1';
					busy <= '0';
					LEDS <= (others => '1');
				end if;
			end if;
		
		
			
		end if;	
			
	end if;-- rising_edge
	
 end process;
end architecture;
