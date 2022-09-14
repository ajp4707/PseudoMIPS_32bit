library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory_tb is
end memory_tb;

architecture memory_tb of memory_tb is
	component memory
		port(
			rst : in std_logic;
			clk : in std_logic;
			mem_out : out std_logic_vector(31 downto 0);
			addr : in std_logic_vector(31 downto 0);
			data_in : in std_logic_vector(31 downto 0);
			
			--control signals
			wr_en : in std_logic;
			-- don't need memread really
			
			--peripheral interface
			outport : out std_logic_vector(31 downto 0);
			inport1 : in std_logic_vector(31 downto 0);
			inport0 : in std_logic_vector(31 downto 0)
		);
	end component;

    signal clkEn  : std_logic                          := '1';
    signal clk    : std_logic                          := '0';
    signal rst    : std_logic                          := '1';
	
	signal mem_out : std_logic_vector(31 downto 0);
	signal addr : std_logic_vector(31 downto 0);
	signal data_in : std_logic_vector(31 downto 0);
	
	--control signals
	signal wr_en : std_logic;
	-- don't need memread really
		
	--peripheral interface
	signal outport : std_logic_vector(31 downto 0);
	signal inport1 : std_logic_vector(31 downto 0);
	signal inport0 : std_logic_vector(31 downto 0);
	
begin	-- TB
	UUT : memory
		generic map (WIDTH => WIDTH)
		port map(
			rst => rst,
			clk => clk,
			mem_out => mem_out,
			addr => addr,
			data_in => data_in,
			wr_en => wr_en,
			outport => outport,
			inport1 => inport1,
			inport0 => inport0
		);
		
	clk <= not clk and clkEn after 20 ns;
		
	process
	begin
		clkEn <= '1';
		rst <= '1';
		wr_en <= '0';
		addr <= (others => '0');
		data_in <= (others => '0');
		inport1 <= (others => '0');
		inport0 <= (others => '0');
		
		
		for i in 0 to 3 loop 
			wait until clk'event and clk = '1';
        end loop;  -- i
		
		rst <= '0';
		
		wait until clk'event and clk = '1';
		
		-- write 0x0a0a0a0a to 0x0
		data_in <= x"0A0A0A0A";
        addr <= x"00000000";
		wr_en <= '1';
        wait until clk'event and clk = '1';

		-- write 0xF0F0F0F0 to 0x04
		data_in <= x"F0F0F0F0";
        addr <= x"00000004";
		wr_en <= '1';
        wait until clk'event and clk = '1';
		
		--read address 0x0
		wr_en <= '0';
		data_in <= x"00000000";
		addr <= x"00000000";
		wait until clk'event and clk = '1';
		wait for 1 ns;

		assert(mem_out = x"0A0A0A0A") 
			report "Wrong data from 0x00" severity warning;

		
		--read address 0x01
		addr <= x"00000001";
						wait until clk'event and clk = '1';
						wait for 1 ns;

		assert(mem_out = x"0A0A0A0A") 
			report "Wrong data from 0x01" severity warning;

			
		--read address 0x04
		addr <= x"00000004";
						wait until clk'event and clk = '1';
						wait for 1 ns;

		assert(mem_out = x"F0F0F0F0") 
			report "Wrong data from 0x04" severity warning;

			
		--read address 0x05
		addr <= x"00000005";
							wait until clk'event and clk = '1';
							wait for 1 ns;

		assert(mem_out = x"F0F0F0F0") 
			report "Wrong data from 0x05" severity warning;

			
		-- write data to outport
		wr_en <= '1';
		data_in <= x"00001111";
		addr <= x"0000FFFC"; 		--outport
		wait until clk'event and clk = '1';
		
		-- Load data to inport
		-- clear signals
		wr_en <= '0';
		data_in <= x"00000000";
		addr <= x"00000000";
		
		inport0 <= x"00010000";
		inport1 <= x"00000001";
		wait until clk'event and clk = '1';
		
		-- read from inport0
		addr <= x"0000FFF8";
							wait until clk'event and clk = '1';
							wait for 1 ns;

		assert(mem_out = x"00010000") 
			report "Wrong data from inport0" severity warning;

			
		-- read from inport1
		addr <= x"0000FFFC";
							wait until clk'event and clk = '1';
							wait for 1 ns;

		assert(mem_out = x"00000001") 
			report "Wrong data from inport1" severity warning;

		
	clkEn <= '0';	
	report("Sim complete!");
	wait;
	end process;

end memory_tb;