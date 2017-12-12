LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE work.VgaDefinitions.all;
USE work.PongDefinitions.all;
USE ieee.math_real.all;

ENTITY control IS
	GENERIC(
		NUM_MAX: NATURAL := 99;
		Fclock: NATURAL := 50_000_000
	);
	PORT (
		clock: IN STD_LOGIC;
		start: IN STD_LOGIC;
		
		
		placar1, placar2 : OUT NATURAL RANGE 0 TO MAX_PONTOS;
		
		
		missil1, missil2:  IN STD_LOGIC;

		
		y_racket_p1, y_racket_p2	: in NATURAL range MIN_RACKET_Y to MAX_RACKET_Y;
				
																
		x_missle_p1, x_missle_p2, x_ball: out NATURAL RANGE 0 TO VGA_MAX_HORIZONTAL;
		y_missle_p1, y_missle_p2, y_ball: out NATURAL RANGE 0 TO VGA_MAX_VERTICAL;
		
		evento_ponto_1, evento_ponto_2, evento_rebateu_1, evento_rebateu_2, evento_missil_acertou_1, evento_missil_acertou_2, evento_fim_de_jogo: out STD_LOGIC		
	);
END ENTITY;

ARCHITECTURE arch OF control IS


	CONSTANT TEMPO_300MS: NATURAL := Fclock * 3 / 10;	
	CONSTANT TEMPO_100MS: NATURAL := Fclock / 10;	
	CONSTANT TEMPO_AUMENTA_VELOCIDADE: NATURAL := Fclock * 5;
	CONSTANT TEMPO_10MS: NATURAL := Fclock / 100;
	CONSTANT TEMPO_15S: NATURAL := Fclock * 15;
	CONSTANT tmax: NATURAL := Fclock * 15;
	
	SIGNAL TEMPO_ATUALIZACAO: NATURAL RANGE 0 TO Fclock := TEMPO_300MS;
	SIGNAL VX: NATURAL RANGE 0 TO 1 := 1;
	SIGNAL VY: NATURAL RANGE 0 TO 4 := 1;
	SIGNAL DIR_X, DIR_Y: STD_LOGIC := '0'; -- DIR_X = '1' => DIREITA; DIR_Y = '1' => BAIXO
	SIGNAL X: NATURAL RANGE 0 TO 63 := 32;
	SIGNAL Y: NATURAL RANGE 0 TO 47 := 24;
	SIGNAL RANDOM_VX, RANDOM_VY: STD_LOGIC := '0';
	

	SIGNAL x_missle_p1_sig	: NATURAL RANGE 0 TO VGA_MAX_VERTICAL;
	SIGNAL y_missle_p1_sig	: NATURAL RANGE 0 TO VGA_MAX_HORIZONTAL;
	SIGNAL x_missle_p2_sig	: NATURAL RANGE 0 TO VGA_MAX_HORIZONTAL;
	SIGNAL y_missle_p2_sig	: NATURAL RANGE 0 TO VGA_MAX_VERTICAL;
	
	SIGNAL evento_ponto_1_sig,evento_ponto_2_sig, evento_rebateu_1_sig,evento_rebateu_2_sig, evento_missil_acertou_1_sig, evento_missil_acertou_2_sig, evento_fim_de_jogo_sig: STD_LOGIC;
		
	SIGNAL fim_de_jogo: STD_LOGIC;
	SIGNAL jogo_rodando: STD_LOGIC;
	SIGNAL SYS_clock: STD_LOGIC;
	SIGNAL reset_xy: STD_LOGIC := '0';
	
	SIGNAL PONTOS1, PONTOS2: NATURAL RANGE 0 TO MAX_PONTOS := 0;
BEGIN

	placar1 <= PONTOS1;
	placar2 <= PONTOS2;

	x_ball <= X;
	y_ball <= Y;
		
	x_missle_p1 <= x_missle_p1_sig;
	y_missle_p1 <= y_missle_p1_sig;
	x_missle_p2 <= x_missle_p2_sig;
	y_missle_p2 <= y_missle_p2_sig;
	
	evento_ponto_1 <= evento_ponto_1_sig;
	evento_ponto_2 <= evento_ponto_2_sig;
	evento_rebateu_1 <= evento_rebateu_1_sig;
	evento_rebateu_2 <= evento_rebateu_2_sig;
	evento_missil_acertou_1 <= evento_missil_acertou_1_sig;
	evento_missil_acertou_2 <= evento_missil_acertou_2_sig;
	evento_fim_de_jogo <= evento_fim_de_jogo_sig;
									
	jogo_rodando <= '0' WHEN start = '0' OR fim_de_jogo = '1' ELSE '1';

--GERA SINAL FIM DE JOGO
PROCESS (clock)
BEGIN
	IF rising_edge (clock) THEN
		IF	PONTOS1 = MAX_PONTOS OR PONTOS2 = MAX_PONTOS THEN
			fim_de_jogo <= '1';
		ELSE
			fim_de_jogo <= '0';
		END IF;
	END IF;
END PROCESS;	
																	
-- ATUALIZA POSICAO BOLA
PROCESS(clock)

--counter(natural) serve pra contar o tempo de atialização do passo da bolinhas. O valor máximo da contagem é TEMPO_ATUALIZACAO_AUX
VARIABLE counter: NATURAL RANGE 0 TO tmax;

--Quando ele chega no valor máximo, diminui TEMPO_ATUALIZACAO_AUX em 10ms (em clock)
VARIABLE counter_aumenta_tempo: NATURAL RANGE 0 TO TEMPO_AUMENTA_VELOCIDADE;

--tempo do passo da bolinha
VARIABLE TEMPO_ATUALIZACAO_AUX: NATURAL RANGE 0 TO Fclock := TEMPO_300MS;
BEGIN
    --start = 1 quando o jogo está rodando, start = 0 quando pausa ou não iniciou
	IF rising_edge(clock) AND jogo_rodando = '1' THEN
		counter := counter + 1;
		counter_aumenta_tempo := counter_aumenta_tempo + 1;

        --aumenta a velocidade da bolinha periodicamente, sendo o mínimo 10mm
		IF counter_aumenta_tempo = TEMPO_AUMENTA_VELOCIDADE - 1 THEN
			IF TEMPO_ATUALIZACAO_AUX > TEMPO_10MS THEN
				TEMPO_ATUALIZACAO_AUX := TEMPO_ATUALIZACAO_AUX - TEMPO_10MS;
			END IF;
			counter := 0;
		END IF;
		
        --morte do jogador = (X < VX OR X > VGA_MAX_HORIZONTAL - VX)
		-- SE UM JOGADOR MORREU, RESETA A VELOCIDADE PARA A ORIGINAL
		IF X < VX OR X > VGA_MAX_HORIZONTAL - VX THEN
			TEMPO_ATUALIZACAO_AUX := TEMPO_300MS;
		END IF;
		
		--MISSIL 1 ACERTOU RAQUETE 2 -> VOLTA BOLA PRO CENTRO
		IF x_missle_p1_sig = VGA_MAX_HORIZONTAL - 3 THEN
			IF y_missle_p1_sig <= y_racket_p2 + 2 AND y_missle_p1_sig >= y_racket_p2 - 2 THEN
				X <= 32; --centro tela
				Y <= 24;
			END IF;
		END IF;
		
		--MISSIL 2 ACERTOU RAQUETE 1 -> VOLTA BOLA PRO CENTRO
		IF x_missle_p2 = 2 THEN
			IF y_missle_p2 <= y_racket_p1 + 2 AND y_missle_p2 >= y_racket_p1 - 2 THEN
				X <= 32; --centro tela
				Y <= 24;
			END IF;
		END IF;
		
        --anda a bola
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

-- GERA DIR_X E DIR_Y ALEATORIOS COSNTANTEMENTE
-- SERVE SOMENTE PARA INICIALIAÇÃO DA DIREÇÃO DA BOLA (começo do jogo/ depois que morre)
PROCESS(clock)
VARIABLE COUNTER_1, COUNTER_2: NATURAL RANGE 0 TO 14;
BEGIN
	IF rising_edge(clock) THEN
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
PROCESS(clock)
VARIABLE counter: NATURAL RANGE 0 TO tmax;
VARIABLE counter_aumenta_tempo: NATURAL RANGE 0 TO TEMPO_AUMENTA_VELOCIDADE;
VARIABLE TEMPO_ATUALIZACAO_AUX: NATURAL RANGE 0 TO Fclock := TEMPO_300MS;
BEGIN
	IF rising_edge(clock) AND jogo_rodando = '1' THEN
		counter := counter + 1;
		counter_aumenta_tempo := counter_aumenta_tempo + 1;

		evento_ponto_1_sig <= '0';
		evento_ponto_2_sig <= '0';
		evento_rebateu_1_sig <= '0';
		evento_rebateu_2_sig <= '0';
		evento_fim_de_jogo_sig <= '0';
				
        --se morrer
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
		IF x_missle_p1_sig = VGA_MAX_HORIZONTAL - 3 THEN
			IF y_missle_p1_sig <= y_racket_p2 + 2 AND y_missle_p1_sig >= y_racket_p2 - 2 THEN
				PONTOS1 <= PONTOS1 + 1;
				DIR_X <= RANDOM_VX;
				DIR_Y <= RANDOM_VY;
				VY <= 1;
				evento_ponto_1_sig <= '1';
			END IF;
		END IF;
		
		--MISSIL ACERTOU RAQUETE 1 -> PONTTO DO JOGADOR 2
		IF x_missle_p2 = 2 THEN
			IF y_missle_p2 <= y_racket_p1 + 2 AND y_missle_p2 >= y_racket_p1 - 2 THEN
				PONTOS2 <= PONTOS2 + 1;
				DIR_X <= RANDOM_VX;
				DIR_Y <= RANDOM_VY;
				VY <= 1;
				evento_ponto_2_sig <= '1';
			END IF;
		END IF;
		
	-- REBATE RAQUETE ESQUERDA
		IF X = 3 AND DIR_X = '0' THEN
			IF Y  <= y_racket_p1 + 2 AND Y >= y_racket_p1 - 2  THEN
				DIR_X <= '1';
				evento_rebateu_1_sig <= '1';
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
				evento_rebateu_2_sig <= '1';
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
				evento_ponto_2_sig <= '1';
			END IF;
			
			--BOLA CHEGOU NA PAREDE DIREITA -> PONTO DO JOGADOR 1
			IF DIR_X = '1' AND X = VGA_MAX_HORIZONTAL THEN
				PONTOS1 <= PONTOS1 + 1;
				DIR_X <= RANDOM_VX;
				DIR_Y <= RANDOM_VY;
				VY <= 1;
				evento_ponto_1_sig <= '1';
			END IF;
			
			-- REBATE EM CIMA E EM BAIXO		
			IF DIR_Y = '1' AND Y > 47 - VY THEN
				DIR_Y <= '0';
			END IF;
			
			IF DIR_Y = '0' AND Y < 0 + VY THEN
				DIR_Y <= '1';
			END IF;
		END IF;
	END IF;
END PROCESS;

-- LANÇA MISSSIL1
PROCESS (clock)
VARIABLE IS_MISSIL1 : STD_LOGIC := '0';
VARIABLE counter_missil: NATURAL RANGE 0 TO TEMPO_10MS;
VARIABLE counter_permite_missil1: NATURAL RANGE 0 TO tmax;
VARIABLE IS_MISSIL2 : STD_LOGIC := '0';
VARIABLE counter_missi2: NATURAL RANGE 0 TO TEMPO_10MS;
VARIABLE counter_permite_missil2: NATURAL RANGE 0 TO tmax;
BEGIN
	IF rising_edge(clock) AND jogo_rodando = '1' THEN
		evento_missil_acertou_1_sig <= '0';
		evento_missil_acertou_2_sig <= '0';
		-- MISSIL 1 ACERTOU -> SOME DA TELA
		IF x_missle_p1 = VGA_MAX_HORIZONTAL - 3 THEN
			IF y_missle_p1_sig <= y_racket_p2 + 2 AND y_missle_p1_sig >= y_racket_p2 - 2 THEN
				x_missle_p1_sig <= 0;
				y_missle_p1_sig <= 0;
				IS_MISSIL1 := '0';
				evento_missil_acertou_1_sig <= '1';
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
				IF x_missle_p1_sig = 0 THEN
					x_missle_p1_sig <= 1;
					y_missle_p1_sig <= y_racket_p1;
				ELSIF x_missle_p1_sig < VGA_MAX_HORIZONTAL - 3 THEN
					x_missle_p1_sig <= x_missle_p1 + 1;
				ELSE
					x_missle_p1_sig <= 0;
					IS_MISSIL1 := '0';
				END IF;
			END IF;
		END IF;
		
		-- MISSIL 2 ACERTOU -> SOME DA TELA
		IF x_missle_p2_sig = 2 THEN
			IF y_missle_p2_sig <= y_racket_p1 + 2 AND y_missle_p2_sig >= y_racket_p1 - 2 THEN
				x_missle_p2_sig <= 0;
				y_missle_p2_sig <= 0;
				IS_MISSIL2 := '0';
				evento_missil_acertou_2_sig <= '1';
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
				IF x_missle_p2_sig	= 0 THEN
					x_missle_p2_sig <= VGA_MAX_HORIZONTAL - 1;
					y_missle_p2_sig <= y_racket_p2;
				ELSIF x_missle_p2_sig > 2 THEN
					x_missle_p2_sig <= x_missle_p2_sig - 1;
				ELSE
					x_missle_p2_sig <= 0;
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

----ATUALIZA POSICAO DA RAQUETE
--PROCESS (clock)
--BEGIN
--	IF rising_edge(clock) AND start = '1' THEN
--		IF sobe_raquete1 = '1' THEN
--			y_racket_p1 <= y_racket_p1 + 1;
--		END IF;
--		
--		IF desce_raquete1 = '1' THEN
--			y_racket_p1 <= y_racket_p1 - 1;
--		END IF;	
--		
--
--	END IF;
--END PROCESS;

--PRINTA PONTOS POR DEBUG  2
--divisor(0) <= 1;
--	G4: FOR i IN 1 TO NATURAL(CEIL(LOG10(REAL(NUM_MAX))))-1 GENERATE
--		divisor(i) <= divisor(i-1)*10;
--	END GENERATE G4;

--G6: FOR i IN 0 TO NATURAL(CEIL(LOG10(REAL(NUM_MAX))))-1 GENERATE
--		aux_disp(i) <= (PONTOS1	/ divisor(i)) MOD 10;
--		output_debug1(i) <= num_0 WHEN aux_disp(i) = 0 ELSE
--		  num_1 WHEN aux_disp(i) = 1 ELSE
--		  num_2 WHEN aux_disp(i) = 2 ELSE
--		  num_3 WHEN aux_disp(i) = 3 ELSE
--		  num_4 WHEN aux_disp(i) = 4 ELSE
--		  num_5 WHEN aux_disp(i) = 5 ELSE
--		  num_6 WHEN aux_disp(i) = 6 ELSE
--		  num_7 WHEN aux_disp(i) = 7 ELSE
--		  num_8 WHEN aux_disp(i) = 8 ELSE
--		  num_9 WHEN aux_disp(i) = 9 ELSE
--		  num_a WHEN aux_disp(i) = 10 ELSE
--		  num_b WHEN aux_disp(i) = 11 ELSE
--		  num_c WHEN aux_disp(i) = 12 ELSE
--		  num_d WHEN aux_disp(i) = 13 ELSE
--		  num_e WHEN aux_disp(i) = 14 ELSE
--		  num_f;
--	END GENERATE G6;
--
----PRINTA PONTOS POR DEBUG  2
--G3: FOR i IN 0 TO NATURAL(CEIL(LOG10(REAL(NUM_MAX))))-1 GENERATE
--		aux_disp2(i) <= (PONTOS2	/ divisor(i)) MOD 10;
--		output_debug2(i) <= num_0 WHEN aux_disp2(i) = 0 ELSE
--		  num_1 WHEN aux_disp2(i) = 1 ELSE
--		  num_2 WHEN aux_disp2(i) = 2 ELSE
--		  num_3 WHEN aux_disp2(i) = 3 ELSE
--		  num_4 WHEN aux_disp2(i) = 4 ELSE
--		  num_5 WHEN aux_disp2(i) = 5 ELSE
--		  num_6 WHEN aux_disp2(i) = 6 ELSE
--		  num_7 WHEN aux_disp2(i) = 7 ELSE
--		  num_8 WHEN aux_disp2(i) = 8 ELSE
--		  num_9 WHEN aux_disp2(i) = 9 ELSE
--		  num_a WHEN aux_disp2(i) = 10 ELSE
--		  num_b WHEN aux_disp2(i) = 11 ELSE
--		  num_c WHEN aux_disp2(i) = 12 ELSE
--		  num_d WHEN aux_disp2(i) = 13 ELSE
--		  num_e WHEN aux_disp2(i) = 14 ELSE
--		  num_f;
--	END GENERATE G3;
	
	

END ARCHITECTURE;