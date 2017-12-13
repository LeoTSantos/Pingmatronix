-------------------------------------------------
-- VERSÃO: 2.1 10/12/2017
-- DESENVOLVIDO POR: BRUNO MATTIAS E RAFAEL UKOSKI 
-- EQUIPE: ANDRÉ BERTONI, KLAUS BOTH, BRUNO MATTIAS, RAFAEL UKOSKI 
-- FUNCIONALIDADES: 
--	1) MOSTRAR PONTUAÇÃO NOS SDDS
--	2) TOCAR SOM A CADA EVENTO
--	3) ACIONAR A VIBRAÇÃO DO CONTROLE A CADA EVENTO
-- 
-------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all; 
use ieee.math_real.all;

entity som is 
generic (
			
		MAX_SPEED_MS: NATURAL := 10;								    -- MÍNIMA TEMPO DE TROCA ENTRE SONS EM UM EVENTO QUALQUER (MAXIMA VELOCIDADE)
		FCLK: NATURAL := 50_000_000;
		RESO: NATURAL := 8;											    -- 8 BITS DE RESOLUÇAO PARA O PWM (0-255)
		
		-- AS VARIAVEIS IRÃO DIZER A FREQUENCIA DO PWM
		FREQ_0: STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000000";				
		FREQ_1: STD_LOGIC_VECTOR(7 DOWNTO 0) := "00100000";					
		FREQ_2: STD_LOGIC_VECTOR(7 DOWNTO 0) := "00010000";
		FREQ_3: STD_LOGIC_VECTOR(7 DOWNTO 0) := "01000100";
		FREQ_4: STD_LOGIC_VECTOR(7 DOWNTO 0) := "01001001";
		FREQ_5: STD_LOGIC_VECTOR(7 DOWNTO 0) := "00100100"
	);
	
	port (		
	

		CLOCK 	 	: in  std_logic;
		
		REBATER		: in std_logic;										-- INDICA REBATIDA DO PLAYER 1
		REBATER2	: in std_logic;										-- INDICA REBATIDA DO PLAYER 2
		MORREU		: in std_logic;										
		ACABOU		: in std_logic;										
		MISSIL 		: in std_logic;
		
		PWM_OUT_SOM 	: out std_logic;								-- SAÍDA DA ONDA PARA O SOM
		PWM_OUT_VIBRA1	: out std_logic;								-- SAÍDA PARA MOTOR DO CONTROLE DO PLAYER 1
		PWM_OUT_VIBRA2	: out std_logic									-- SAÍDA PARA MOTOR DO CONTROLE DO PLAYER 2
	);

end som;
	
architecture projeto of som IS

component PWM
	port ( 
			 CLK 	 	: in  std_logic;
			 RST 	 	: in  std_logic;
			 ENABLE  	: in  std_logic;
			 SEL_PR		: in  std_logic_vector (1 downto 0);
			 TIMER 		: in  std_logic_vector ((RESO-1) DOWNTO 0);
			 DUTY  		: in  std_logic_vector ((RESO-1) DOWNTO 0);
			 PWM_OUT 	: out std_logic);
	end component;
	---------------------------------------------
	-- COMPONENTE RESPONSÁVEL POR GERAR UM PWM
	--
	--         			Fclk
	-- Fpwm = ------------------------   USAR 50MHz PARA O CLOCK
	--         (TIMER + 1)*PRESCALER
	--
	-- TIMER 8bits -> 0 à 255
	-- PRESCALER   -> 1, 4 ou 16
	-- DUTY X%   = Duty/TIMER*100%
	---------------------------------------------

	
	---------------------------------------------
	-- SINAIS PARA CONTROLE DOS PWM DO SOM, MUDAR SOMENTE SE NECESSÁRIO 
	---------------------------------------------
	type sound_FREQ is array(0 to 2) of std_logic_vector(7 downto 0); 	-- GUARDA AS FREQUÊNCIAS DAS ONDAS
	signal evento_FREQ, last_evento : sound_FREQ := (FREQ_0, FREQ_0, FREQ_0);
	signal flag_TOCA : boolean := false;
	
	constant limit_SOM 	: integer := FCLK/1000*MAX_SPEED_MS;
	constant limit_VIBRA : integer := FCLK/1000*MAX_SPEED_MS;
	constant limit_FREQ	: integer := 28;
	
	signal sig_RST_SOM 	: std_logic := '1';
	signal sig_ENABLE  	: std_logic := '1';
	signal sig_SEL_PR  	: std_logic_vector (1 downto 0) := "10"; 		-- DIVISOR DE CLOCK SETADO PARA 16
	signal sig_DUTY_SOM   	: std_logic_vector ((RESO-1) DOWNTO 0) := "00000001";		-- SOM NÃO IRÁ VARIAR O DUTY POIS ALTERA SOMENTE O VOLUME (VERIFICAR)
	signal sig_TIMER_SOM   : std_logic_vector ((RESO-1) DOWNTO 0);
	signal sig_PWM_OUT_SOM : std_logic ;
	signal SOM : std_logic := '0';
	---------------------------------------------
	
	
	---------------------------------------------
	-- SINAIS PARA CONTROLE DO MOTOR
	---------------------------------------------
	signal sig_VIBRA1		: std_logic;
	signal sig_VIBRA2		: std_logic;
	
	---------------------------------------------



	
	
	---------------------------------------------
	-- SINAIS AUXILIARES
	---------------------------------------------
	signal sig_REBATER, sig_REBATER2 : std_logic;
	signal sig_MORREU: std_logic;
	signal sig_ACABOU : std_logic;
	signal sig_MISSIL : std_logic;	
	signal evento_limit, evento_limit_vibra : integer range 1 to 400;
	---------------------------------------------
	
	begin		
	
	
	sig_REBATER <= REBATER;
	sig_REBATER2 <= REBATER2;
	sig_MORREU <= MORREU;
	sig_ACABOU <= ACABOU;						
	sig_MISSIL <= MISSIL;
		
	---------------------------------------------
	-- CUIDA DO TEMPO DE TROCA ENTRE SONS E VIBRA
	---------------------------------------------
	process (CLOCK)
	variable seq, vibra:natural range 0 to 101*limit_SOM := 0;
	variable change_SOUND: natural range 0 to 5  := 0;
	begin
		if rising_edge (CLOCK) then		
			
			if sig_MORREU = '1' then 									--TOCA POR 0,5s MORREU 
				evento_FREQ <= (FREQ_5, FREQ_5, FREQ_2); 
				evento_limit <= 10;    
				flag_TOCA <= true;
				change_SOUND := 0;
				sig_TIMER_SOM <= evento_FREQ(change_SOUND);				-- ATUALIZA A FREQUÊNCIA DA ONDA PWM 
				sig_RST_SOM <= '0';										-- HABILITA O SOM
				
			elsif sig_REBATER = '1' OR sig_REBATER2 = '1' then 			--REBATEU VIBRA E TOCA POR 0,25S
				evento_FREQ <= (FREQ_5, FREQ_3, FREQ_1); 
				evento_limit <= 3;
				evento_limit_vibra <=13; 
				flag_TOCA <= true;
				change_SOUND := 0;

				if(sig_REBATER = '1') then
					sig_VIBRA1 <= '1';
				elsif sig_REBATER2 = '1' then
					sig_VIBRA2 <= '1';
				end if;
				
				sig_TIMER_SOM <= evento_FREQ(change_SOUND);				-- ATUALIZA A FREQUÊNCIA DA ONDA PWM 
				sig_RST_SOM <= '0';										-- HABILITA O SOM
				
			elsif sig_ACABOU = '1' then 								--ACABOU VIBRA E TOCA POR 2S
				evento_FREQ <= (FREQ_3, FREQ_1, FREQ_3);	
				evento_limit <= 160;
				evento_limit_vibra <= 400;
				flag_TOCA <= true;
				change_SOUND := 0;
				sig_VIBRA1 <= '1';
				sig_VIBRA2 <= '1';
				sig_TIMER_SOM <= evento_FREQ(change_SOUND);				-- ATUALIZA A FREQUÊNCIA DA ONDA PWM 
				sig_RST_SOM <= '0';										-- HABILITA O SOM
				
			elsif sig_MISSIL = '1' then -- MISSIL TOCA E VIBRA POR 0,5s
				evento_FREQ <= (FREQ_2, FREQ_1, FREQ_1);	
				evento_limit <= 10;
				evento_limit_vibra <= 50;
				flag_TOCA <= true;
				change_SOUND := 0;
				sig_VIBRA1 <= '1';
				sig_VIBRA2 <= '1';
				sig_TIMER_SOM <= evento_FREQ(change_SOUND);				-- ATUALIZA A FREQUÊNCIA DA ONDA PWM 
				sig_RST_SOM <= '0';										-- HABILITA O SOM
			else 
				flag_TOCA <= true;
			end if;
			
			vibra := vibra + 1;
			if vibra = (evento_limit_vibra*limit_VIBRA - 1) AND (sig_VIBRA1 = '1' OR sig_VIBRA2 = '1') then			--PARA DE VIBRAR	
				vibra := 0;
				if(sig_VIBRA1 = '1') then
					sig_VIBRA1 <= '0'; 	
				elsif sig_VIBRA2 = '1' then
					sig_VIBRA2 <= '0'; 
				end if;				
			end if;				
				
			seq := seq + 1;
				if seq = (evento_limit*limit_SOM - 1) and flag_TOCA = true  then				
					seq := 0;					
					if (change_SOUND = 2) then
						sig_RST_SOM <= '1'; 							-- PARA DE TOCAR O SOM
						flag_TOCA <= false;
					else 
						change_SOUND := change_SOUND + 1;				-- ATUALIZA A FREQUÊNCIA DA ONDA PWM 
						sig_TIMER_SOM <= evento_FREQ(change_SOUND);									
					end if;						
				end if;	
		end if;
	end process;
	---------------------------------------------
	
	M1: PWM port map (CLOCK,sig_RST_SOM,sig_ENABLE,sig_SEL_PR,sig_TIMER_SOM,sig_DUTY_SOM,sig_PWM_OUT_SOM); -- COMPONENTE SOM		
	
	---------------------------------------------
	--- GERA ONDA DE 50% DUTY CYCLE DE ACORDO COM A FREQUÊNCIA SETADA
	--- SOM : onda com frequência = Fpwm / (limit_FREQ*2);
	---------------------------------------------
	process (sig_PWM_OUT_SOM)
	variable counter:natural range 0 to 400000000 := 0;
		begin 
			if rising_edge (sig_PWM_OUT_SOM) then					
				counter := counter + 1;
					if counter = limit_FREQ	then
						SOM <= not SOM;
    					counter := 0;
					end if;
			end if;
	end process;
	---------------------------------------------
	
	PWM_OUT_VIBRA1 <= sig_VIBRA1;
	PWM_OUT_VIBRA2 <= sig_VIBRA2;
	PWM_OUT_SOM  <= SOM;
		
end projeto;
	