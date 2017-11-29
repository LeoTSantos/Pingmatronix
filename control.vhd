LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE work.meupacote.all;
USE work.VgaDefinitions.all;
USE ieee.math_real.all;

ENTITY control IS
	GENERIC(
		FCLK: NATURAL := 50_000_000
	);
	PORT (
		clk: IN STD_LOGIC;
		in_sobe_raquete1, in_desce_raquete1:  IN STD_LOGIC;
		red, green, blue 				: out std_logic_vector (3 downto 0);
      Hsync, Vsync     				: out std_logic
	);
END ENTITY;

ARCHITECTURE arch OF control IS
	CONSTANT TEMPO_300MS: NATURAL := FCLK / 2;	
	CONSTANT TEMPO_AUMENTA_VELOCIDADE: NATURAL := FCLK * 5;
	CONSTANT TEMPO_10MS: NATURAL := FCLK / 100;
	CONSTANT tmax: NATURAL := FCLK * 5;
	
	SIGNAL TEMPO_ATUALIZACAO: NATURAL RANGE 0 TO FCLK := TEMPO_300MS;
	SIGNAL VX: NATURAL RANGE 0 TO 1 := 1;
	SIGNAL VY: NATURAL RANGE 0 TO 4 := 1;
	SIGNAL DIR_X, DIR_Y: STD_LOGIC := '1'; -- DIR_X = '1' => DIREITA; DIR_Y = '1' => BAIXO
	SIGNAL X: NATURAL RANGE 0 TO 63 := 32;
	SIGNAL Y: NATURAL RANGE 0 TO 47 := 24;
	SIGNAL RAQUETE1, RAQUETE2: NATURAL RANGE 3 TO 44;
	
	SIGNAL y_racket_p1, y_racket_p2: NATURAL RANGE 0 TO VGA_MAX_VERTICAL;
	--SIGNAL 
	
	SIGNAL SYS_CLK: STD_LOGIC;
		
-- FLAGS
	SIGNAL flag_put, flag_remove, flag_end_put, flag_end_remove: STD_LOGIC := '0';
BEGIN
	--DB1: entity work.debounce port map (clk => clk, input => not in_put, output => put);
	--DB2: entity work.debounce port map (clk => clk, input => not in_remove, output => remove);
--	DB3: entity work.debounce port map (clk => clk, input => not in_rst, output => rst);
	
--GERA SYS_CLK



VGA: ENTITY WORK.ScreenRender PORT MAP (  clock => clk,  
														red => red,
														green => green,
														blue	=> blue,	
														Hsync => Hsync,
														Vsync => Vsync,
														y_racket_p1 => y_racket_p1,
														y_racket_p2 => y_racket_p2,
														x_missle_p1 => 0,
														x_missle_p2 => 0,
														y_missle_p1 => 0,
														y_missle_p2 => 0,
														x_ball		=> x,
														y_ball 		=> y	);

														
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
		
		IF counter_aumenta_tempo = TEMPO_AUMENTA_VELOCIDADE - 1 THEN
			TEMPO_ATUALIZACAO <= TEMPO_ATUALIZACAO - TEMPO_10MS;
			counter := 0;
		END IF;
	END IF;
END PROCESS;

-- ATUALIZA POSICAO BOLA
PROCESS(sys_clk, clk)
BEGIN
	IF rising_edge(sys_clk) THEN
		IF DIR_X = '1' THEN
			IF X  > 63 - VX THEN
				X <= 62;
			ELSE
				X <= X + VX;
			END IF;
		ELSE
			IF X < VX  THEN
				X <= 1;
			ELSE
				X <= X - VX;
			END IF;
		END IF;
		
		IF DIR_Y = '1' THEN
			IF Y > 47 - VY THEN
				Y <= 46;
			ELSE
				Y <= Y + VY;
			END IF;
		ELSE
			IF Y < VY  THEN
				Y <= 1;
			ELSE
				Y <= Y - VY;
			END IF;
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
		
		IF DIR_X = '0' AND X = 0 THEN
			DIR_X <= '1';
		END IF;
		
		IF DIR_Y = '1' AND Y = 47 THEN
			DIR_Y <= '0';
		END IF;
		
		IF DIR_Y = '0' AND Y = 0 THEN
			DIR_Y <= '1';
		END IF;
	END IF;
END PROCESS;



END ARCHITECTURE;