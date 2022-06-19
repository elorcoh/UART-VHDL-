-- Copyright (C) 1991-2010 Altera Corporation
-- Your use of Altera Corporation's design tools, logic functions 
-- and other software and tools, and its AMPP partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Altera Program License 
-- Subscription Agreement, Altera MegaCore Function License 
-- Agreement, or other applicable license agreement, including, 
-- without limitation, that your use is for the sole purpose of 
-- programming logic devices manufactured by Altera and sold by 
-- Altera or its authorized distributors.  Please refer to the 
-- applicable agreement for further details.

-- PROGRAM		"Quartus II"
-- VERSION		"Version 9.1 Build 350 03/24/2010 Service Pack 2 SJ Web Edition"
-- CREATED		"Tue Feb 23 15:55:15 2021"

library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all ;
LIBRARY work;

ENTITY uart1 IS 
	PORT
	(
		clk :  IN  STD_LOGIC;
		resetN :  IN  STD_LOGIC;
		dint_pass :  IN  STD_LOGIC_VECTOR(7 DOWNTO 0)  ;
		dout_pass :  buffer  STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000000"  ;
		d_leds    :  buffer  STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000000"  ;
		transmit  : in std_logic := '0'
	);
END uart1;

ARCHITECTURE arc_uart1 OF uart1 IS 
-- state machine
   type state is
   ( pass1,
    pass2,
	pass3,
	pass4,
	ERROR,
	blink);
	 
type pass is array (0 to 3) of std_logic_vector (7 downto 0);
constant passwoard : pass := 
( "00000000" + character'pos('D'),
"00000000" + character'pos('U'),
"00000000" + character'pos('B'),
"00000000"  + character'pos('I'));
signal pass_test : pass := 
("00000000",
"00000000",
"00000000",
"00000000" );
signal present_state , next_state : state ;
signal count,dcount           : integer := 0 ;
signal blink_ena,ena_error,pass_ena,clr_dcout : std_logic := '0' ;
signal dout_p : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000000" ;
signal blinker : STD_LOGIC_VECTOR(7 DOWNTO 0) := "00000000" ;
BEGIN 

process (clk,resetN)
begin
	if resetN = '0' then
		present_state <= pass1 ;
	elsif rising_edge(clk) then
		present_state <= next_state ;
	end if;
end process ;

process (present_state,pass_ena)
begin
next_state <= pass1 ;
ena_error <= '0' ; blink_ena <= '0' ; 
	case present_state is 
	 -------------------
   -- state 1 : pass1 --
   -------------------
		when pass1 =>
			clr_dcout <= '0'; 
			blink_ena <= '0' ;
			ena_error <='0' ;
			if pass_test(0) = passwoard(0) then 
				next_state <= pass2;
			elsif dcount /= 4 then
				next_state <= pass1;
			else
				next_state <= ERROR ;
			end if;
	 -------------------
   -- state 2:  pass2 --
   -------------------
		when pass2 =>
			clr_dcout <= '0'; 
			blink_ena <= '0' ;
			ena_error <= '0' ;
			if pass_test(1) = passwoard(1) then 
				next_state <= pass3;
			elsif dcount /= 4 then
				next_state <= pass1;
			else
				next_state <= ERROR ;
			end if;
	 -------------------
   -- state 3: pass3 --
   -------------------
		when pass3 =>
			clr_dcout <= '0'; 
			blink_ena <= '0' ;
			ena_error <='0' ;
			if pass_test(2) = passwoard(2) then 
				next_state <= pass4;
			elsif dcount /= 4 then
				next_state <= pass1;
			else
				next_state <= ERROR ;
			end if;
	 -------------------
   -- state 4: pass3 --
   -------------------
		when pass4 =>
			clr_dcout <= '0'; 
			blink_ena <= '0' ;
			ena_error <= '0' ;
			if pass_test(3) = passwoard(3) then 
				next_state <= blink;
			elsif dcount /= 4 then
				next_state <= pass1;
			else
				next_state <= ERROR ;
			end if;
	 -------------------
   -- state 5: blink --
   -------------------
		when blink =>
			blink_ena <= '1' ;
			clr_dcout <= '1' ;
			ena_error <= '0' ;
			next_state <= blink; 
	-------------------
   -- state 6: ERROR --
   -------------------
	 when ERROR =>
			clr_dcout <= '1' ;
			blink_ena <= '0' ;
			ena_error <='1' ;
			next_state <= ERROR ;
	 	when others => next_state <= pass1 ;
	end case;
end process ;


	-------------------
   -- PASSWOARD INSERTION --
   -------------------

process(resetN,clk)
begin
	if resetN = '0' then 
		dcount <= 0 ;
	elsif rising_edge(clk) then
		if dcount < 4 and transmit = '1' then
			pass_test(dcount) <= dint_pass ;
			dcount <= dcount +1 ;
		elsif clr_dcout = '1' then
			dcount <= 0 ;
			pass_test(0) <= "00000000" ;
			pass_test(1) <= "00000000" ;
			pass_test(2) <= "00000000" ;
			pass_test(3) <= "00000000" ;
		end if;
	end if;
end process;
pass_ena <= '1' when (dcount = 4) else '0';


	-------------------
   -- OUTPUT SR FLIPLOP --
   -------------------
   
process (clk,resetN)
begin
	if resetN = '0' then
		dout_pass <= (others => '0') ;
		d_leds <= (others => '0') ;
	elsif rising_edge(clk) then
		if blink_ena = '0' and ena_error = '0' then 
			dout_pass<= dint_pass ;
		elsif blink_ena = '0' and ena_error = '1' then 
			dout_pass<= "11100001" ;
			d_leds <= "11101110" ;
		elsif blink_ena = '1' and ena_error ='0' then 
			dout_pass<= "00100011" ;
			d_leds <= dout_p ;
		elsif blink_ena = '1' and ena_error = '1' then 
			dout_pass <= "11111111" ;
		end if ;
	end if;
end process ;

	-------------------
   -- BLINKER --
   -------------------

process(clk,resetN)
	
	begin
		if resetN = '0' then
		blinker <= (others => '0') ;
		elsif clk'event and clk = '1' and blink_ena = '1' then
				if count = 13333333 then
					count <= 0;
					if dout_p /= "11111111" then
						blinker <= '1' & blinker(7 downto 1);
						dout_p<= blinker xor "00000000";
					else
						dout_p <= dout_p xor "11111111" ;
					end if ;
							
				else
					count <= count + 1;
				end if;
		end if;
	end process;
	
	
end  arc_uart1 ;