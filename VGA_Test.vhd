Library IEEE;
use IEEE.STD_Logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;
use work.VgaDefinitions.all;

entity VGA_Test is
    port (
      clock            				: in std_logic;
      red, green, blue 				: out std_logic_vector (3 downto 0);
      Hsync, Vsync     				: out std_logic
    );
end;

architecture arch of VGA_Test is
begin
	
	vga: entity work.ScreenRender PORT MAP (clock => clock,
													  Hsync => Hsync,
													  Vsync => Vsync,
													  red => red,
													  green => green,
													  blue => blue,
													  y_racket_p1 => 30,
													  y_racket_p2 => 30,
													  x_missle_p1 => 20,
													  y_missle_p1 => 30,
													  x_missle_p2 => 40,
													  y_missle_p2 => 30,
													  x_ball => 30,
													  y_ball => 30
													 );
   
end architecture;