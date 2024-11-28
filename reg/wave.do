onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/uartctrl_reg_u1/clk_125
add wave -noupdate /tb/uartctrl_reg_u1/rst_n_125
add wave -noupdate /tb/uartctrl_reg_u1/pe_flag
add wave -noupdate /tb/uartctrl_reg_u1/fe_flag
add wave -noupdate /tb/uartctrl_reg_u1/ne_flag
add wave -noupdate /tb/uartctrl_reg_u1/axi_uart_cr
add wave -noupdate /tb/uartctrl_reg_u1/peripheral_data_in
add wave -noupdate /tb/uartctrl_reg_u1/peripheral_addr_in
add wave -noupdate /tb/uartctrl_reg_u1/peripheral_read_en
add wave -noupdate /tb/uartctrl_reg_u1/peripheral_write_en
add wave -noupdate /tb/uartctrl_reg_u1/peripheral_base_addr
add wave -noupdate /tb/uartctrl_reg_u1/peripheral_data_out
add wave -noupdate /tb/uartctrl_reg_u1/peripheral_data_out_en
add wave -noupdate /tb/uartctrl_reg_u1/uart_pe_cnt
add wave -noupdate /tb/uartctrl_reg_u1/uart_fe_cnt
add wave -noupdate /tb/uartctrl_reg_u1/uart_ne_cnt
add wave -noupdate /tb/uartctrl_reg_u1/axi_uart_st
add wave -noupdate /tb/uartctrl_reg_u1/axi_uart_rfdn
add wave -noupdate /tb/uartctrl_reg_u1/axi_uart_tfi
add wave -noupdate /tb/uartctrl_reg_u1/axi_uart_tnc
add wave -noupdate /tb/uartctrl_reg_u1/axi_uart_tfc
add wave -noupdate /tb/uartctrl_reg_u1/axi_uart_tpc
add wave -noupdate /tb/uartctrl_reg_u1/slv_reg_wren
add wave -noupdate /tb/uartctrl_reg_u1/slv_reg_rden
add wave -noupdate /tb/uartctrl_reg_u1/reg_data_out
add wave -noupdate /tb/uartctrl_reg_u1/reg_data_out_en
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1740000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 342
configure wave -valuecolwidth 139
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {1682906 ps} {1797094 ps}
