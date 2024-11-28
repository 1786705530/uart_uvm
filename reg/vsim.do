vsim -voptargs=+acc=bcglnprst+uartctrl_reg work.tb
add wave -position insertpoint sim:/tb/uartctrl_reg_u1/*

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
