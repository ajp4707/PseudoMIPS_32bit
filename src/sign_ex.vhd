library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sign_ex is
	generic (
		WIDTH_IN: positive
	);
	port(
		input : in std_logic_vector(WIDTH_IN-1 downto 0);
		output : out std_logic_vector(WIDTH_IN*2 - 1 downto 0);
		isSigned : in std_logic
	);
end sign_ex;

architecture BHV of sign_ex is
begin
	output(WIDTH_IN-1 downto 0) <= input;
	
	with isSigned select output(WIDTH_IN*2 -1 downto WIDTH_IN) <= 
		(others => input(WIDTH_IN-1)) when '1', --sign extend MSB
		(others => '0') when others;
end BHV;