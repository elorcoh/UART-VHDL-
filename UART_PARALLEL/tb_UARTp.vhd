library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all ;
entity tb_UARTp is
  -- Test bench of UART receiver
end tb_UARTp ;
architecture arc_tb_UARTp of tb_UARTp is
   component myuart
	PORT
	(
		resetN :  IN  STD_LOGIC;
		clk :  IN  STD_LOGIC;
		write_din :  IN  STD_LOGIC;
		rx :  IN  STD_LOGIC;
		read_dout :  IN  STD_LOGIC;
		din :  IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
		tx :  OUT  STD_LOGIC;
		tx_ready :  OUT  STD_LOGIC;
		rx_ready :  OUT  STD_LOGIC;
		dout_new :  OUT  STD_LOGIC;
		dout_ready :  OUT  STD_LOGIC;
		dout :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0)
	);
   end component ;
		 signal resetN         : std_logic                       ;
		 signal clk            : std_logic                       ;
		 signal write_din      : std_logic                       ;
         signal rx             : std_logic                       ;
         signal read_dout      : std_logic                       ;
		 signal din            : std_logic_vector (7 downto 0)   ;
		 signal tx             : std_logic                       ;
		 signal tx_ready       : std_logic                       ;
         signal rx_ready       : std_logic                       ;
         signal dout           : std_logic_vector(7 downto 0)    ;
         signal dout_new       : std_logic                       ;
         signal dout_ready     : std_logic                      ;
		 constant bit_time : time := 8680 ns ;   
 begin 
   eut: myuart
      port map ( resetN     => resetN      ,
                 clk        => clk         ,
				 write_din  => write_din   ,
                 rx         => rx          ,
                 read_dout  => read_dout   ,
				 din        => din         ,
				 tx         =>  tx          ,
				 tx_ready   => tx_ready    ,
                 rx_ready   => rx_ready    ,
                 dout       => dout        ,
                 dout_new   => dout_new    ,
                 dout_ready => dout_ready  );
 -- Clock process (50 MHz)
   process
   begin
      clk <= '0' ;  wait for 20 ns ;
      clk <= '1' ;  wait for 20 ns ;
   end process ;   
   -- Active low reset pulse
   resetN <= '0' , '1' after 40 ns ;
   din <= dout  ;
   write_din <= dout_new ;
   read_dout <= '0' ;
   -- Transmission activation & test vectors process
 process
   constant baud : real:= 115200.0;
   constant dt   : time:= 1 sec * (1.0/baud);
   variable d : std_logic_vector(7 downto 0) ;
   --variable d    : std_logic_vector(7 downto 0);   
begin
read_dout <= '0' ;
	d := "11001100" ;
	rx <= '1' ; wait for dt ;
	rx <= '0' ; wait for dt ;
	for i in 0 to 7 loop 
		rx <= d(i) ; wait for dt ;
	end loop ;
	rx <= '1' ; wait for dt ;
	wait for 100 us ;
	----------------------------------------
	d := "00110101" ; 
	rx <= '0' ; wait for dt ;
	for i in 0 to 7 loop 
		rx <= d(i) ; wait for dt ;
	end loop ;
	rx <= '1' ; wait for dt ;
	wait for 100 us ;
	----------------------------------------
	d := "11110000" ; 
	rx <= '0' ; wait for dt ;
	for i in 0 to 7 loop 
		rx <= d(i) ; wait for dt ;
	end loop ;
	rx <= '1' ; wait for dt ;
	wait for 50 us ;
	----------------------------------------
	rx <= '1' ; wait for dt ;
	rx <= '0' ; wait for dt/4 ;
	rx <= '1' ; wait for dt ;
	wait for 100 us ;
	--------------------------------------
	assert false report "end of test vectors " severity note ;
	wait ;
   end process ;
end arc_tb_UARTp ;