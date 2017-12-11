library IEEE;
use   IEEE.std_logic_1164.all;
use   IEEE.numeric_std.all;
 
entity PRESCALER is
 port ( s_CLK     : in  std_logic;
 s_RST     : in  std_logic;
 s_SEL_PR  : in  std_logic_vector (1 downto 0);
 OUT_CLK   : out std_logic);
end PRESCALER;
 
architecture RTL of PRESCALER is
 
 signal CLK4  : std_logic;
 signal CLK16 : std_logic;
 
 begin
 process(s_CLK,s_RST)
 variable CONT4  : integer range 0 to 2;
 variable CONT16 : integer range 0 to 8;
 begin
 if( s_RST = '1' ) then
 CLK4   <= '0';
 CLK16   <= '0';
 CONT4   :=  0;
 CONT16  :=  0;
 elsif( s_CLK = '1' and s_CLK'EVENT ) then
 
 -- GERAR AS DIVISOES DE FREQUENCIA /4 e /16
 -- OBS: VARIAVEL DO TIPO INTEIRA É SEQUENCIAL, OU SEJA, A ORDEM DESSE CÓDIGO IMPORTA
 
 CONT4  := CONT4  + 1;
 CONT16 := CONT16 + 1;
	if( CONT4 = 2 ) then
		CLK4 <= not CLK4;
		CONT4 := 0;
	end if;
	if( CONT16 = 8 ) then
		CLK16 <= not CLK16;
		CONT16  := 0;
	end if;
 
 end if;
 end process;
 
 -- MUX 4:1
 -- SELECIONA O CLK ESCOLHIDO
 
 with s_SEL_PR select
 OUT_CLK <= s_CLK and (not s_RST) when "00",
   CLK4  when "01",
   CLK16 when "10",
   '0'   when "11",
   '0'   when others;
   
end RTL;