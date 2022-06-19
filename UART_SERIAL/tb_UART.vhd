library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all ;
entity tb_UART is
  -- Test bench of UART receiver
end tb_UART ;
architecture arc_tb_UART of tb_UART is
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
   rx <= tx  ;
   read_dout <= '0' ;
   -- Transmission activation & test vectors process
 process
   constant baud : real:= 115200.0;
   constant dt   : time:= 1 sec * (1.0/baud);
   variable data_send : std_logic_vector(7 downto 0) ;
   --variable d    : std_logic_vector(7 downto 0);   
begin
     -- wait for end of async reset
      din <= "XXXXXXXX" ; write_din <= '0' ;  
      wait for 40 ns ;
      -----------------------------------------  vector 1    
      report "sending the H character (01001000b=48h=72d)" ; 
      data_send := "00000000" + character'pos('H') ; 
      din <= data_send ; write_din <= '1' ;  
      wait for 40 ns ;
      din <= "XXXXXXXX" ;  write_din <= '0' ;  
      wait for 11 * bit_time ;
      assert dout = data_send report "bad transmission #1" severity error ;
      -----------------------------------------  vector 2     
      report "sending the i character (01101001b=69h=105d)" ; 
      data_send := "00000000" + character'pos('i') ;  
      din <= data_send ; write_din <= '1' ;  
      wait for 40 ns ;
      din <= "XXXXXXXX" ;  write_din <= '0' ;  
      wait for 11 * bit_time ;
      assert dout = data_send report "bad transmission #2" severity error ;      
      -----------------------------------------  vector 3      
      report "sending the CR character (00001101=0Dh=13d)" ; 
      data_send := "00000000" + character'pos(CR) ;  
      din <= data_send ; write_din <= '1' ;  
      wait for 40 ns ;
      din <= "XXXXXXXX" ;  write_din <= '0' ;  
      wait for 11 * bit_time ;
      assert dout = data_send report "bad transmission #3" severity error ;          
      -----------------------------------------  vector 4      
      report "sending the LF character (00001010=0Ah=10d)" ; 
      data_send := "00000000" + character'pos(LF) ;  
      din <= data_send ; write_din <= '1' ;  
      wait for 40 ns ;
      din <= "XXXXXXXX" ;  write_din <= '0' ;  
      wait for 11 * bit_time ;
      assert dout = data_send report "bad transmission #4" severity error ;
      -----------------------------------------      
      report "end of test vectors" ;
      wait ;
end process ;
end arc_tb_UART ;