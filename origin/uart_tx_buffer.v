`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/06 17:53:22
// Design Name: 
// Module Name: uart_tx_buffer
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


module uart_tx_buffer(
    input           clk_125                     ,
    input           rst_n_125                   ,
    input           uart_mon_tx_en              ,
    input           uart_tx_fifo_rden           ,
    output [31:0]   uart_tx_fifo_data           ,
    output          uart_tx_fifo_empty          ,
    input           slv_reg_wren                ,
    input[31:0]     peripheral_data_in          ,
    output[31:0]    uart_tfi                    

    );


wire [31:0] uart_tx_fifo_wr_data;
wire uart_tx_fifo_wr;

wire [7:0]uart_tx_fifo_wr_num;
wire uart_tx_fifo_prog_full;

uart_tx_buffer_reg uart_tx_buffer_reg_u1(
    .clk_125                     (clk_125                ),
    .rst_n_125                   (rst_n_125              ),
    .tx_fifo_wr                  (uart_tx_fifo_wr        ),
    .tx_fifo_wr_data             (uart_tx_fifo_wr_data   ),
    .tx_fifo_wr_num              (uart_tx_fifo_wr_num    ),
    .slv_reg_wren                (slv_reg_wren           ),
    .peripheral_data_in          (peripheral_data_in     ),
    .tfi                         (uart_tfi               )   
    );


uart_tx_fifo_256x32 uart_tx_fifo_256x32(
    .wr_clk                      (clk_125                ),
    .rd_clk                      (clk_125                ),
    .din                         (uart_tx_fifo_wr_data   ),
    .rst                         (~uart_mon_tx_en        ),
    .wr_en                       (uart_tx_fifo_wr        ),
    .rd_en                       (uart_tx_fifo_rden      ),
    .dout                        (uart_tx_fifo_data      ),
    .full                        (                       ),
    .empty                       (uart_tx_fifo_empty     ),
    .prog_full                   (uart_tx_fifo_prog_full ),
    .wr_data_count               (uart_tx_fifo_wr_num    ),
    .rd_data_count               (                       )
);





endmodule
