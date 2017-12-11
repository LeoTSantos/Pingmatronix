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
		pwm_som: out std_logic
		
	);
end entity;

architecture arch of pong is

	signal y_racket_p1, y_racket_p2: NATURAL range MIN_RACKET_Y to MAX_RACKET_Y;	
	signal x_missle_p1, x_missle_p2, x_ball:  NATURAL RANGE 0 TO VGA_MAX_HORIZONTAL;
	signal y_missle_p1, y_missle_p2, y_ball:  NATURAL RANGE 0 TO VGA_MAX_VERTICAL;
	signal atira_1_deb, atira_2_deb : std_logic;
	signal placar1, placar2 :  NATURAL RANGE 0 TO MAX_PONTOS;
	
	signal evento_ponto, evento_rebateu, evento_missil_acertou, evento_fim_de_jogo:  STD_LOGIC;	

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
															
															evento_ponto => evento_ponto,
															evento_rebateu  => evento_rebateu, 
															evento_missil_acertou  => evento_missil_acertou, 
															evento_fim_de_jogo  => evento_fim_de_jogo
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
						
	som: entity work.Controle_de_som_vibracao_ssd_v2 PORT MAP (CLOCK => clock,
																				  REBATER => evento_rebateu,
																				  REBATER2 => evento_rebateu,
																				  MORREU => evento_ponto,
																				  ACABOU => evento_fim_de_jogo,
																				  MISSIL => evento_missil_acertou,
																				  
																				  PWM_OUT_SOM => pwm_som,
																				  PWM_OUT_VIBRA1 => vibra_1,
																				  PWM_OUT_VIBRA2 => vibra_2);
							

end architecture;