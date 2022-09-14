library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu_ns_tb is
end alu_ns_tb;

architecture alu_tb of alu_ns_tb is
	component alu_ns
		generic(
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
	end component;

	constant WIDTH : positive := 32;
	signal input1 : std_logic_vector(WIDTH-1 downto 0);
	signal input2 : std_logic_vector(WIDTH-1 downto 0);
	signal OPsel : std_logic_vector(4 downto 0);
	signal sft_amt : std_logic_vector(4 downto 0);
	
	signal branch : std_logic;
	signal output_lo : std_logic_vector(WIDTH-1 downto 0);
	signal output_hi : std_logic_vector(WIDTH-1 downto 0);
	
begin	-- TB
	UUT : alu_ns
		generic map (WIDTH => WIDTH)
		port map(
			input1 => input1,
			input2 => input2,
			OPsel => OPsel,
			sft_amt => sft_amt,

			output_lo => output_lo,
			output_hi => output_hi,
			branch => branch
		);
		
	process
	
	variable temp : signed(2*WIDTH -1 downto 0);
	begin
		-- test 10 + 15
		sft_amt <= "00000";
        OPsel    <= "00000";
        input1 <= std_logic_vector(to_unsigned(10, input1'length));
        input2 <= std_logic_vector(to_unsigned(15, input2'length));
        wait for 40 ns;
        assert(output_lo = std_logic_vector(to_unsigned(25, output_lo'length))) 
			report "Test 1 output_lo wrong" severity warning;
		assert(output_hi = std_logic_vector(to_unsigned(0, output_hi'length))) 
			report "Test 1 ouptut_hi wrong" severity warning;
		
		-- test 25 - 10
        OPsel    <= "00001";
        input1 <= std_logic_vector(to_unsigned(25, input1'length));
        input2 <= std_logic_vector(to_unsigned(10, input2'length));
        wait for 40 ns;
        assert(output_lo = std_logic_vector(to_unsigned(15, output_lo'length))) 
			report "Test 2 output_lo wrong" severity warning;
		assert(output_hi = std_logic_vector(to_unsigned(0, output_hi'length))) 
			report "Test 2 ouptut_hi wrong" severity warning;

		-- test signed 10 * -4
        OPsel    <= "00011";
        input1 <= std_logic_vector(to_signed(10, input1'length));
        input2 <= std_logic_vector(to_signed(-4, input2'length));
        wait for 40 ns;
		temp := to_signed(10 * (-4), temp'length);
        assert(output_lo = std_logic_vector(temp(WIDTH-1 downto 0))) 
			report "Test 3 output_lo wrong" severity warning;
		assert(output_hi = std_logic_vector(temp(WIDTH*2-1 downto WIDTH))) 
			report "Test 3 ouptut_hi wrong" severity warning;
			
        -- test unsigned 65536 * 131072
        OPsel    <= "00010";
        input1 <= std_logic_vector(to_unsigned(65536, input1'length));
        input2 <= std_logic_vector(to_unsigned(131072, input2'length));
        wait for 40 ns;
		temp := signed(to_unsigned(65536, WIDTH) * to_unsigned(131072, WIDTH));
        assert(output_lo = std_logic_vector(temp(WIDTH-1 downto 0))) 
			report "Test 4 output_lo wrong" severity warning;
		assert(output_hi = std_logic_vector(temp(WIDTH*2-1 downto WIDTH))) 
			report "Test 4 ouptut_hi wrong" severity warning;
			
        -- 0x0000FFFF and 0xFFFF1234
        OPsel    <= "00100";
        input1 <= x"0000FFFF";
        input2 <= x"FFFF1234";
        wait for 40 ns;
        assert(output_lo = x"00001234") 
			report "Test 5 output_lo wrong" severity warning;
		assert(output_hi = std_logic_vector(to_unsigned(0, output_hi'length))) 
			report "Test 5 ouptut_hi wrong" severity warning;
			
        -- shift right logical 0xF by 4
        OPsel    <= "00111";
		sft_amt <= "00100";
        input1 <= x"0000000F";
        input2 <= x"000000FF";
        wait for 40 ns;
        assert(output_lo = std_logic_vector(to_unsigned(0, output_lo'length))) 
			report "Test 6 output_lo wrong" severity warning;
		assert(output_hi = std_logic_vector(to_unsigned(0, output_hi'length))) 
			report "Test 6 ouptut_hi wrong" severity warning;
			
        -- shift right arithmetic 0xF0000008 by 1
        OPsel    <= "01000";
		sft_amt <= "00001";
        input1 <= x"F0000008";
        input2 <= x"000000FF";
        wait for 40 ns;
        assert(output_lo = x"F8000004") 
			report "Test 7 output_lo wrong" severity warning;
		assert(output_hi = std_logic_vector(to_signed(-1, output_hi'length))) 
			report "Test 7 ouptut_hi wrong" severity warning;

        -- shift right arithmetic 0x8 by 1
        OPsel    <= "01000";
		sft_amt <= "00001";
        input1 <= x"00000008";
        input2 <= x"000000FF";
        wait for 40 ns;
        assert(output_lo = x"00000004") 
			report "Test 8 output_lo wrong" severity warning;
		assert(output_hi = std_logic_vector(to_unsigned(0, output_hi'length))) 
			report "Test 8 ouptut_hi wrong" severity warning;

		
		-- set on less than 10 < 15
        OPsel    <= "01100";
        input1 <= std_logic_vector(to_unsigned(10, input1'length));
        input2 <= std_logic_vector(to_unsigned(15, input2'length));
        wait for 40 ns;
        assert(output_lo = std_logic_vector(to_unsigned(1, output_lo'length))) 
			report "Test 9 output_lo wrong" severity warning;
		assert(output_hi = std_logic_vector(to_unsigned(0, output_hi'length))) 
			report "Test 9 ouptut_hi wrong" severity warning;
		
		-- set on less than 15 < 10
        OPsel    <= "01100";
        input1 <= std_logic_vector(to_unsigned(15, input1'length));
        input2 <= std_logic_vector(to_unsigned(10, input2'length));
        wait for 40 ns;
        assert(output_lo = std_logic_vector(to_unsigned(0, output_lo'length))) 
			report "Test 10 output_lo wrong" severity warning;
		assert(output_hi = std_logic_vector(to_unsigned(0, output_hi'length))) 
			report "Test 10 ouptut_hi wrong" severity warning;

		-- Don't take branch 5 <= 0
        OPsel    <= "01110";
        input1 <= std_logic_vector(to_unsigned(5, input1'length));
        input2 <= std_logic_vector(to_unsigned(0, input2'length));
        wait for 40 ns;
        assert(output_lo = std_logic_vector(to_unsigned(0, output_lo'length))) 
			report "Test 11 output_lo wrong" severity warning;
		assert(output_hi = std_logic_vector(to_unsigned(0, output_hi'length))) 
			report "Test 11 ouptut_hi wrong" severity warning;
		assert(branch = '0') report "Test 11 branch wrong" severity warning;
		
		-- Take branch 5 > 0
        OPsel    <= "01111";
        input1 <= std_logic_vector(to_unsigned(5, input1'length));
        input2 <= std_logic_vector(to_unsigned(0, input2'length));
        wait for 40 ns;
        assert(output_lo = std_logic_vector(to_unsigned(1, output_lo'length))) 
			report "Test 12 output_lo wrong" severity warning;
		assert(output_hi = std_logic_vector(to_unsigned(0, output_hi'length))) 
			report "Test 12 ouptut_hi wrong" severity warning;
		assert(branch = '1') report "Test 12 branch wrong" severity warning;

	report("Sim complete!");
	wait;
	end process;

end alu_tb;