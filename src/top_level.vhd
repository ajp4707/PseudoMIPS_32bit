library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ieee;
use ieee.std_logic_1164.all;

entity top_level is
    port (
		clk50MHz : in  std_logic;
        switch  : in  std_logic_vector(9 downto 0);
        button  : in  std_logic_vector(1 downto 0);
        led0    : out std_logic_vector(6 downto 0);
        led0_dp : out std_logic;
        led1    : out std_logic_vector(6 downto 0);
        led1_dp : out std_logic;
        led2    : out std_logic_vector(6 downto 0);
        led2_dp : out std_logic;
        led3    : out std_logic_vector(6 downto 0);
        led3_dp : out std_logic;
        led4    : out std_logic_vector(6 downto 0);
        led4_dp : out std_logic;
        led5    : out std_logic_vector(6 downto 0);
        led5_dp : out std_logic
        );
end top_level;


architecture STR of top_level is
	signal  rst 		:  std_logic;
	signal	PCWrCond    :  std_logic;
	signal	PCWr        :  std_logic;
	signal	IorD        :  std_logic;
	signal	MemRead		:  std_logic;
	signal	MemWrite    :  std_logic;
	signal	MemToReg    :  std_logic;
	signal	IRWrite     :  std_logic;
	signal	JumpAndLink :  std_logic;
	signal	IsSigned	:  std_logic;
	signal	ALUSrcA		:  std_logic;
	signal	RegWrite    :  std_logic;
	signal	RegDst      :  std_logic;
	signal	PCSource	:  std_logic_vector(1 downto 0);
	signal	ALU_OP 		:  std_logic_vector(1 downto 0); --EDIT size subject to change
	signal	ALUSrcB 	:  std_logic_vector(1 downto 0);
	signal	LEDS 		:  std_logic_vector(31 downto 0);
	signal	IR 			:  std_logic_vector(31 downto 0);



begin
	rst <= not button(0);

    -- Map output onto the LEDs
    U_LED5 : entity work.decoder7seg port map (
        input  => LEDS(23 downto 20),
        output => led5);

    U_LED4 : entity work.decoder7seg port map (
        input  => LEDS(19 downto 16),
        output => led4);

    -- all other LEDs should display 0
    U_LED3 : entity work.decoder7seg port map (
        input  => LEDS(15 downto 12),
        output => led3);

    U_LED2 : entity work.decoder7seg port map (
        input  => LEDS(11 downto 8),
        output => led2);
    
    U_LED1 : entity work.decoder7seg port map (
        input  => LEDS(7 downto 4),
        output => led1);

    U_LED0 : entity work.decoder7seg port map (
        input  => LEDS(3 downto 0),
        output => led0);
		
	led5_dp <= '1';
    led4_dp <= '1';
    led3_dp <= '1';
    led2_dp <= '1';
    led1_dp <= '1';
    led0_dp <= '1';


U_datap : entity work.datapath
	generic map(width => 32)
	port map(
		clk => clk50MHz,
	
		PCWrCond    => PCWrCond   , 
		PCWr        => PCWr       , 
		IorD        => IorD       , 
		MemRead		=> MemRead	,	
		MemWrite    => MemWrite   , 
		MemToReg    => MemToReg   , 
		IRWrite     => IRWrite    , 
		JumpAndLink => JumpAndLink, 
		IsSigned	=> IsSigned	 ,
		ALUSrcA		=> ALUSrcA	,	
		RegWrite    => RegWrite   , 
		RegDst      => RegDst     , 
		
		--busses
		PCSource	=> PCSource,
		ALU_OP 		=> ALU_OP,
		ALUSrcB 	=> ALUSrcB,
		
		button => button,
		switch => switch,
		LEDS => LEDs,
		IR => IR
		);
	
U_controller : entity work.controller
	generic map(width => 32)
	port map(
		clk => clk50MHz,
		rst => rst,
		
		Instruction => IR(31 downto 26),
		Special => IR(5 downto 0),      --IR[5..0]
	
		PCWrCond    => PCWrCond   , 
		PCWr        => PCWr       , 
		IorD        => IorD       , 
		MemRead		=> MemRead		,
		MemWrite    => MemWrite   , 
		MemToReg    => MemToReg   , 
		IRWrite     => IRWrite    , 
		JumpAndLink => JumpAndLink, 
		IsSigned	=> IsSigned	  ,
		ALUSrcA		=> ALUSrcA		,
		RegWrite    => RegWrite   , 
		RegDst      => RegDst     , 
		
		--busses
		PCSource 	=> PCSource,
		ALU_OP 		=> ALU_OP,
		ALUSrcB		=> ALUSrcB
	);

end STR;