library ieee;
use ieee.std_logic_1164.all;

entity reg is
	generic( WIDTH : positive );
	port(
		input : in std_logic_vector(WIDTH-1 downto 0);
		en : in std_logic;
		clk : in std_logic;
		rst : in std_logic;
		output : out std_logic_vector(WIDTH-1 downto 0)
	);
end reg;

architecture bhv of reg is
begin
	process(clk, rst)
	begin
		if(rst='1') then
			output <= (others => '0');
		elsif (rising_edge(clk)) then
			if (en = '1') then
				output <= input;
			end if;
		end if;
	end process;
end bhv;