LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE work.meupacote.all;
USE work.VgaDefinitions.all;
USE ieee.math_real.all;

ENTITY control IS
	GENERIC(
		MAX_PONTOS: NATURAL := 99;
		NUM_MAX: NATURAL := 99;
		FCLK: NATURAL := 50_000_000
	);
	PORT (
		clk: IN STD_LOGIC;
		start: IN STD_LOGIC;
		output_debug1, output_debug2: OUT SSDARRAY (NATURAL(CEIL(LOG10(REAL(NUM_MAX))))-1 DOWNTO 0);
		
		in_sobe_raquete1, in_desce_raquete1, in_missil1:  IN STD_LOGIC;
		red, green, blue 				: out std_logic_vector (3 downto 0);
      Hsync, Vsync     				: out std_logic;
		missil2 						: in std_logic
	);
END ENTITY;

ARCHITECTURE arch OF control IS
	TYPE TIPODISP IS ARRAY (NATURAL(CEIL(LOG10(REAL(NUM_MAX))))-1 DOWNTO 0) OF INTEGER RANGE 0 TO 9;
	TYPE DIV IS ARRAY(NATURAL(CEIL(LOG10(REAL(NUM_MAX))))-1 DOWNTO 0) OF NATURAL RANGE 0 TO 10**(NATURAL(CEIL(LOG10(		REAL(NUM_MAX))))-1);
	signal divisor: DIV;
	signal aux_disp, aux_disp2: TIPODISP;

	CONSTANT TEMPO_300MS: NATURAL := FCLK * 3 / 10;	
	CONSTANT TEMPO_100MS: NATURAL := FCLK / 10;	
	CONSTANT TEMPO_AUMENTA_VELOCIDADE: NATURAL := FCLK * 5;
	CONSTANT TEMPO_10MS: NATURAL := FCLK / 100;
	CONSTANT TEMPO_15S: NATURAL := FCLK * 15;
	CONSTANT tmax: NATURAL := FCLK * 15;
	
	SIGNAL TEMPO_ATUALIZACAO: NATURAL RANGE 0 TO FCLK := TEMPO_300MS;
	SIGNAL VX: NATURAL RANGE 0 TO 1 := 1;
	SIGNAL VY: NATURAL RANGE 0 TO 4 := 1;
	SIGNAL DIR_X, DIR_Y: STD_LOGIC := '0'; -- DIR_X = '1' => DIREITA; DIR_Y = '1' => BAIXO
	SIGNAL X: NATURAL RANGE 0 TO 63 := 32;
	SIGNAL Y: NATURAL RANGE 0 TO 47 := 24;
	SIGNAL RAQUETE1, RAQUETE2: NATURAL RANGE 3 TO 44;
	SIGNAL RANDOM_VX, RANDOM_VY: STD_LOGIC := '0';
	
	SIGNAL y_racket_p1, y_racket_p2: NATURAL RANGE 0 TO VGA_MAX_VERTICAL;
	SIGNAL sobe_raquete1, desce_raquete1, missil1: STD_LOGIC;
	SIGNAL x_missle_p1	: NATURAL RANGE 0 TO VGA_MAX_VERTICAL;
	SIGNAL y_missle_p1	: NATURAL RANGE 0 TO VGA_MAX_HORIZONTAL;
	SIGNAL x_missle_p2	: NATURAL RANGE 0 TO VGA_MAX_HORIZONTAL;
	SIGNAL y_missle_p2	: NATURAL RANGE 0 TO VGA_MAX_VERTICAL;
	SIGNAL SYS_CLK: STD_LOGIC;
	SIGNAL reset_xy: STD_LOGIC := '0';
	
	SIGNAL PONTOS1, PONTOS2: NATURAL RANGE 0 TO MAX_PONTOS := 0;
BEGIN
	DB1: entity work.debounce port map (clk => clk, input => not in_sobe_raquete1, output => sobe_raquete1);
	DB2: entity work.debounce port map (clk => clk, input => not in_desce_raquete1, output => desce_raquete1);
	DB3: entity work.debounce port map (clk => clk, input => not in_missil1, output => missil1);

VGA: ENTITY WORK.ScreenRender PORT MAP (  clock => clk,  
														red => red,
														green => green,
														blue	=> blue,	
														Hsync => Hsync,
														Vsync => Vsync,
														y_racket_p1 => y_racket_p1,
														y_racket_p2 => y_racket_p2,
														x_missle_p1 => x_missle_p1,
														x_missle_p2 => x_missle_p2,
														y_missle_p1 => y_missle_p1,
														y_missle_p2 => y_missle_p2,
														x_ball		=> x,
														y_ball 		=> y	);
																												
-- ATUALIZA POSICAO BOLA
PROCESS(CLK)
VARIABLE counter: NATURAL RANGE 0 TO tmax;
VARIABLE counter_aumenta_tempo: NATURAL RANGE 0 TO TEMPO_AUMENTA_VELOCIDADE;
VARIABLE TEMPO_ATUALIZACAO_AUX: NATURAL RANGE 0 TO FCLK := TEMPO_300MS;
BEGIN
	IF rising_edge(clk) AND start = '1' THEN
		counter := counter + 1;
		counter_aumenta_tempo := counter_aumenta_tempo + 1;

		IF counter_aumenta_tempo = TEMPO_AUMENTA_VELOCIDADE - 1 THEN
			IF TEMPO_ATUALIZACAO_AUX > TEMPO_10MS THEN
				TEMPO_ATUALIZACAO_AUX := TEMPO_ATUALIZACAO_AUX - TEMPO_10MS;
			END IF;
			counter := 0;
		END IF;
		
		-- SE UM JOGADOR MORREU, RESETA A VELOCIDADE PARA A LENTA
		IF X < VX OR X > VGA_MAX_HORIZONTAL - VX THEN
			TEMPO_ATUALIZACAO_AUX := TEMPO_300MS;
		END IF;
		
		--MISSIL ACERTOU RAQUETE 2 -> VOLTA BOLA PRO CENTRO
		IF x_missle_p1 = VGA_MAX_HORIZONTAL - 2 THEN
			IF y_missle_p1 < y_racket_p2 + 2 AND y_missle_p1 > y_racket_p2 - 2 THEN
				X <= 32;
				Y <= 24;
			END IF;
		END IF;
		
		--MISSIL ACERTOU RAQUETE 1 -> VOLTA BOLA PRO CENTRO
		IF x_missle_p2 = 2 THEN
			IF y_missle_p2 < y_racket_p1 + 2 AND y_missle_p2 > y_racket_p1 - 2 THEN
				X <= 32;
				Y <= 24;
			END IF;
		END IF;
		
		IF counter = TEMPO_ATUALIZACAO - 1 THEN
			counter := 0;
			
			-- ATUALIZA POSICAO X
			IF DIR_X = '1' THEN
				X <= X + VX;
			ELSE
				X <= X - VX;
			END IF;
			
			-- ATUALIZA POSICAO Y
			IF DIR_Y = '1' THEN
				IF Y > 47 - VY THEN
					Y <= 47;
				ELSE
					Y <= Y + VY;
				END IF;
			ELSE
				IF Y < VY  THEN
					Y <= 0;
				ELSE 
					Y <= Y - VY;
				END IF;
			END IF;
			
			-- CHEGOU NA PAREDE ESQUERDA: PONTO DO JGOADOR 2
			IF X < VX THEN
				X <= 32;
				Y <= 24;
			END IF;
			-- CHEGOU NA PAREDE DIREITA: PONTO DO JOGADOR 1
			IF X > VGA_MAX_HORIZONTAL - VX THEN
				X <= 32;
				Y <= 24;
			END IF;
		END IF;
	END IF;
END PROCESS;

-- GERA DIR_X E DIR_Y ALEATORIOS
PROCESS(clk)
VARIABLE COUNTER_1, COUNTER_2: NATURAL RANGE 0 TO 14;
BEGIN
	IF rising_edge(clk) THEN
		COUNTER_1 := COUNTER_1 + 1;
		IF COUNTER_1 = 7 THEN
			COUNTER_1 := 0;
			RANDOM_VX <= NOT RANDOM_VX;
		END IF;
		
		COUNTER_2 := COUNTER_2 + 1;
		IF COUNTER_2 = 14 THEN
			COUNTER_2 := 0;
			RANDOM_VY <= NOT RANDOM_VY;
		END IF;
	END IF;
END PROCESS;

-- ATUALIZA VELOCIDADE
PROCESS(clk)
VARIABLE counter: NATURAL RANGE 0 TO tmax;
VARIABLE counter_aumenta_tempo: NATURAL RANGE 0 TO TEMPO_AUMENTA_VELOCIDADE;
VARIABLE TEMPO_ATUALIZACAO_AUX: NATURAL RANGE 0 TO FCLK := TEMPO_300MS;
BEGIN
	IF rising_edge(clk) AND start = '1' THEN
		counter := counter + 1;
		counter_aumenta_tempo := counter_aumenta_tempo + 1;
		
		IF X < VX OR X > VGA_MAX_HORIZONTAL - VX THEN
			TEMPO_ATUALIZACAO_AUX := TEMPO_300MS;
		END IF;
		
		IF counter_aumenta_tempo = TEMPO_AUMENTA_VELOCIDADE - 1 THEN
			IF TEMPO_ATUALIZACAO_AUX > TEMPO_10MS THEN
				TEMPO_ATUALIZACAO_AUX := TEMPO_ATUALIZACAO_AUX - TEMPO_10MS;
			END IF;
			counter := 0;
		END IF;
		
		--MISSIL ACERTOU RAQUETE 2 -> PONTTO DO JOGADOR 1
		IF x_missle_p1 = VGA_MAX_HORIZONTAL - 2 THEN
			IF y_missle_p1 < y_racket_p2 + 2 AND y_missle_p1 > y_racket_p2 - 2 THEN
				PONTOS1 <= PONTOS1 + 1;
				DIR_X <= RANDOM_VX;
				DIR_Y <= RANDOM_VY;
				VY <= 1;
			END IF;
		END IF;
		
		--MISSIL ACERTOU RAQUETE 1 -> PONTTO DO JOGADOR 2
		IF x_missle_p2 = 2 THEN
			IF y_missle_p2 < y_racket_p1 + 2 AND y_missle_p2 > y_racket_p1 - 2 THEN
				PONTOS2 <= PONTOS2 + 1;
				DIR_X <= RANDOM_VX;
				DIR_Y <= RANDOM_VY;
				VY <= 1;
			END IF;
		END IF;
		
		IF counter = TEMPO_ATUALIZACAO - 1 THEN
			counter := 0;
			
			-- INICIALIZA ALEATORIAMENTE
			IF PONTOS1 = 0 AND PONTOS2 = 0 AND X = 32 AND Y = 24 THEN
				DIR_X <= RANDOM_VX;
				DIR_Y <= RANDOM_VY;
			END IF;
					
			--BOLA CHEGOU NA PAREDE ESQUERDA -> PONTO DO JOGADOR 2
			IF DIR_X = '0' AND X = 0 THEN
				PONTOS2 <= PONTOS2 + 1;
				DIR_X <= RANDOM_VX;
				DIR_Y <= RANDOM_VY;
				VY <= 1;
			END IF;
			
			--BOLA CHEGOU NA PAREDE DIREITA -> PONTO DO JOGADOR 1
			IF DIR_X = '1' AND X = VGA_MAX_HORIZONTAL THEN
				PONTOS1 <= PONTOS1 + 1;
				DIR_X <= RANDOM_VX;
				DIR_Y <= RANDOM_VY;
				VY <= 1;
			END IF;
			
			-- REBATE EM CIMA E EM BAIXO		
			IF DIR_Y = '1' AND Y > 47 - VY THEN
				DIR_Y <= '0';
			END IF;
			
			IF DIR_Y = '0' AND Y < 0 + VY THEN
				DIR_Y <= '1';
			END IF;
			
			-- REBATE RAQUETE ESQUERDA
			IF X = 4 AND DIR_X = '0' THEN
				IF Y  <= y_racket_p1 + 2 AND Y >= y_racket_p1 - 2  THEN
					DIR_X <= '1';
					IF Y = y_racket_p1 + 2 OR Y = y_racket_p1 - 2 THEN
						VY <= 3;
					END IF;
					IF Y = y_racket_p1 + 1 OR Y = y_racket_p1 - 1 THEN
						VY <= 2;
					END IF;
					IF Y = y_racket_p1 THEN
						VY <= 1;
					END IF;
				END IF;
			END IF;
			
			-- REBATE NA REQUETE DIREITA
			IF X = VGA_MAX_HORIZONTAL - 4 AND DIR_X = '1' THEN
				IF Y <= y_racket_p2 + 2 AND Y >= y_racket_p2 - 2  THEN
					DIR_X <= '0';
					IF Y = y_racket_p2 + 2 OR Y = y_racket_p2 - 2 THEN
						VY <= 3;
					END IF;
					IF Y = y_racket_p2 + 1 OR Y = y_racket_p2 - 1 THEN
						VY <= 2;
					END IF;
					IF Y = y_racket_p2 THEN
						VY <= 1;
					END IF;
				END IF;
			END IF;
		END IF;
	END IF;
END PROCESS;

-- LANÇA MISSSIL1
PROCESS (clk)
VARIABLE IS_MISSIL1 : STD_LOGIC := '0';
VARIABLE counter_missil: NATURAL RANGE 0 TO TEMPO_10MS;
VARIABLE counter_permite_missil1: NATURAL RANGE 0 TO tmax;
VARIABLE IS_MISSIL2 : STD_LOGIC := '0';
VARIABLE counter_missi2: NATURAL RANGE 0 TO TEMPO_10MS;
VARIABLE counter_permite_missil2: NATURAL RANGE 0 TO tmax;
BEGIN
	IF rising_edge(clk) AND start = '1' THEN
		-- MISSIL 1 ACERTOU -> SOME DA TELA
		IF x_missle_p1 = VGA_MAX_HORIZONTAL - 2 THEN
			IF y_missle_p1 < y_racket_p2 + 2 AND y_missle_p1 > y_racket_p2 - 2 THEN
				x_missle_p1 <= 0;
				y_missle_p1 <= 0;
				IS_MISSIL1 := '0';
			END IF;
		END IF;
		
		-- CONTADOR MISSIL 1 DE 15 SEGUNDOS
		IF counter_permite_missil1 /= TEMPO_15S - 1 THEN	
			counter_permite_missil1 := counter_permite_missil1 + 1;
		END IF;
			
		counter_missil:= counter_missil + 1;
		IF counter_missil = TEMPO_10MS - 1 THEN
			counter_missil := 0;
			
			-- ATUALIZA POSICAO DO MISSIL 1
			IF IS_MISSIL1 = '1' THEN
				IF x_missle_p1 = 0 THEN
					x_missle_p1 <= 1;
					y_missle_p1 <= y_racket_p1;
				ELSIF x_missle_p1 < VGA_MAX_HORIZONTAL - 2 THEN
					x_missle_p1 <= x_missle_p1 + 1;
				ELSE
					x_missle_p1 <= 0;
					IS_MISSIL1 := '0';
				END IF;
			END IF;
		END IF;
		
		-- MISSIL 2 ACERTOU -> SOME DA TELA
		IF x_missle_p2 = 2 THEN
			IF y_missle_p2 < y_racket_p1 + 2 AND y_missle_p2 > y_racket_p1 - 2 THEN
				x_missle_p2 <= 0;
				y_missle_p2 <= 0;
				IS_MISSIL2 := '0';
			END IF;
		END IF;
		
		-- CONTADOR MISSIL 2	DE 15 SEGUNDOS
		IF counter_permite_missil2 /= TEMPO_15S - 1 THEN	
			counter_permite_missil2 := counter_permite_missil2 + 1;
		END IF;
			
		counter_missi2:= counter_missi2 + 1;
		IF counter_missi2 = TEMPO_10MS - 1 THEN
			counter_missi2 := 0;
			
			-- ATUALIZA POSICAO DO MISSIL 2
			IF IS_MISSIL2 = '1' THEN
				IF x_missle_p2	= 0 THEN
					x_missle_p2 <= VGA_MAX_HORIZONTAL - 1;
					y_missle_p2 <= y_racket_p2;
				ELSIF x_missle_p2 > 2 THEN
					x_missle_p2 <= x_missle_p2 - 1;
				ELSE
					x_missle_p2 <= 0;
					IS_MISSIL2 := '0';
				END IF;
			END IF;
		END IF;
		
		-- RECEBE DO HARDWARE - MISSIL 1
		IF missil1 = '1' AND counter_permite_missil1 = TEMPO_15S - 1 THEN
			counter_permite_missil1 := 0;
			IS_MISSIL1 := '1';
		END IF;
		
		-- RECEBE DO HARDWARE - MISSIL 2
		IF missil2	= '1' AND counter_permite_missil2 = TEMPO_15S - 1 THEN
			counter_permite_missil2 := 0;
			IS_MISSIL2 := '1';
		END IF;
	END IF;
	
	
END PROCESS;

--ATUALIZA POSICAO DA RAQUETE
PROCESS (clk)
BEGIN
	IF rising_edge(clk) AND start = '1' THEN
		IF sobe_raquete1 = '1' THEN
			y_racket_p1 <= y_racket_p1 + 1;
		END IF;
		
		IF desce_raquete1 = '1' THEN
			y_racket_p1 <= y_racket_p1 - 1;
		END IF;	
		
		IF sobe_raquete1 = '1' THEN
			y_racket_p2 <= y_racket_p2 + 1;
		END IF;
		
		IF desce_raquete1 = '1' THEN
			y_racket_p2 <= y_racket_p2 - 1;
		END IF;	
	END IF;
END PROCESS;

--PRINTA PONTOS POR DEBUG  2
divisor(0) <= 1;
	G4: FOR i IN 1 TO NATURAL(CEIL(LOG10(REAL(NUM_MAX))))-1 GENERATE
		divisor(i) <= divisor(i-1)*10;
	END GENERATE G4;

G6: FOR i IN 0 TO NATURAL(CEIL(LOG10(REAL(NUM_MAX))))-1 GENERATE
		aux_disp(i) <= (PONTOS1	/ divisor(i)) MOD 10;
		output_debug1(i) <= num_0 WHEN aux_disp(i) = 0 ELSE
		  num_1 WHEN aux_disp(i) = 1 ELSE
		  num_2 WHEN aux_disp(i) = 2 ELSE
		  num_3 WHEN aux_disp(i) = 3 ELSE
		  num_4 WHEN aux_disp(i) = 4 ELSE
		  num_5 WHEN aux_disp(i) = 5 ELSE
		  num_6 WHEN aux_disp(i) = 6 ELSE
		  num_7 WHEN aux_disp(i) = 7 ELSE
		  num_8 WHEN aux_disp(i) = 8 ELSE
		  num_9 WHEN aux_disp(i) = 9 ELSE
		  num_a WHEN aux_disp(i) = 10 ELSE
		  num_b WHEN aux_disp(i) = 11 ELSE
		  num_c WHEN aux_disp(i) = 12 ELSE
		  num_d WHEN aux_disp(i) = 13 ELSE
		  num_e WHEN aux_disp(i) = 14 ELSE
		  num_f;
	END GENERATE G6;

--PRINTA PONTOS POR DEBUG  2
G3: FOR i IN 0 TO NATURAL(CEIL(LOG10(REAL(NUM_MAX))))-1 GENERATE
		aux_disp2(i) <= (PONTOS2	/ divisor(i)) MOD 10;
		output_debug2(i) <= num_0 WHEN aux_disp2(i) = 0 ELSE
		  num_1 WHEN aux_disp2(i) = 1 ELSE
		  num_2 WHEN aux_disp2(i) = 2 ELSE
		  num_3 WHEN aux_disp2(i) = 3 ELSE
		  num_4 WHEN aux_disp2(i) = 4 ELSE
		  num_5 WHEN aux_disp2(i) = 5 ELSE
		  num_6 WHEN aux_disp2(i) = 6 ELSE
		  num_7 WHEN aux_disp2(i) = 7 ELSE
		  num_8 WHEN aux_disp2(i) = 8 ELSE
		  num_9 WHEN aux_disp2(i) = 9 ELSE
		  num_a WHEN aux_disp2(i) = 10 ELSE
		  num_b WHEN aux_disp2(i) = 11 ELSE
		  num_c WHEN aux_disp2(i) = 12 ELSE
		  num_d WHEN aux_disp2(i) = 13 ELSE
		  num_e WHEN aux_disp2(i) = 14 ELSE
		  num_f;
	END GENERATE G3;
	
	

END ARCHITECTURE;