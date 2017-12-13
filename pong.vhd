LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE work.VgaDefinitions.all;
USE work.PongDefinitions.all;
use work.SSDefinitions.all;

USE ieee.math_real.all;

entity pong is

	port (
		clock: IN STD_LOGIC;
		placar1_ssd, placar2_ssd: OUT SSD_ARRAY(natural(ceil(log10(real(MAX_PONTOS))))-1 downto 0);
		
		--monitor
		red, green, blue 				: out std_logic_vector (3 downto 0);
      Hsync, Vsync     				: out std_logic;
		
		
		--roda/pause
		start_sw: in std_logic;
		
		--controle 1
		vibra_1: out std_logic; 
		atira_1: in std_logic; 
		encoder_ckl_1: in std_logic; 
		encoder_d_1: in std_logic; 
		
		--controle 2
		vibra_2: out std_logic; 
		atira_2: in std_logic; 
		encoder_ckl_2: in std_logic; 
		encoder_d_2: in std_logic;
		
		--som
		pwm_som: out std_logic;
		
		LEDS: out std_logic_vector(9 DOWNTO 0)
		
	);
end entity;

architecture arch of pong is

	signal y_racket_p1, y_racket_p2: NATURAL range MIN_RACKET_Y to MAX_RACKET_Y;	
	signal x_missle_p1, x_missle_p2, x_ball:  NATURAL RANGE 0 TO VGA_MAX_HORIZONTAL;
	signal y_missle_p1, y_missle_p2, y_ball:  NATURAL RANGE 0 TO VGA_MAX_VERTICAL;
	signal atira_1_deb, atira_2_deb : std_logic;
	signal placar1, placar2 :  NATURAL RANGE 0 TO MAX_PONTOS;
	
	signal evento_ponto_1, evento_ponto_2, evento_rebateu_1, evento_rebateu_2, evento_missil_acertou_1, evento_missil_acertou_2, evento_fim_de_jogo:  STD_LOGIC;	

begin

-- entradas

	batedor1: entity work.batedor PORT MAP (clock => clock, clkrot => encoder_ckl_1, dtrot => encoder_d_1, position => y_racket_p1); 
	batedor2: entity work.batedor PORT MAP (clock => clock, clkrot => encoder_ckl_2, dtrot => encoder_d_2, position => y_racket_p2); 
	
	atiradeb1: entity work.deb_button PORT MAP (clock => clock, input => not atira_1, output => atira_1_deb); 
	atiradeb2: entity work.deb_button PORT MAP (clock => clock, input => not atira_2, output => atira_2_deb); 
	
--
	controle : entity work.control PORT MAP (	clock => clock,
															start => start_sw,
															placar1 => placar1, 
															placar2 => placar2, 
															missil1 => atira_1_deb,
															missil2 => atira_2_deb,
															
															y_racket_p1 => y_racket_p1,
															y_racket_p2 => y_racket_p2,
															x_missle_p1 => x_missle_p1,
															y_missle_p1 => y_missle_p1,
															x_missle_p2 => x_missle_p2,
															y_missle_p2 => y_missle_p2,
															x_ball => x_ball,
															y_ball => y_ball,
															
															evento_ponto_1 => evento_ponto_1,
															evento_ponto_2 => evento_ponto_2,
															evento_rebateu_1 => evento_rebateu_1,
															evento_rebateu_2 => evento_rebateu_2,
															evento_missil_acertou_1 => evento_missil_acertou_1,
															evento_missil_acertou_2 => evento_missil_acertou_2,
															evento_fim_de_jogo => evento_fim_de_jogo
															);
	
-- 

	vga: entity work.ScreenRender PORT MAP (clock => clock,
													  Hsync => Hsync,
													  Vsync => Vsync,
													  red => red,
													  green => green,
													  blue => blue,
													  
													  y_racket_p1 => y_racket_p1,
													  y_racket_p2 => y_racket_p2,
													  x_missle_p1 => x_missle_p1,
													  y_missle_p1 => y_missle_p1,
													  x_missle_p2 => x_missle_p2,
													  y_missle_p2 => y_missle_p2,
													  x_ball => x_ball,
													  y_ball => y_ball);

---
	p1: entity work.placar PORT MAP (pontos => placar1, ssds_out => placar2_ssd); 
	p2: entity work.placar PORT MAP (pontos => placar2, ssds_out => placar1_ssd); 
						
	s: entity work.som PORT MAP (CLOCK => clock,
										  REBATER => evento_rebateu_1,
										  REBATER2 => evento_rebateu_2,
										  MORREU => evento_ponto_1 or evento_ponto_2,
										  ACABOU => evento_fim_de_jogo,
										  MISSIL => evento_missil_acertou_1 or evento_missil_acertou_2,
										  
										  PWM_OUT_SOM => pwm_som
										  );
																				  
																					
	vib: entity work.vibra PORT MAP (	clock => clock,
													evento_ponto_1 => evento_ponto_1,
													evento_ponto_2 => evento_ponto_2,
													evento_rebateu_1 => evento_rebateu_1,
													evento_rebateu_2 => evento_rebateu_2,
													evento_missil_acertou_1 => evento_missil_acertou_1,
													evento_missil_acertou_2 => evento_missil_acertou_2,
													evento_fim_de_jogo => evento_fim_de_jogo,
													
													vibra_1 => vibra_1,
													vibra_2 => vibra_2);
													
	leds_1: entity work.LEDS_jogo PORT MAP ( clock_in => clock,
													 Raquete => evento_rebateu_1 or evento_rebateu_2,
													 Ponto => evento_ponto_1 or evento_ponto_2,
													 Missel => evento_missil_acertou_1 or evento_missil_acertou_2, 
													 Fim => evento_fim_de_jogo,
													 LEDS => LEDS);
	

		
	

end architecture;