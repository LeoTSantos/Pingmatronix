library IEEE;
use     IEEE.std_logic_1164.all;
use     IEEE.std_logic_unsigned.all;
 
entity PWM is 
 port ( CLK : in  std_logic;
 RST : in  std_logic;
 ENABLE  : in  std_logic;
 SEL_PR : in  std_logic_vector (1 downto 0);
 TIMER : in  std_logic_vector (7 downto 0);
 DUTY   : in  std_logic_vector (7 downto 0);
 PWM_OUT : out std_logic);
end entity;
 
architecture RTL of PWM is
 
 component PRESCALER
 port ( s_CLK     : in  std_logic;
 s_RST     : in  std_logic;
 s_SEL_PR  : in  std_logic_vector (1 downto 0);
 OUT_CLK   : out std_logic);
 end component;
 
 signal s_OUT_CLK  : std_logic; 
 signal CYCLE_OFF  : std_logic_vector (7 downto 0);
 signal s_PWM_OUT  : std_logic;
 signal CONT       : std_logic_vector (7 downto 0);
 
 begin
 
 U0 : PRESCALER port map (CLK,RST,SEL_PR,s_OUT_CLK);
 
 CYCLE_OFF <= TIMER - DUTY - '1';
 
 -- CASO ESPECIAL:
 
 with TIMER select
 PWM_OUT <= s_OUT_CLK and ENABLE and (not RST) when "00000000",
   s_PWM_OUT when others;
 
 process(s_OUT_CLK,RST)
 begin
 if( RST = '1' ) then
 s_PWM_OUT <= '0';
 CONT      <= "00000000";
 elsif( s_OUT_CLK = '1' and s_OUT_CLK'EVENT ) then
 
 if( ENABLE = '1' ) then
 
 -- CONTA PULSOS DO CLOCK
 CONT <= CONT + '1';
 
 if ( CONT = CYCLE_OFF ) then
 s_PWM_OUT <= '1';
 elsif ( CONT = TIMER ) then
 s_PWM_OUT <= '0';
 CONT      <= "00000000";
 end if;
 
 else
 s_PWM_OUT <= '0'; 
 CONT      <= "00000000";
 end if;
 end if;
 end process;
 end RTL;