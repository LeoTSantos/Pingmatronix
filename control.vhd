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
		
		output_debug: OUT SSDARRAY (NATURAL(CEIL(LOG10(REAL(NUM_MAX))))-1 DOWNTO 0);
		
		in_sobe_raquete1, in_desce_raquete1, in_missil1:  IN STD_LOGIC;
		red, green, blue 				: out std_logic_vector (3 downto 0);
      Hsync, Vsync     				: out std_logic
	);
END ENTITY;

ARCHITECTURE arch OF control IS
	TYPE TIPODISP IS ARRAY (NATURAL(CEIL(LOG10(REAL(NUM_MAX))))-1 DOWNTO 0) OF INTEGER RANGE 0 TO 9;
	TYPE DIV IS ARRAY(NATURAL(CEIL(LOG10(REAL(NUM_MAX))))-1 DOWNTO 0) OF NATURAL RANGE 0 TO 10**(NATURAL(CEIL(LOG10(		REAL(NUM_MAX))))-1);
	signal divisor: DIV;
	signal aux_disp: TIPODISP;


	CONSTANT TEMPO_300MS: NATURAL := FCLK * 3 / 10;	
	CONSTANT TEMPO_100MS: NATURAL := FCLK / 10;	
	CONSTANT TEMPO_AUMENTA_VELOCIDADE: NATURAL := FCLK * 5;
	CONSTANT TEMPO_10MS: NATURAL := FCLK / 100;
	CONSTANT tmax: NATURAL := FCLK * 5;
	
	SIGNAL TEMPO_ATUALIZACAO: NATURAL RANGE 0 TO FCLK := TEMPO_300MS;
	SIGNAL VX: NATURAL RANGE 0 TO 1 := 1;
	SIGNAL VY: NATURAL RANGE 0 TO 4 := 1;
	SIGNAL DIR_X, DIR_Y: STD_LOGIC := '0'; -- DIR_X = '1' => DIREITA; DIR_Y = '1' => BAIXO
	SIGNAL X: NATURAL RANGE 0 TO 63 := 32;
	SIGNAL Y: NATURAL RANGE 0 TO 47 := 24;
	SIGNAL RAQUETE1, RAQUETE2: NATURAL RANGE 3 TO 44;
	
	SIGNAL y_racket_p1, y_racket_p2: NATURAL RANGE 0 TO VGA_MAX_VERTICAL;
	SIGNAL sobe_raquete1, desce_raquete1, missil1: STD_LOGIC;
	SIGNAL x_missle_p1	: NATURAL RANGE 0 TO VGA_MAX_VERTICAL;
	SIGNAL y_missle_p1	: NATURAL RANGE 0 TO VGA_MAX_HORIZONTAL;
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
														x_missle_p2 => 0,
														y_missle_p1 => y_missle_p1,
														y_missle_p2 => 0,
														x_ball		=> x,
														y_ball 		=> y	);
														

--GERA SYS_CLK									
PROCESS(clk)
VARIABLE counter: NATURAL RANGE 0 TO tmax;
VARIABLE counter_aumenta_tempo: NATURAL RANGE 0 TO TEMPO_AUMENTA_VELOCIDADE;
BEGIN
	IF rising_edge(clk) THEN
		counter := counter + 1;
		counter_aumenta_tempo := counter_aumenta_tempo + 1;
		IF counter = TEMPO_ATUALIZACAO - 1 THEN
			sys_clk <= '1';
			counter := 0;
		ELSE
			sys_clk <= '0';
		END IF;
		
		IF X < VX THEN
			TEMPO_ATUALIZACAO <= TEMPO_300MS;
		END IF;
		
		IF counter_aumenta_tempo = TEMPO_AUMENTA_VELOCIDADE - 1 THEN
			IF TEMPO_ATUALIZACAO > TEMPO_10MS THEN
				TEMPO_ATUALIZACAO <= TEMPO_ATUALIZACAO - TEMPO_10MS;
			END IF;
			counter := 0;
		END IF;
	END IF;
END PROCESS;

-- ATUALIZA POSICAO BOLA
PROCESS(sys_clk)
VARIABLE OLD_PONTOS1: NATURAL RANGE 0 TO MAX_PONTOS := 0;
BEGIN
	IF rising_edge(sys_clk) THEN
		IF DIR_X = '1' THEN
			IF X  > 63 - VX THEN
				X <= 63;
			ELSE
				X <= X + VX;
			END IF;
		ELSE
			X <= X - VX;
		END IF;
		
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
		
		-- ACONTECEU PONTO 
		-- ADICIONAR PONTO DO OUTRO LADO
		IF X < VX THEN
			X <= 32;
			Y <= 24;
		END IF;
	END IF;
END PROCESS;

-- ATUALIZA VELOCIDADE
PROCESS(sys_clk, clk)
BEGIN
	IF rising_edge(sys_clk) THEN
		IF DIR_X = '1' AND X = 63 THEN
			DIR_X <= '0';
		END IF;
				
		--PONTO DO JOGADOR 1
		IF DIR_X = '0' AND X = 0 THEN
			PONTOS1 <= PONTOS1 + 1;
		END IF;
				
		IF DIR_Y = '1' AND Y > 47 - VY THEN
			DIR_Y <= '0';
		END IF;
		
		IF DIR_Y = '0' AND Y < 0 + VY THEN
			DIR_Y <= '1';
		END IF;
		
		IF X = 3 AND DIR_X = '0' THEN
			IF Y <= y_racket_p1 + 2 AND Y >= y_racket_p1 - 2  THEN
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
		
		
		IF X = 45 AND DIR_X = '1' THEN
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
END PROCESS;

-- LANÇA MISSSIL1
PROCESS (clk)
VARIABLE IS_MISSIL1 : STD_LOGIC := '0';
VARIABLE counter_missil: NATURAL RANGE 0 TO TEMPO_10MS;
BEGIN
	IF rising_edge(clk) THEN
			
		counter_missil:= counter_missil + 1;
		IF counter_missil = TEMPO_10MS - 1 THEN
			counter_missil := 0;
			
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
		
		IF missil1 = '1' THEN
			IS_MISSIL1 := '1';
		END IF;
	END IF;
	
	
END PROCESS;

--ATUALIZA POSICAO DA RAQUETE
PROCESS (clk)
BEGIN
	IF rising_edge(clk) THEN
		IF sobe_raquete1 = '1' THEN
			y_racket_p1 <= y_racket_p1 + 1;
		END IF;
		
		IF desce_raquete1 = '1' THEN
			y_racket_p1 <= y_racket_p1 - 1;
		END IF;	
	END IF;
END PROCESS;

--PRINTA PONTOS POR DEBUG
divisor(0) <= 1;
	G1: FOR i IN 1 TO NATURAL(CEIL(LOG10(REAL(NUM_MAX))))-1 GENERATE
		divisor(i) <= divisor(i-1)*10;
	END GENERATE G1;

G3: FOR i IN 0 TO NATURAL(CEIL(LOG10(REAL(NUM_MAX))))-1 GENERATE
		aux_disp(i) <= (PONTOS1 / divisor(i)) MOD 10;
		output_debug(i) <= num_0 WHEN aux_disp(i) = 0 ELSE
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
	END GENERATE G3;
	

END ARCHITECTURE;