library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity datapath is
	generic( 
		width: positive := 32
	);
	port(
		clk : in std_logic;
		
		PCWrCond    : in std_logic;
		PCWr        : in std_logic;
		IorD        : in std_logic;
		MemRead		: in std_logic;
		MemWrite    : in std_logic;
		MemToReg    : in std_logic;
		IRWrite     : in std_logic;
		JumpAndLink : in std_logic;
		IsSigned	: in std_logic;
		ALUSrcA		: in std_logic;
		RegWrite    : in std_logic;
		RegDst      : in std_logic;
		
		--busses
		PCSource	: in std_logic_vector(1 downto 0);
		ALU_OP : in std_logic_vector(1 downto 0); --EDIT size subject to change
		ALUSrcB : in std_logic_vector(1 downto 0);
		
		button : in std_logic_vector(1 downto 0);
		switch : in std_logic_vector(9 downto 0);
		LEDS : out std_logic_vector(31 downto 0);
		IR : out std_logic_vector(WIDTH-1 downto 0)
		
	);
end datapath;

architecture STR of datapath is

signal rst : std_logic;

-- mem block signals
signal mem_out, mem_data_in, mem_addr : std_logic_vector(WIDTH-1 downto 0);

signal IR_out : std_logic_vector(WIDTH-1 downto 0);

signal MDR_out : std_logic_vector(WIDTH-1 downto 0);

--Reg file signals
signal wr_addr : std_logic_vector(4 downto 0);
signal wr_data, wr_data_2, rega_out, regb_out : std_logic_vector(WIDTH-1 downto 0);

--ALU ctrl signals
signal OPsel: std_logic_vector(4 downto 0);
signal ALU_HI_en, ALU_LO_en : std_logic;
signal ALU_LO_HI_sel : std_logic_vector(1 downto 0);

-- ALU signals
signal alu_in1, alu_in2, alu_out_lo, alu_out_hi : std_logic_vector(WIDTH-1 downto 0);

-- PC signals
signal pc_in, pc_out : std_logic_vector(WIDTH-1 downto 0);

--ALU Reg signals
signal alu_out_r_out, alu_hi_r_out, alu_lo_r_out : std_logic_vector(WIDTH-1 downto 0);

-- Mux to Mux signals
signal alu_out_wr_mux_out : std_logic_vector(WIDTH-1 downto 0);

--sign extend signal
signal sig_ex_out : std_logic_vector(WIDTH-1 downto 0);

-- helper signals
signal pc_out_31_28 : std_logic_vector(3 downto 0);
signal IR_out_25_0 : std_logic_vector(25 downto 0);
signal BranchTaken : std_logic;
signal pc_en : std_logic;

signal inport_en : std_logic_vector(1 downto 0);

begin
mem_data_in <= regb_out;
IR <= IR_out;
pc_en <= PCWr or (PCWrCond and BranchTaken);

rst <= not button(0);  -- button 0 is active low button reset
inport_en(0) <= not button(1) and not switch(9);
inport_en(1) <= not button(1) and switch(9);

-- instantiate all components
-- registers and register files
U_IR : entity work.reg
	generic map( WIDTH => width )
	port map(
		input => mem_out,
		en => IRWrite,
		clk => clk,
		rst => rst,
		output => IR_out
	);
	
mem : entity work.memory
	port map(
		rst => rst,
		clk => clk,
		mem_out => mem_out,
		addr => mem_addr,
		data_in => mem_data_in,
		
		
		--control signals
		wr_en => MemWrite,
		-- don't need memread really
		
		--peripheral interface
		outport => LEDS,
		inport1(31 downto 9) => (others => '0'),
		inport1(8 downto 0) => switch(8 downto 0),
		inport0(31 downto 9) => (others => '0'),
		inport0(8 downto 0) => switch(8 downto 0),
		-- button 1 controls the input en
		inport_en => inport_en

	);
	
MDR : entity work.reg
	generic map( WIDTH => width )
	port map(
		input => mem_out,
		en => MemRead,     --using MemRead as MDR enable
		clk => clk,
		rst => rst,
		output => MDR_out
	);
	
regf : entity work.register_file
	port map(
		JumpAndLink => JumpAndLink,
		clk => clk,
		rst => rst,
		rd_addr0 => IR_out(25 downto 21),
		rd_addr1 => IR_out(20 downto 16),
		wr_addr  => wr_addr,
		wr_en => RegWrite,
		wr_data => wr_data_2,
		rd_data0 => rega_out,
		rd_data1 => regb_out
	);

aluct : entity work.alu_ctrl
	port map(
		ALU_OP => ALU_OP,
		func_OP => IR_out(5 downto 0),
		OPsel => OPsel ,

		HI_en => ALU_HI_en,
		LO_en => ALU_LO_en,
		ALU_LO_HI_sel => ALU_LO_HI_sel,
		
		IR_20_16 => IR_out(20 downto 16),
		IR_OP => IR_out(31 downto 26)
	);
	
alum : entity work.alu_ns
	generic map( WIDTH => width)
	port map (
		input1 => alu_in1,
		input2 => alu_in2,
		OPsel => OPsel,
		sft_amt => IR_out(10 downto 6),
		
		output_lo => alu_out_lo,
		output_hi => alu_out_hi,
		branch => BranchTaken
	);
	
pc : entity work.reg
	generic map( WIDTH => width )
	port map(
		input => pc_in,
		en => pc_en,
		clk => clk,
		rst => rst,
		output => pc_out
	);
	
alu_out_r : entity work.reg
	generic map( WIDTH => width )
	port map(
		input => alu_out_lo,
		en => '1',
		clk => clk,
		rst => rst,
		output => alu_out_r_out
	);
	
alu_lo_r : entity work.reg
	generic map( WIDTH => width )
	port map(
		input => alu_out_lo,
		en => ALU_LO_en,
		clk => clk,
		rst => rst,
		output => alu_lo_r_out
	);
	
alu_hi_r : entity work.reg
	generic map( WIDTH => width )
	port map(
		input => alu_out_hi,
		en => ALU_HI_en,
		clk => clk,
		rst => rst,
		output => alu_hi_r_out
	);
	
-- Here come the MUXs
mem_mux : entity work.mux2x1
	generic map( WIDTH => width)
	port map(
		in1 => pc_out,
		in2 => alu_out_r_out,
		sel => IorD,
		output => mem_addr
	);
	
wr_reg_mux : entity work.mux2x1
	generic map( WIDTH => 5)
	port map(
		in1 => IR_out(20 downto 16),
		in2 => IR_out(15 downto 11),
		sel => RegDst,
		output => wr_addr
	);
	
wr_data_mux : entity work.mux2x1
	generic map( WIDTH => width)
	port map(
		in1 => alu_out_wr_mux_out,
		in2 => MDR_out,
		sel => MemToReg,
		output => wr_data
	);
	
alu_in1_mux : entity work.mux2x1
	generic map( WIDTH => width)
	port map(
		in1 => pc_out,
		in2 => rega_out,
		sel => ALUSrcA,
		output => alu_in1
	);
	
sig_ex : entity work.sign_ex	
	generic map (WIDTH_IN => 16)
	port map(
		input => IR_out(15 downto 0),
		output => sig_ex_out,
		isSigned => isSigned
	);
	
alu_in2_mux : entity work.mux4x1
	generic map( WIDTH => width)
	port map(
		in0 => regb_out,
		in1 => std_logic_vector( to_unsigned(4, 32)),
		in2 => sig_ex_out,
		in3(31 downto 2) => sig_ex_out(29 downto 0),
		in3(1 downto 0) => "00",
		sel => ALUSrcB,
		output => alu_in2
	);
	
alu_out_wr_mux : entity work.mux4x1
	generic map( WIDTH => width)
	port map(
		in0 => alu_out_r_out,
		in1 => alu_lo_r_out,
		in2 => alu_hi_r_out,
		in3 => (others => '0'),
		sel => ALU_LO_HI_sel,
		output => alu_out_wr_mux_out
	);
	
pc_mux : entity work.mux4x1
	generic map( WIDTH => width)
	port map(
		in0 => alu_out_lo,
		in1 => alu_out_r_out,
		in2(31 downto 28) => pc_out(31 downto 28),
		in2(27 downto 2) => IR_out(25 downto 0),
		in2(1 downto 0) => "00",
		in3 => (others => '0'),
		sel => PCSource,
		output => pc_in
	);
	
jal_mux : entity work.mux2x1
	generic map( WIDTH => width)
	port map(
		in1 => wr_data,
		in2 => pc_out,
		sel => JumpAndLink,
		output => wr_data_2
	);
end STR;