

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.math_real.ceil;

entity vibra is
	generic(
		freq: natural := 50_000_000;
		t_batida: real := 0.1;
		t_morre: real := 1.5;
		t_ponto_on: real := 0.15;
		t_ponto_off: real := 0.08
		); 
	port (
		clock: IN std_logic;
		
		vibra_1, vibra_2: out std_logic; 
		evento_ponto_1, evento_ponto_2, evento_rebateu_1, evento_rebateu_2, evento_missil_acertou_1, evento_missil_acertou_2, evento_fim_de_jogo: in std_logic

		
	);
end entity;

architecture arch of vibra is

	constant MAX_counter_batida: natural := natural(ceil(real(freq)*t_batida));
	signal counter_batida_1, counter_batida_2: natural range 0 to MAX_counter_batida := 0;	
	
	constant MAX_counter_morre: natural := natural(ceil(real(freq)*t_morre));
	signal counter_morre_1, counter_morre_2: natural range 0 to MAX_counter_morre := 0;	
	
	constant MAX_counter_ponto_on: natural := natural(ceil(real(freq)*t_ponto_on));
	constant MAX_counter_ponto_off: natural := natural(ceil(real(freq)*t_ponto_off));
	
	signal counter_ponto_1, counter_ponto_2: natural range 0 to 2*MAX_counter_ponto_on + MAX_counter_ponto_off:= 0;	
	
	signal evento_morre_1, evento_morre_2 : std_logic;
	signal vibra_batida_1, vibra_batida_2, vibra_morre_1, vibra_morre_2, vibra_ponto_1, vibra_ponto_2: std_logic;

begin

	vibra_1 <= vibra_batida_1 or vibra_morre_1 or vibra_ponto_1;
	vibra_2 <= vibra_batida_2 or vibra_morre_2 or vibra_ponto_2;

	evento_morre_1 <= evento_ponto_2 or evento_missil_acertou_2;
	evento_morre_2 <= evento_ponto_1 or evento_missil_acertou_1;
	
	
	process (evento_rebateu_1, evento_rebateu_2, clock)
	begin

		if rising_edge(clock) then
		
			--rebate 1
			if evento_rebateu_1 = '1' then
				vibra_batida_1 <= '1';
				counter_batida_1 <= 1;
			end if;
			
			if counter_batida_1 > 0  and counter_batida_1 < MAX_counter_batida then
				counter_batida_1 <= counter_batida_1 + 1;
			end if;
			
			if counter_batida_1 = MAX_counter_batida then
				vibra_batida_1 <= '0';
				counter_batida_1 <= 0;
			end if;
			
			--rebate 2
			if evento_rebateu_2 = '1' then
				vibra_batida_2 <= '1';
				counter_batida_2 <= 1;
			end if;
			
			if counter_batida_2 > 0  and counter_batida_2 < MAX_counter_batida then
				counter_batida_2 <= counter_batida_2 + 1;
			end if;
			
			if counter_batida_2 = MAX_counter_batida then
				vibra_batida_2 <= '0';
				counter_batida_2 <= 0;
			end if;
			
			--morre 1
			if evento_morre_1 = '1' then
				vibra_morre_1 <= '1';
				counter_morre_1 <= 1;
			end if;
			
			if counter_morre_1 > 0  and counter_morre_1 < MAX_counter_morre then
				counter_morre_1 <= counter_morre_1 + 1;
			end if;
			
			if counter_morre_1 = MAX_counter_morre then
				vibra_morre_1 <= '0';
				counter_morre_1 <= 0;
			end if;
			
			--morre 2
			if evento_morre_2 = '1' then
				vibra_morre_2 <= '1';
				counter_morre_2 <= 1;
			end if;
			
			if counter_morre_2 > 0  and counter_morre_2 < MAX_counter_morre then
				counter_morre_2 <= counter_morre_2 + 1;
			end if;
			
			if counter_morre_2 = MAX_counter_morre then
				vibra_morre_2 <= '0';
				counter_morre_2 <= 0;
			end if;
			
			--ponto 1
			
			if evento_ponto_1 = '1' then
				vibra_ponto_1 <= '1';
				counter_ponto_1 <= 1;
			end if;
			
			if counter_ponto_1 > 0  and counter_ponto_1 < MAX_counter_ponto_on*2 + MAX_counter_ponto_off then
				counter_ponto_1 <= counter_ponto_1 + 1;
			end if;
			
			if counter_ponto_1 = MAX_counter_ponto_on then
				vibra_ponto_1 <= '0';
			end if;
			
			if counter_ponto_1 = MAX_counter_ponto_on + MAX_counter_ponto_off then
				vibra_ponto_1 <= '1';
			end if;
			
			if counter_ponto_1 = 2*MAX_counter_ponto_on + MAX_counter_ponto_off then
				vibra_ponto_1 <= '0';
				counter_ponto_1 <= 0;
			end if;
			
			--ponto 2
			
			if evento_ponto_2 = '1' then
				vibra_ponto_2 <= '1';
				counter_ponto_2 <= 1;
			end if;
			
			if counter_ponto_2 > 0  and counter_ponto_2 < MAX_counter_ponto_on*2 + MAX_counter_ponto_off then
				counter_ponto_2 <= counter_ponto_2 + 1;
			end if;
			
			if counter_ponto_2 = MAX_counter_ponto_on then
				vibra_ponto_2 <= '0';
			end if;
			
			if counter_ponto_2 = MAX_counter_ponto_on + MAX_counter_ponto_off then
				vibra_ponto_2 <= '1';
			end if;
			
			if counter_ponto_2 = 2*MAX_counter_ponto_on + MAX_counter_ponto_off then
				vibra_ponto_2 <= '0';
				counter_ponto_2 <= 0;
			end if;
		
		end if;
	end process;

end architecture;