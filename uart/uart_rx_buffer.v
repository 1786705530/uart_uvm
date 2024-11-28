`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/06 15:54:52
// Design Name: 
// Module Name: uart_rx_buffer
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


module uart_rx_buffer(
        input                           clk_125                 ,
        input                           ifc_clk                 ,
        input                           rst_n                   ,
        input                           uart_rx_vld             ,
        input         [7:0]             uart_rx_data            ,
        input                           frame_ping_pong_flag    ,
        input         [31:0]            bus_data_in             ,
        input         [31:0]            bus_addr_in             ,
        input                           bus_read_en             ,
        input                           bus_write_en            ,
        input         [31:0]            bus_base_addr           ,    
        output        [31:0]            bus_data_out            ,
        output                          bus_data_out_en 
    );


wire [7:0]uart_rx_fifo_data_1;
wire [7:0]uart_rx_fifo_data_2;

wire [9:0]uart_rfdn_1;
wire [9:0]uart_rfdn_2;

wire uart_rx_fifo_wren_1;
wire uart_rx_fifo_wren_2;
wire uart_rx_fifo_rden_1;
wire uart_rx_fifo_rden_2;
wire uart_rx_fifo_empty_1;
wire uart_rx_fifo_empty_2;

wire [9:0]uart_rx_fifo_wr_num_1;
wire [9:0]uart_rx_fifo_wr_num_2;

uart_rx_buffer_read_reg uart_rx_buffer_read_reg_u1(
    .clk                    (ifc_clk                ),//ifc_clk
    .rst_n                  (rst_n                  ),
    .uart_rx_fifo_rden_1    (uart_rx_fifo_rden_1    ),
    .uart_rx_fifo_rden_2    (uart_rx_fifo_rden_2    ),
    .uart_rx_fifo_data_1    (uart_rx_fifo_data_1    ),
    .uart_rx_fifo_data_2    (uart_rx_fifo_data_2    ),
    .uart_rx_fifo_empty_1   (uart_rx_fifo_empty_1   ),
    .uart_rx_fifo_empty_2   (uart_rx_fifo_empty_2   ),
    .uart_rfdn_1            (uart_rfdn_1            ),
    .uart_rfdn_2            (uart_rfdn_2            ),
    .frame_ping_pong_flag   (frame_ping_pong_flag   ),
    .bus_data_in            (bus_data_in            ),
    .bus_addr_in            (bus_addr_in            ),
    .bus_read_en            (bus_read_en            ),
    .bus_write_en           (bus_write_en           ),
    .bus_base_addr          (bus_base_addr          ),
    .bus_data_out           (bus_data_out           ),
    .bus_data_out_en        (bus_data_out_en        )
    );


uart_rx_buffer_write_reg uart_rx_buffer_write_reg_u1(
    .clk                    (clk_125                ),//clk_125
    .rst_n                  (rst_n                  ),
    .uart_rx_vld            (uart_rx_vld            ),
    .frame_ping_pong_flag   (frame_ping_pong_flag   ),
    .uart_rx_fifo_wr_num_1  (uart_rx_fifo_wr_num_1  ),
    .uart_rx_fifo_wr_num_2  (uart_rx_fifo_wr_num_2  ),  
    .uart_rx_fifo_wren_1    (uart_rx_fifo_wren_1    ),
    .uart_rx_fifo_wren_2    (uart_rx_fifo_wren_2    )
    );



uart_rx_fifo_1024x8 uart_rx_fifo_1024x8_u1(
    .wr_clk                 (clk_125                ), 
    .rd_clk                 (ifc_clk                ), 
    .din                    (uart_rx_data            ), 
    .wr_en                  (uart_rx_fifo_wren_1    ), 
    .rd_en                  (uart_rx_fifo_rden_1    ), 
    .dout                   (uart_rx_fifo_data_1    ), 
    .full                   (                       ), 
    .empty                  (uart_rx_fifo_empty_1   ), 
    .wr_data_count          (uart_rx_fifo_wr_num_1  ), 
    .rd_data_count          (uart_rfdn_1            ), 
    .prog_full              (                       )  
);



uart_rx_fifo_1024x8 uart_rx_fifo_1024x8_u2(
    .wr_clk                 (clk_125                ), 
    .rd_clk                 (ifc_clk                ),
    .din                    (uart_rx_data            ), 
    .wr_en                  (uart_rx_fifo_wren_2    ), 
    .rd_en                  (uart_rx_fifo_rden_2    ), 
    .dout                   (uart_rx_fifo_data_2    ), 
    .full                   (                       ), 
    .empty                  (uart_rx_fifo_empty_2   ), 
    .wr_data_count          (uart_rx_fifo_wr_num_2  ), 
    .rd_data_count          (uart_rfdn_2            ), 
    .prog_full              (                       )  
);





endmodule
