library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.MyPacket.all; --used for SSD, can be removed

entity Inputs_vFinal is
	generic (
		FCLK: NATURAL := 50_000_000;
		NUM_SSD: NATURAL := 4 --used only to test(must be removed)
	);
	
	port (
		CLK: IN STD_LOGIC;
		
		--Rotary Encoder 1
		clk_rot1: IN STD_LOGIC; --clk pin (rotary encoder) - PIN_AB15 (board pin we have used)
		dt_rot1: IN STD_LOGIC;  --dt pin (rotary encoder) - PIN_AA16 (board pin we have used)
		btnMissel1: IN STD_LOGIC; --sw pin (rotary encoder) - PIN_AB16 (board pin we have used)
		
		--Rotary Encoder 2
		clk_rot2: IN STD_LOGIC; --clk pin (rotary encoder) - PIN_AB19 (board pin we have used)
		dt_rot2: IN STD_LOGIC;  --dt pin (rotary encoder) - PIN_AB20 (board pin we have used)
		btnMissel2: IN STD_LOGIC; --sw pin (rotary encoder) - PIN_AA20 (board pin we have used)
		
		--ports declared to test
		SSD: OUT SSDArray (NUM_SSD-1 DOWNTO 0);
		ledBat1, ledBat2: OUT STD_LOGIC
	);
end entity;

architecture arch of Inputs_vFinal IS
	TYPE display_vector is array (NUM_SSD-1 DOWNTO 0) of NATURAL; --used only to test(must be removed)
	
	signal positionBat1, positionBat2: NATURAL;
	signal bat1shot, bat2shot: std_logic;
	
	--signals used to tests (must be removed)
	signal teste1, teste2: std_logic;
	signal total: NATURAL;
	signal quociente, resto: display_vector;
	
	begin
	--we used the debounce file that was already on the git repository
	misselBat1: entity work.debounce PORT MAP (clk => CLK, input => btnMissel1, output => bat1shot);
	misselBat2: entity work.debounce PORT MAP (clk => CLK, input => btnMissel2, output => bat2shot);
	moveBat1: entity work.batedor PORT MAP (clk => CLK, clkrot => clk_rot1, dtrot => dt_rot1, position => positionBat1); 
	moveBat2: entity work.batedor PORT MAP (clk => CLK, clkrot => clk_rot2, dtrot => dt_rot2, position => positionBat2); 
	--NOTE: in debounce entity we used TEMPO_25MS = FCLK / 2500 for rotary encoder clock debounce, but it can be
	--changed, looking for a better response
		
	process (all)
	variable counter:natural;
	begin  --player 1 shots
		if rising_edge(bat1shot) then			
			--implement here the code responsible to shot dynamic
			teste1 <= not teste1; --used only to test(must be removed)
		end if;	
	end process;
	
	process (all)
	variable counter:natural;
	begin  --player 2 shots
		if rising_edge(bat2shot) then			
			--implement here the code responsible to shot dynamic
			teste2 <= not teste2; --used only to test(must be removed)
		end if;	
	end process;

	
	--the code below was used to verify if the rotary encoder is working properly
	--it shows the "batedor" position in SSD
	--it must be removed
	ledBat1 <= teste1;
	ledBat2 <= teste2;
	
	total <= 100*positionBat1 + positionBat2;
	
	quociente(0) <= total/(10**(NUM_SSD-1));
	resto(0) <= total mod (10**(NUM_SSD-1));
	
	SSD(NUM_SSD-1)	<= "1000000" WHEN quociente(0) = 0 ELSE
			 "1111001" WHEN quociente(0) = 1 ELSE
			 "0100100" WHEN quociente(0) = 2 ELSE
			 "0110000" WHEN quociente(0) = 3 ELSE
			 "0011001" WHEN quociente(0) = 4 ELSE
			 "0010010" WHEN quociente(0) = 5 ELSE
			 "0000010" WHEN quociente(0) = 6 ELSE
			 "1111000" WHEN quociente(0) = 7 ELSE
			 "0000000" WHEN quociente(0) = 8 ELSE
			 "0010000" WHEN quociente(0) = 9 ELSE
			 "1111111" ;
	
	gen2: FOR i IN 1 TO NUM_SSD-1 GENERATE
	quociente(i) <= resto(i-1)/(10**(NUM_SSD-1-i));
	resto(i) <= resto(i-1) mod (10**(NUM_SSD-1-i));
	
	SSD(NUM_SSD-1-i)	<= "1000000" WHEN quociente(i) = 0 ELSE
			 "1111001" WHEN quociente(i) = 1 ELSE
			 "0100100" WHEN quociente(i) = 2 ELSE
			 "0110000" WHEN quociente(i) = 3 ELSE
			 "0011001" WHEN quociente(i) = 4 ELSE
			 "0010010" WHEN quociente(i) = 5 ELSE
			 "0000010" WHEN quociente(i) = 6 ELSE
			 "1111000" WHEN quociente(i) = 7 ELSE
			 "0000000" WHEN quociente(i) = 8 ELSE
			 "0010000" WHEN quociente(i) = 9 ELSE
			 "1111111" ;
	END GENERATE;
	
end architecture;