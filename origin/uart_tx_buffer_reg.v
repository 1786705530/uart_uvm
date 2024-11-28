`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/06 18:23:26
// Design Name: 
// Module Name: uart_tx_buffer_reg
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

module uart_tx_buffer_reg(
    input           clk_125                     ,
    input           rst_n_125                   ,
    output          tx_fifo_wr                  ,
    output reg[31:0]tx_fifo_wr_data             ,
    input [7:0]     tx_fifo_wr_num              ,
    input           slv_reg_wren                ,
    input [31:0]    peripheral_data_in          ,
    output [31:0]   tfi                    
    );


wire [14:0]tfsn;
wire tx_prog_full;
assign tfsn[1:0]            = 2'b0                                          ;
assign tfsn[14:2]           = 13'd254-tx_fifo_wr_num                        ;
assign tfi                  = {tx_prog_full,16'b0,tfsn}                     ;
assign tx_prog_full = (tx_fifo_wr_num >= 8'd253) ? 1'b1 : 1'b0;

reg tx_fifo_wr_tmp;

assign tx_fifo_wr = (tx_fifo_wr_num < 8'd254)? tx_fifo_wr_tmp : 1'b0;


always@(posedge clk_125)
    if(rst_n_125 == 'd0)
    begin 
        tx_fifo_wr_tmp <= 'd0;
        tx_fifo_wr_data <= 'd0;
    end 
    else if(slv_reg_wren)
    begin 
        tx_fifo_wr_tmp <= 'd1;
        tx_fifo_wr_data <= peripheral_data_in;
    end 
    else
    begin  
        tx_fifo_wr_tmp <= 'd0;
        tx_fifo_wr_data <= tx_fifo_wr_data;
    end 



endmodule
