`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/12 10:02:42
// Design Name: 
// Module Name: uart_rx_buffer_write_reg
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart_rx_buffer_write_reg(
        input                           clk                     ,
        input                           rst_n                   ,
        input                           uart_rx_vld             ,
        input                           frame_ping_pong_flag    ,
        input [9:0]                     uart_rx_fifo_wr_num_1   ,
        input [9:0]                     uart_rx_fifo_wr_num_2   ,
        output                          uart_rx_fifo_wren_1     ,
        output                          uart_rx_fifo_wren_2     
    );

assign uart_rx_fifo_wren_1  = (frame_ping_pong_flag == 'd1) ? 'd0 : 
                                (uart_rx_fifo_wr_num_1 < 10'd1020) ? uart_rx_vld : 1'b0   ;
assign uart_rx_fifo_wren_2  = (frame_ping_pong_flag == 'd0) ? 'd0 : 
                                (uart_rx_fifo_wr_num_2 < 10'd1020) ? uart_rx_vld : 1'b0   ;



endmodule
