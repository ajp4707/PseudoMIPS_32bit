library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity alu_ns is
	generic (
		WIDTH : positive := 32
	);
	port (
		input1 : in std_logic_vector(WIDTH-1 downto 0);
		input2 : in std_logic_vector(WIDTH-1 downto 0);
		OPsel : in std_logic_vector(4 downto 0);		-- 5 wide, ~ 16 unique ALU operations. See key
		sft_amt : in std_logic_vector(4 downto 0); 		-- 5 wide
		
		output_lo : out std_logic_vector(WIDTH-1 downto 0);
		output_hi : out std_logic_vector(WIDTH-1 downto 0);
		branch : out std_logic
	);
end alu_ns;

architecture alu_case of alu_ns is
begin
	process (input1, input2, OPsel, sft_amt)
		variable temp : unsigned(2*WIDTH-1 downto 0);
	begin
		branch <= '0';
		temp := to_unsigned(0, temp'length);
			
		case OPsel is
			when "00000" =>	-- Addition	
				temp := resize(unsigned(input1), temp'length) + unsigned(input2);
			when "00001" => -- Subtraction
				temp := resize(unsigned(input1), temp'length) - unsigned(input2);
			when "00010" => -- unsigned multiplication
				temp := unsigned(input1) * unsigned(input2);
			when "00011" => --signed multiplication
				temp := unsigned(signed(input1) * signed(input2));
			when "00100" => -- bitwise and
				temp := resize(unsigned(input1 and input2), temp'length);
			when "00101" => -- bitwise or
				temp := resize(unsigned(input1 or input2), temp'length);
			when "00110" => -- bitwise xor
				temp := resize(unsigned(input1 xor input2), temp'length);
			when "00111" => -- logical right shift
				temp := resize(shift_right(unsigned(input2), to_integer(unsigned(sft_amt))), temp'length);
			when "01000" => -- arithmetic right shift
				temp := unsigned(resize(shift_right(signed(input2), to_integer(unsigned(sft_amt))), temp'length));
			when "01001" => -- shift left
				temp := resize(shift_left(unsigned(input2), to_integer(unsigned(sft_amt))), temp'length);
			when "01010" => -- equal
				if (input1 = input2) then 
					branch <= '1';
					temp(0) := '1';
				end if;
			when "01011" => -- not equal
				if (input1 /= input2) then 
					branch <= '1';
					temp(0) := '1';
				end if;
			when "01100" => -- LT unsigned
				if (input1 < input2) then 
					branch <= '1';
					temp(0) := '1';
				end if;
			when "01101" => -- LT signed
				if (signed(input1) < signed(input2)) then 
					branch <= '1';
					temp(0) := '1';
				end if;
			when "01110" => -- LTE signed
				if (signed(input1) <= signed(input2)) then 
					branch <= '1';
					temp(0) := '1';
				end if;
			when "01111" => -- GT signed
				if (signed(input1) > signed(input2)) then 
					branch <= '1';
					temp(0) := '1';
				end if;
			when "10000" => -- GTE signed
				if (signed(input1) >= signed(input2)) then 
					branch <= '1';
					temp(0) := '1';
				end if;
			when "10001" => -- GTE signed
				temp := resize(unsigned(input1), temp'length);
			when others =>
				temp := to_unsigned(0, temp'length);
		end case;
		
		-- output <= temp
		output_lo <= std_logic_vector(temp(WIDTH-1 downto 0));
		output_hi <= std_logic_vector(temp(2*WIDTH-1 downto WIDTH));
	end process;
end alu_case;
