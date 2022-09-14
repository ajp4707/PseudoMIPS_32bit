library ieee;
use ieee.std_logic_1164.all;

entity mux4x1 is
	generic( WIDTH : positive );
	port(
		in0 : in std_logic_vector(WIDTH-1 downto 0);
		in1 : in std_logic_vector(WIDTH-1 downto 0);
		in2 : in std_logic_vector(WIDTH-1 downto 0);
		in3 : in std_logic_vector(WIDTH-1 downto 0);
		sel : in std_logic_vector(1 downto 0);
		output : out std_logic_vector(WIDTH-1 downto 0)
	);
end mux4x1;

architecture bhv of mux4x1 is
begin
	with sel select output <= 
		in0 when "00",
		in1 when "01",
		in2 when "10",
		in3 when others;
end bhv;