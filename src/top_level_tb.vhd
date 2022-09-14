library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_level_tb is 
end top_level_tb;

architecture top_level_tb of top_level_tb is
	signal clk  	:std_logic := '0';
	signal clken 	:std_logic := '1';
	signal switch   :std_logic_vector(9 downto 0);
	signal button   :std_logic_vector(1 downto 0);
	signal led0     :std_logic_vector(6 downto 0);
	signal led0_dp  :std_logic;
	signal led1     :std_logic_vector(6 downto 0);
	signal led1_dp  :std_logic;
	signal led2     :std_logic_vector(6 downto 0);
	signal led2_dp  :std_logic;
	signal led3     :std_logic_vector(6 downto 0);
	signal led3_dp  :std_logic;
	signal led4     :std_logic_vector(6 downto 0);
	signal led4_dp  :std_logic;
	signal led5     :std_logic_vector(6 downto 0);
	signal led5_dp  :std_logic;
begin
	U_top : entity work.top_level
	port map(
		clk50MHz => clk   ,
		switch   => switch     ,
		button   => button     ,
		led0     => led0       ,
		led0_dp  => led0_dp    ,
		led1     => led1       ,
		led1_dp  => led1_dp    ,
		led2     => led2       ,
		led2_dp  => led2_dp    ,
		led3     => led3       ,
		led3_dp  => led3_dp    ,
		led4     => led4       ,
		led4_dp  => led4_dp    ,
		led5     => led5       ,
		led5_dp  => led5_dp    
	);

	clk <= not clk and clkEn after 20 ns;

	switch <= "0111111111";


process
begin
	clkEn <= '1';
	button(0) <= '0';		--rst = 1
	
	-- we should load up the input ports
	button(1) <= '0';
	
	for i in 0 to 3 loop 
		wait until clk'event and clk = '1';
    end loop;
	
	button(1) <= '1';
	
	wait until clk'event and clk = '1';
	
	button(0) <= '1';
	
	for i in 0 to 300 loop 
		wait until clk'event and clk = '1';
    end loop; 
	
clkEn <= '0';	
report("Sim complete!");
wait;
end process;
	
end top_level_tb;
