package uart_constants is

   constant clockfreq  : integer := 25000000 ;
   constant baud       : integer := 115200   ;
   constant t1_count   : integer := clockfreq / baud ; -- 217
   constant t2_count   : integer := t1_count / 2     ; -- 108

end uart_constants ;

-------------------------------------------------------------------------------------

-------------------------------------------------------
-- UART receiver (C) VHDL workshop Dan Iton --
-------------------------------------------------------
use work.uart_constants.all ;
library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all ;
entity receiver is
   port ( resetN    : in     std_logic                    ;
          clk       : in     std_logic                    ;
          rx        : in std_logic                       ;
		  read_dout : in std_logic                       ;
          rx_ready   : out std_logic                        ;
		  dout       : out std_logic_vector (7 downto 0)     ;
		  dout_new   : out std_logic                         ;
		  dout_ready,qbar : out std_logic                      );
end receiver ;

architecture arc_receiver of receiver is
   -- timer            floor(log2(t1_count)) downto 0
   signal tcount : std_logic_vector(8 downto 0) ;
   signal te     : std_logic ; -- Timer_Enable/!reset
   signal t1     : std_logic ; -- end of one time slot
   signal t2     : std_logic ; -- end of one time slot

   -- data counter
   signal dcount     : std_logic_vector(2 downto 0) ; -- data counter
   signal ena_dcount : std_logic                    ; -- enable this counter
   signal clr_dcount : std_logic                    ; -- clear this counter
   signal eoc        : std_logic                    ; -- end of count (7)

   -- shift register
   signal rxs      : std_logic ;
   signal dint       : std_logic_vector (7 downto 0) ;
   signal ena_shift : std_logic                    ; -- enable shift register
   signal ena_load  : std_logic                    ; -- enable parallel load

   -- output register --
   signal dout_ena : std_logic ; -- enable tx from shift register during data transfer
   
   
  -- state machine
   type state is
   ( idle        ,
     start_wait  ,
     start_chk ,
     data_wait   ,
     break_wait    ,
     data_count ,
     data_chk ,
	 tell_out ,
	 update_out ,
	 stop_chk ,
	 stop_wait);
	 

    signal present_state , next_state : state ;

begin
 -------------------
   -- RX --
   -------------------
process (clk)
begin
	if rising_edge(clk) then
		rxs <= rx ;
	end if;
end process ;
   -------------------
   -- state machine --
   -------------------
process (resetN,clk)
begin
	if resetN = '0' then
		present_state <= idle ;
	elsif rising_edge(clk) then
		present_state <= next_state ;
	end if;
end process ;
--------------------------------
process (present_state,t1,t2,rxs,eoc)
begin
--default output:
	rx_ready <= '0' ;
	next_state <= idle ;
	case present_state is 
	 -------------------
   -- state 1 : idle --
   -------------------
		when idle =>
			rx_ready <= '1';
			clr_dcount <= '1';
			te <= '0' ;
			dout_new <= '0' ;
			ena_dcount <= '0';
			ena_shift <= '0' ;
			dout_ena <= '0' ;
			if rxs = '1' then 
				next_state <= idle;
			elsif rxs = '0' then
				next_state <= start_wait;
			end if;
	 -------------------
   -- state 2: start wait --
   -------------------
		when start_wait =>
			te <= '1' ;
			rx_ready <= '0';
			clr_dcount <= '0';
			dout_new <= '0' ;
			ena_dcount <= '0';
			ena_shift <= '0' ;
			dout_ena <= '0' ;
			if t2 = '1' then 
				next_state <= start_chk ;
			elsif t2 = '0' then
				next_state <= start_wait;
			end if;
	 -------------------
   -- state 3: start chk --
   -------------------
		when start_chk =>
			te <= '0' ;
			rx_ready <= '0';
			clr_dcount <= '0';
			dout_new <= '0' ;
			ena_dcount <= '0';
			ena_shift <= '0' ;
			dout_ena <= '0' ;
			if rxs = '1' then 
				next_state <= idle;
			elsif rxs = '0' then
				next_state <= data_wait;
			end if;
	 -------------------
   -- state 4: data_wait --
   -------------------
		when data_wait =>
			te <= '1';
			ena_dcount <= '0';
			rx_ready <= '0';
			clr_dcount <= '0';
			dout_new <= '0' ;
			ena_shift <= '0' ;
			dout_ena <= '0' ;
			if t1 = '1' then
				next_state <= data_chk ;
			elsif t1 = '0' then	
				next_state <= data_wait;
			end if ;
	 -------------------
   -- state 5: data_chk --
   -------------------
		when data_chk =>
			ena_shift <= '1' ;
			te <= '0' ;
			rx_ready <= '0';
			clr_dcount <= '0';
			dout_new <= '0' ;
			ena_dcount <= '0';
			dout_ena <= '0' ;
			if eoc = '0' then
				next_state <= data_count ;
			elsif eoc = '1' then
				next_state <= stop_wait ;
			end if;
	 -------------------
   -- state 6: stop_wait --
   -------------------
		when stop_wait =>
			te <= '1';
			ena_shift <= '0' ;
			rx_ready <= '0';
			clr_dcount <= '0';
			dout_new <= '0' ;
			ena_dcount <= '0';
			dout_ena <= '0' ;
			if t1 = '1' then
				next_state <= stop_chk ;
			elsif t1 = '0' then	
				next_state <= stop_wait;
			end if ;
	 -------------------
   -- state 7: data_count --
   -------------------
		when data_count =>
			ena_dcount <= '1' ;
			te <= '0' ;
			rx_ready <= '0';
			clr_dcount <= '0';
			dout_ena <= '0' ;
			dout_new <= '0' ;
			ena_shift <= '0' ;
			next_state <= data_wait ;
	
	 -------------------
   -- state 8: stop_chk --
   -------------------
		when stop_chk =>
			te <='0' ;
			rx_ready <= '0';
			clr_dcount <= '0';
			dout_new <= '0' ;
			dout_ena <= '0' ;
			ena_shift <= '0' ;
			ena_dcount <= '0' ;
			if rxs = '1' then 
				next_state <= update_out;
			elsif rxs = '0' then
				next_state <= break_wait;
			end if;
	 -------------------
   -- state 9: update_out --
   -------------------
		when update_out =>
			dout_ena <= '1' ;
			te <='0' ;
			rx_ready <= '0';
			clr_dcount <= '0';
			dout_new <= '0' ;
			ena_shift <= '0' ;
			ena_dcount <= '0' ;
			next_state <= tell_out ;
			
	 -------------------
   -- state 10: break_wait --
   -------------------
		when break_wait =>
			dout_ena <= '0' ;
			te <='0' ;
			rx_ready <= '0';
			clr_dcount <= '0';
			dout_new <= '0' ;
			ena_shift <= '0' ;
			ena_dcount <= '0' ;
			if rxs = '1' then 
				next_state <= idle;
			elsif rxs = '0' then
				next_state <= break_wait;
			end if;
		 -------------------
   -- state 11: tell_out --
   -------------------
		when tell_out =>
			dout_ena <= '0' ;
			te <='0' ;
			rx_ready <= '0';
			clr_dcount <= '0';
			dout_new <= '1' ;
			ena_shift <= '0' ;
			ena_dcount <= '0' ;
			next_state <= idle ;
	 -------------------
   -- state default : --
   -------------------
		when others => next_state <= idle ;
	end case;
end process;
   -----------
   -- timer --
   -----------
process(resetN,clk)
begin
	if resetN = '0' then 
		tcount <= (others => '0');
	elsif rising_edge(clk) then
		if te ='1' then 
			if tcount /= t1_count then 
				tcount <= tcount+1;
			end if;
		else
			tcount <= (others => '0');
		end if;
	end if;
end process;
t1 <= '1' when (t1_count = tcount) else '0';
t2 <= '1' when (tcount = t2_count) else '0';
--------------------------------------------

   ------------------
   -- data counter --
   ------------------
process(resetN,clk)
begin
	if resetN = '0' then 
		dcount <= (others => '0');
	elsif rising_edge(clk) then
		if clr_dcount ='1' then
			dcount <= (others => '0');
		elsif ena_dcount = '1' then
			dcount <= dcount +1 ;
		end if;
	end if;
end process;
eoc <= '1' when (dcount = "111") else '0';
   --------------------
   -- shift register --
   --------------------
process(resetN,clk)
begin 
	if resetN = '0' then
		dint <= (others => '0') ;
	elsif rising_edge(clk) then 
		if ena_shift = '1' then 
			dint <= rxs & dint(7 downto 1) ;
		end if;
	end if;
end process ;
 --------------------
   -- shift Dout --
   -------------------
   process(resetN,clk)
begin 
	if resetN = '0' then
		dout <= (others => '0') ;
	elsif rising_edge(clk) then 
		if dout_ena = '1' then
			dout <= dint ;
		end if;
	end if;
end process ;
   ----------------------
   -- output flag --
   ----------------------
process(clk)
variable tmp: std_logic := '0';
begin
	if rising_edge(clk) then 
		if dout_ena = '0' and read_dout ='0' then 
			tmp := tmp ;
		elsif dout_ena = '1' and read_dout ='1' then 
			tmp := 'Z' ;
		elsif dout_ena = '1' and read_dout ='0' then 
			tmp := '1' ;
		elsif dout_ena = '0' and read_dout ='1' then 
			tmp := '0' ;
		end if;
	end if;
	dout_ready <= tmp ;
	qbar <= not tmp ;
end process;

end arc_receiver ;
