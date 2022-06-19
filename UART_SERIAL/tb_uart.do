# a possible do (*.TCL) script to run the UART transmitter simulation
vcom transmitter.vhd
vcom receiver.vhd
vcom tb_UART.vhd
vsim tb_UART

add wave            resetN                    
add wave            clk     
add wave            rx        
add wave            read_dout 
add wave            rx_ready  
add wave            dout      
add wave 			write_din
add wave 			din
add wave 			tx



--add wave /tb_receiver/eut/present_state
--add wave -radix unsigned /tb_receiver/eut/tcount 
--add wave /tb_receiver/eut/te     
--add wave /tb_receiver/eut/t1     
--add wave /tb_receiver/eut/t2     
--add wave -radix unsigned /tb_receiver/eut/dcount     
--add wave /tb_receiver/eut/ena_dcount 
--add wave /tb_receiver/eut/clr_dcount 
--add wave /tb_receiver/eut/eoc          
--add wave /tb_receiver/eut/rxs       
--add wave /tb_receiver/eut/ena_shift 
--add wave /tb_receiver/eut/dint      
--add wave /tb_receiver/eut/dout_ena 

run 1000000 ns
