library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory is 
	port(
		rst : in std_logic;
		clk : in std_logic;
		mem_out : out std_logic_vector(31 downto 0);
		addr : in std_logic_vector(31 downto 0);
		data_in : in std_logic_vector(31 downto 0);
		inport_en : in std_logic_vector(1 downto 0);
		
		
		--control signals
		wr_en : in std_logic;
		-- don't need memread really
		
		--peripheral interface
		outport : out std_logic_vector(31 downto 0);
		inport1 : in std_logic_vector(31 downto 0);
		inport0 : in std_logic_vector(31 downto 0)
	);
end memory;

architecture BHV of memory is

	component RAMv2
		PORT(
				address		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
				clock		: IN STD_LOGIC  := '1';
				data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
				wren		: IN STD_LOGIC ;
				q		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
			);
	end component;
	
	signal inport1_r, inport0_r, outport_r : std_logic_vector(31 downto 0);
	signal RAM_wren : std_logic;
	signal OUTP_wren : std_logic;
	signal RAM_out : std_logic_vector(31 downto 0);
	signal sel : std_logic_vector(1 downto 0); --11 is none. 10 is RAM, 01 is ip1, 00 is ip2
	
begin
	myRAM : RAMv2
	port map(
		address => addr(9 downto 2),
		clock => clk,
		data => data_in,
		wren => RAM_wren,
		q => RAM_out
	);


	process(clk, rst)
	begin
		if (rst = '1') then
			outport_r <= (others => '0');
			
			sel <= "11"; --None
			if (to_integer(unsigned(addr)) < 1024) then -- RAM addresses
				sel <= "10"; -- select RAM
			elsif (addr = x"0000FFFC") then -- Outport address. Inport 1
				sel <= "01"; -- select Inport1
			elsif (addr = x"0000FFF8") then -- Inport 0
				sel <= "00"; -- select Inport 0
			end if;
		elsif (rising_edge(clk)) then
			if (inport_en(1) = '1') then
				inport1_r <= inport1;
			elsif (inport_en(0) = '1') then
				inport0_r <= inport0;
			end if;
			
			if (OUTP_wren = '1') then
				outport_r <= data_in;
			end if;
			
			sel <= "11"; --None
			if (to_integer(unsigned(addr)) < 1024) then -- RAM addresses
				sel <= "10"; -- select RAM
			elsif (addr = x"0000FFFC") then -- Outport address. Inport 1
				sel <= "01"; -- select Inport1
			elsif (addr = x"0000FFF8") then -- Inport 0
				sel <= "00"; -- select Inport 0
			end if;
			
		end if;
	end process;
	
	--concurrent logic to determine enables. Enables vary based on adress and wr_en
	process(addr, wr_en)
	begin
		RAM_wren <= '0';
		OUTP_wren <= '0';
		if (to_integer(unsigned(addr)) < 1024 and wr_en = '1') then -- RAM addresses
			RAM_wren <= '1';
		elsif (addr = x"0000FFFC" and wr_en = '1') then -- Outport address. Inport 1
			OUTP_wren <= '1';
		end if;
	end process;
--	--Combinational logic to determine enables. Outputs: sel, RAM_wren
--	process(wr_en, addr, rst)
--	begin
--		sel <= "11"; --None
--		RAM_wren <= '0';
--		OUTP_wren <= '0';
--		if (to_integer(unsigned(addr)) < 1024) then -- RAM addresses
--			sel <= "10"; -- select RAM
--			if (wr_en = '1') then
--				RAM_wren <= '1';
--			end if;
--		elsif (addr = x"0000FFFC") then -- Outport address. Inport 1
--			sel <= "01"; -- select Inport1
--			if (wr_en = '1') then
--				OUTP_wren <= '1';
--			end if;
--		elsif (addr = x"0000FFF8") then -- Inport 0
--			sel <= "00"; -- select Inport 0
--		end if;
--	end process;

	-- concurrent assignments to determine the write enables
	--RAM_wren <= '1' when (sel="10") else '0';
	
	-- concurrent assignments. assignment of mem_out
	with sel select mem_out <=
		inport0_r when "00",
		inport1_r when "01",
		RAM_out when "10",
		(others => '0') when others;

	outport <= outport_r;

end BHV;