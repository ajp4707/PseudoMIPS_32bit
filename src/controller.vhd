library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controller is
	generic( 
		width: positive := 32
	);
	port(
		clk : in std_logic;
		rst : in std_logic;
		
		Instruction : in std_logic_vector(5 downto 0);  --IR[31..26]
		Special : in std_logic_vector(5 downto 0);      --IR[5..0]
	
		PCWrCond    : out std_logic;
		PCWr        : out std_logic;
		IorD        : out std_logic;
		MemRead		: out std_logic;
		MemWrite    : out std_logic;
		MemToReg    : out std_logic;
		IRWrite     : out std_logic;
		JumpAndLink : out std_logic;
		IsSigned	: out std_logic;
		ALUSrcA		: out std_logic;
		RegWrite    : out std_logic;
		RegDst      : out std_logic;
		
		--busses
		PCSource	: out std_logic_vector(1 downto 0);
		ALU_OP : out std_logic_vector(1 downto 0); --EDIT size subject to change
		ALUSrcB : out std_logic_vector(1 downto 0)
		
	);
end controller;

architecture FSM2 of controller is

type state is ( IR_FETCH, IR_DECODE, 
				LOAD_W, STORE_W,
				MEM_READ, MEM_MDR_READ, MEM_REG_WR,
				MEM_WRITE, 
				R_ALU, R_REG_WR,
				I_ALU, I_REG_WR,
				BRANCH_IF,
				J_ADDR, J_LINK_1, J_LINK_2,
				STALL,
				HALT
				); 
signal state_r : state;
signal next_state_r : state;

begin

-- Assign state -> next_state_r
process(clk, rst)
begin
if(rst = '1') then
	state_r <= IR_FETCH;
elsif(rising_edge(clk)) then
	state_r <= next_state_r;
end if;
end process;


-- Combinational logic to determine the next state. Also controls outputs.
process(state_r, Instruction, Special)
begin
	-- Assign all signals a "default" state
	PCWrCond    <= '0';
	PCWr        <= '0';
	IorD        <= '0';
	MemRead		<= '0';
	MemWrite    <= '0';
	MemToReg    <= '0';
	IRWrite     <= '0';
	JumpAndLink <= '0';
	IsSigned	<= '0';
	ALUSrcA		<= '0';  -- by default, do PC + 4 operation.
	RegWrite    <= '0';
	RegDst      <= '0';  -- 0 for RT (I type), 1 for RD (R type)
	
	--busses
	PCSource	<= "00"; -- PC + 4
	ALU_OP 		<= "00"; --EDIT size subject to change -- PC + 4
	ALUSrcB 	<= "01"; -- PC + 4
	next_state_r <= IR_DECODE;
	
	-- IR_FETCH
	if (state_r = IR_FETCH) then
		MemRead <= '1';
		-- ALUSrcA, ALUSrcB, ALU_OP, and PCSource already default
		-- IorD 0
		IRWrite <= '1';  -- Loads the IR register
		PCWr <= '1';
		next_state_r <= IR_DECODE;
	
	-- IR_DECODE
	elsif (state_r = IR_DECODE) then
		-- RegA and RegB loading happens automatically
		ALU_OP <= "00"; -- calculate potential branch address
		ALUSrcA <= '0';
		ALUSrcB <= "11";
		IsSigned <= '1';
		
		-- Decode next state. 
		
		-- Decode R -types
		if (Instruction = "000000") then
			next_state_r <= R_ALU;
			
		-- Decode each of 7 I - types by hand
		elsif ( Instruction = "001001" or
				Instruction = "010000" or
				Instruction = "001100" or
				Instruction = "001101" or
				Instruction = "001110" or
				Instruction = "001010" or
				Instruction = "001011") then
			next_state_r <= I_ALU;
			
		-- Decode Branch type
		elsif ( Instruction = "000100" or
				Instruction = "000101" or
				Instruction = "000110" or
				Instruction = "000111" or
				Instruction = "000001") then
			next_state_r <= BRANCH_IF;
		
		-- Decode Jump Address
		elsif( Instruction = "000010") then
			next_state_r <= J_ADDR;
		
		--Decode Jump Link
		elsif( Instruction = "000011") then
			next_state_r <= J_LINK_1;
			
		-- Decode load word
		elsif( Instruction = "100011" ) then
			next_state_r <= LOAD_W;
			
		-- Decode store word
		elsif( Instruction = "101011" ) then
			next_state_r <= STORE_W;
			
		-- Decode HALT
		elsif( Instruction = "111111" ) then
			next_state_r <= HALT;
		end if;
	-- ---------- END OF IR_DECODE

	-- STALL
	elsif (state_r = STALL) then
		next_state_r <= IR_FETCH;

	-- R_ALU (including Move Hi and Move Lo)
	elsif (state_r = R_ALU) then
		ALU_OP <= "01"; -- Configure ALU to do a IR[5..0] R type
		ALUSrcA <= '1';
		ALuSrcB <= "00";
		next_state_r <= R_REG_WR;		
		
	-- R_REG_WR
	elsif (state_r = R_REG_WR) then
		ALU_OP <= "01";	-- REWRITE ALU controller to decode IRs so that it knows ALU_OUT_HI_LO
		RegDst <= '1';
		ALUSrcA <= '1';
		ALuSrcB <= "00";
		-- where to write it to? Consider if J_R
		if (Special = "001000") then  -- if it's the J R
			PCSource <= "01";		  -- load the ALU output into the PC counter
			PCWr <= '1';
		else
			RegWrite <= '1';
		end if;
		next_state_r <= STALL;

	-- I_ALU
	elsif (state_r = I_ALU) then
		ALU_OP <= "10"; -- Configure ALU I type
		ALUSrcA <= '1';
		ALUSrcB <= "10";
		if ( Instruction = "001001" or 
			Instruction = "010000" or 
			Instruction = "001010" or 
			Instruction = "001011") then
			IsSigned <= '1';
		end if;
		next_state_r <= I_REG_WR;
		
	-- I_REG_WR
	elsif (state_r = I_REG_WR) then
		ALU_OP <= "10"; -- Configure ALU I type
		RegDst <= '0';
		RegWrite <= '1';
		next_state_r <= IR_FETCH;
	
	-- BRANCH_IF
	elsif (state_r = BRANCH_IF) then
		ALUSrcA <= '1';
		ALUSrcB <= "00";
		ALU_OP <= "11";		--ALU needs to be evaluating the branch condition here
		PCWrCond <= '1';
		PCSource <= "01";
		next_state_r <= STALL;
		
	-- J_ADDR
	elsif (state_r = J_ADDR) then
		PCWr <= '1';
		PCSource <= "10";
		next_state_r <= STALL;
		
	-- J_LINK_1
	elsif (state_r = J_LINK_1) then
		--write to the PC
		PCWr <= '1';
		PCSource <= "10";
		--meanwhile, compute PC + 4 for the link
		RegWrite <= '1';
		JumpAndLink <= '1';
		
		next_state_r <= STALL;
		
	-- J_LINK_2
--	elsif (state_r = J_LINK_2) then
--		ALU_OP <= "00";
--		RegDst <= '0'; -- irrelevant
--		-- write the PC+4 sum to reg 31
--		RegWrite <= '1';
--		JumpAndLink <= '1';  -- forces the regfile to write to 32
--		next_state_r <= STALL;
		
	-- LOAD_W
	elsif (state_r = LOAD_W) then
		ALUSrcA <= '1';
		ALUSrcB <= "10";
		ALU_OP <= "00";
		IsSigned <= '0';
		next_state_r <= MEM_READ;
	
	-- MEM_READ
	elsif(state_r = MEM_READ) then
		--MemRead <= '1';
		IorD <= '1';
		next_state_r <= MEM_MDR_READ;
		
	-- MEM_MDR_READ
	elsif(state_r = MEM_MDR_READ) then
		IorD <= '1';
		MemRead <= '1';
		next_state_r <= MEM_REG_WR;
	
	--MEM_REG_WR
	elsif(state_r = MEM_REG_WR) then
		RegDst <= '0';  --load into rt
		RegWrite <= '1';
		MemToReg <= '1';
		next_state_r <= STALL;
	
	-- STORE_W
	elsif (state_r = STORE_W) then
		IorD <= '1';
		ALUSrcA <= '1';
		ALUSrcB <= "10";
		ALU_OP <= "00";
		IsSigned <= '0';
		next_state_r <= MEM_WRITE;
		
	-- MEM_WRITE
	elsif(state_r = MEM_WRITE) then
		MemWrite <= '1';
		IorD <= '1';
		ALUSrcA <= '1';
		ALUSrcB <= "10";
		ALU_OP <= "00";
		IsSigned <= '0';
		next_state_r <= STALL;
		
	-- HALT
	elsif(state_r = HALT) then
		next_state_r <= HALT;
	end if;
end process;

end FSM2;

