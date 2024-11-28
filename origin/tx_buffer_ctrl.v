`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/05 17:25:39
// Design Name: 
// Module Name: tx_buffer_ctrl
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


module tx_buffer_ctrl(
    input                   clk_125                     ,//125MHz 
    input                   can_clk                     , 
    input                   rst_n                       ,  
    input  [11:0]           uart_mon_tx_en              ,
    input  [11:0]           uart_tx_fifo_rden           ,
    output [11:0][31:0]     uart_tx_fifo_data           ,
    output [11:0]           uart_tx_fifo_empty          ,
    input                   fast_tx_fifo_rden           ,
    output [31:0]           fast_tx_fifo_data           ,
    output                  fast_tx_fifo_empty          ,
    output [7:0]            fast_tx_fifo_rd_num         ,
    input                   block_tx_fifo_rden          ,
    output [31:0]           block_tx_fifo_data          ,
    output                  block_tx_fifo_empty         ,
    output [11:0]           block_tx_fifo_rd_num        ,
    input  [3:0]            ar429_mon_tx_en             ,
    input  [3:0]            ar429_tx_fifo_rden          ,
    output [3:0][31:0]      ar429_tx_fifo_data          ,
    output [3:0]            ar429_tx_fifo_empty         ,
    input  [9:0]            can_mon_tx_en               ,
    input  [9:0]            can_tx_fifo_rden            ,
    output [9:0][7:0]       can_tx_fifo_data            ,
    output [9:0]            can_tx_fifo_empty           ,
    input [31:0]            peripheral_data_in          ,
    input [31:0]            peripheral_addr_in          ,
    input                   peripheral_read_en          ,
    input                   peripheral_write_en         ,  
    output [31:0]           peripheral_data_out         ,
    output                  peripheral_data_out_en 

    );

wire rst_n_125;

xpm_cdc_async_rst #(

  //Common module parameters
  .DEST_SYNC_FF    (4), // integer; range: 2-10
  .INIT_SYNC_FF    (0), // integer; 0=disable simulation init values, 1=enable simulation init values
  .RST_ACTIVE_HIGH (0)  // integer; 0=active low reset, 1=active high reset

) xpm_cdc_async_rst_inst (

  .src_arst  (rst_n),
  .dest_clk  (clk_125),
  .dest_arst (rst_n_125)

);

wire [31:0]slv_reg_wren;
wire [31:0]slv_reg_rden;

wire [11:0][31:0]uart_tfi;
wire [9:0][31:0]can_tfi;
wire [3:0][31:0]ar429_tfi;
wire [31:0]fast_tfi;
wire [31:0]block_tfi;


tx_buffer_write_enable tx_buffer_write_enable_u1(
    .clk_125                    (clk_125                      ),
    .rst_n_125                  (rst_n_125                    ),
    .slv_reg_wren               (slv_reg_wren                 ),
    .slv_reg_rden               (slv_reg_rden                 ),
    .peripheral_addr_in         (peripheral_addr_in           ),
    .peripheral_read_en         (peripheral_read_en           ),
    .peripheral_write_en        (peripheral_write_en          )
    );



genvar i,j;
generate for(i=0;i<12;i=i+1) begin : UART
    uart_tx_buffer uart_tx_buffer_u1(
        .clk_125                     (clk_125                     ),
        .rst_n_125                   (rst_n_125                   ),
        .uart_mon_tx_en              (uart_mon_tx_en[i]           ),
        .uart_tx_fifo_rden           (uart_tx_fifo_rden [i]       ),
        .uart_tx_fifo_data           (uart_tx_fifo_data [i]       ),
        .uart_tx_fifo_empty          (uart_tx_fifo_empty[i]       ),
        .slv_reg_wren                (slv_reg_wren[i]             ),
        .peripheral_data_in          (peripheral_data_in          ),
        .uart_tfi                    (uart_tfi[i]                 )
        );

end
endgenerate


cpu_sync_tx_buffer cpu_sync_tx_buffer_u1(
    .clk_125                     (clk_125                   ),
    .rst_n_125                   (rst_n_125                 ),
    .fast_fifo_rden              (fast_tx_fifo_rden         ),
    .fast_fifo_data              (fast_tx_fifo_data         ),
    .fast_fifo_empty             (fast_tx_fifo_empty        ),
    .fast_fifo_rd_num            (fast_tx_fifo_rd_num       ),
    .block_fifo_rden             (block_tx_fifo_rden        ),
    .block_fifo_data             (block_tx_fifo_data        ),
    .block_fifo_empty            (block_tx_fifo_empty       ),
    .block_fifo_rd_num           (block_tx_fifo_rd_num      ),
    .slv_reg_wren                (slv_reg_wren[31:30]       ),
    .peripheral_data_in          (peripheral_data_in        ),
    .fast_tfi                    (fast_tfi                  ),
    .block_tfi                   (block_tfi                 )
    );

generate for(i=0;i<4;i=i+1) begin : AR429
    ar429_tx_buffer ar429_tx_buffer_u1(
        .clk_125                     (clk_125                     ),
        .rst_n_125                   (rst_n_125                   ),
        .ar429_mon_tx_en             (ar429_mon_tx_en[i]          ),
        .ar429_tx_fifo_rden          (ar429_tx_fifo_rden [i]      ),
        .ar429_tx_fifo_data          (ar429_tx_fifo_data [i]      ),
        .ar429_tx_fifo_empty         (ar429_tx_fifo_empty[i]      ),
        .slv_reg_wren                (slv_reg_wren[26+i]          ),
        .peripheral_data_in          (peripheral_data_in          ),
        .ar429_tfi                   (ar429_tfi[i]                )
        );
end
endgenerate

generate for(i=0;i<10;i=i+1) begin : CAN
    can_tx_buffer can_tx_buffer_u1(
        .clk_125                     (clk_125                     ),
        .can_clk                     (can_clk                     ),
        .rst_n_125                   (rst_n_125                   ),
        .can_mon_tx_en               (can_mon_tx_en[i]            ),
        .can_tx_fifo_rden            (can_tx_fifo_rden [i]        ),
        .can_tx_fifo_data            (can_tx_fifo_data [i]        ),
        .can_tx_fifo_empty           (can_tx_fifo_empty[i]        ),
        .slv_reg_wren                (slv_reg_wren[16+i]          ),
        .peripheral_data_in          (peripheral_data_in          ),
        .can_tfi                     (can_tfi[i]                  )
        );
end
endgenerate




tx_buffer_upload_route tx_buffer_upload_route_u1(
    .clk_125                     (clk_125                   ),
    .rst_n_125                   (rst_n_125                 ),
    .slv_reg_rden                (slv_reg_rden              ),
    .uart_tfi                    (uart_tfi                  ),
    .can_tfi                     (can_tfi                   ),
    .ar429_tfi                   (ar429_tfi                 ),
    .fast_tfi                    (fast_tfi                  ),  
    .block_tfi                   (block_tfi                 ),     
    .peripheral_data_out_en      (peripheral_data_out_en    ),
    .peripheral_data_out         (peripheral_data_out       )
    );





endmodule
