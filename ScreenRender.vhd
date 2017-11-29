Library IEEE;
use IEEE.STD_Logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;
use work.VgaDefinitions.all;

entity ScreenRender is
    port (
      clock            				: in std_logic;
		
      red, green, blue 				: out std_logic_vector (3 downto 0);
      Hsync, Vsync     				: out std_logic;
		
		y_racket_p1, y_racket_p2	: in natural range 0 to VGA_MAX_VERTICAL;
		x_missle_p1, x_missle_p2	: in natural range 0 to VGA_MAX_VERTICAL;
		y_missle_p1, y_missle_p2	: in natural range 0 to VGA_MAX_HORIZONTAL;
		
		x_ball							: in natural range 0 to VGA_MAX_VERTICAL;
		y_ball					 		: in natural range 0 to VGA_MAX_HORIZONTAL
    );
end;

architecture arch of ScreenRender is
	signal reset:     STD_LOGIC;
	signal start:     STD_LOGIC;
	signal y_control: natural range 0 to 900;
	signal x_control: natural range 0 to 900;
	signal video_on:  STD_LOGIC;
begin
	
	start <= '1';
	reset <= '0';
	
	vga_sync: entity work.sync_mod PORT MAP (clk => clock, 
														  reset => reset,
														  start => start,
														  y_control => y_control,
														  x_control => x_control,
														  h_s => Hsync,
														  v_s => Vsync,
														  video_on => video_on);
   
   process (all)
		variable x_screen, y_screen : natural;
   begin
		if video_on = '1' then
			
			x_screen := x_control / 10;
			y_screen := y_control / 10;
			
			-- Racket Player 1
			if x_screen = 2 and (y_screen <= y_racket_p1 + 2 and y_screen >= y_racket_p1 - 2) then
				red <= (others => '1');
				green <= (others => '1');
				blue <= (others => '1');
			
			-- Racket Player 2
			elsif x_screen = VGA_MAX_HORIZONTAL - 3 and (y_screen <= y_racket_p2 + 2 and y_screen >= y_racket_p2 - 2) then
				red <= (others => '1');
				green <= (others => '1');
				blue <= (others => '1');
			
			-- Ball
			elsif x_screen = x_ball and y_screen = y_ball then
				red <= (others => '0');
				green <= (others => '1');
				blue <= (others => '0');
			
			-- Missle Player 1
			elsif (x_screen <= x_missle_p1 + 1 and x_screen >= x_missle_p1 - 1) and y_screen = y_missle_p1 then
				red <= (others => '0');
				green <= (others => '0');
				blue <= (others => '1');
			
			-- Missle Player 2
			elsif (x_screen <= x_missle_p2 + 1 and x_screen >= x_missle_p2 - 1) and y_screen = y_missle_p2 then
				red <= (others => '1');
				green <= (others => '0');
				blue <= (others => '0');
				
			else 
				red <= (others => '0');
				green <= (others => '0');
				blue <= (others => '0');			
			end if;
		else 
			red <= (others => '0');
			green <= (others => '0');
			blue <= (others => '0');
		end if;
   end process;
end architecture;