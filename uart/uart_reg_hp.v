`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/09 15:54:36
// Design Name: 
// Module Name: uart_reg_hp
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


module uart_reg_hp(
        input               clk_125                 ,
        input               rst_n                   ,
        output              en_ctrl                 ,
        output              uart_re                 ,
        output              uart_te                 ,
        output              uart_tx                 ,
        input               uart_rx                 ,
        output              uart_rx_vld             ,
        output [7:0]        uart_rx_data            ,
        output              uart_tx_fifo_rden       , 
        input [31:0]        uart_tx_fifo_data       , 
        output              uart_tx_fifo_empty      ,   
        input [31:0]        peripheral_data_in      ,
        input [31:0]        peripheral_addr_in      ,
        input               peripheral_read_en      ,
        input               peripheral_write_en     ,
        input  [31:0]       peripheral_base_addr    ,    
        output [31:0]       peripheral_data_out     ,
        output              peripheral_data_out_en 

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

wire [31:0]axi_uart_cr;

wire [3:0]uart_brr;
wire uart_sr;
wire uart_ps;
wire uart_sb;
wire uart_pce;

assign uart_brr    = axi_uart_cr[11:8]                         ;
assign uart_sr     = axi_uart_cr[4]                            ;
assign uart_ps     = axi_uart_cr[2]                            ;
assign uart_sb     = axi_uart_cr[5]                            ;
assign uart_pce    = axi_uart_cr[3]                            ;
assign uart_re     = axi_uart_cr[0]                            ;
assign uart_te     = axi_uart_cr[1]                            ;

wire ne_flag;
wire fe_flag;
wire pe_flag;
wire uart_tx_end;


uartctrl_reg uartctrl_reg_u1
(
    .clk_125                (clk_125                ),
    .rst_n_125              (rst_n_125              ),
    .axi_uart_cr            (axi_uart_cr            ),
    .ne_flag                (ne_flag                ),
    .fe_flag                (fe_flag                ),
    .pe_flag                (pe_flag                ),
    .peripheral_data_in     (peripheral_data_in     ),
    .peripheral_addr_in     (peripheral_addr_in     ),
    .peripheral_read_en     (peripheral_read_en     ),
    .peripheral_write_en    (peripheral_write_en    ),
    .peripheral_base_addr   (peripheral_base_addr   ),
    .peripheral_data_out    (peripheral_data_out    ),
    .peripheral_data_out_en (peripheral_data_out_en )

);


uartctrl_0 uartctrl_u
(
    .clk_i                  (clk_125                ),
    .rstn_i                 (rst_n_125              ),
    .uart_brr_i             (uart_brr               ),
    .uart_sr_i              (uart_sr                ),//uart_sr
    .uart_ps_i              (uart_ps                ),//uart_ps
    .uart_sb_i              (uart_sb                ),//uart_sb
    .uart_pce_i             (uart_pce               ),//uart_pce
    .uart_re                (uart_re                ),
    .uart_tx                (uart_tx                ),
    .uart_rx                (uart_rx                ),
    .uart_rxvld_o           (uart_rx_vld            ),
    .uart_rxdata_o          (uart_rx_data           ),
    .uart_txfifo_empty_i    (uart_tx_fifo_empty     ),
    .uart_txfifo_rden_o     (uart_tx_fifo_rden      ),
    .uart_txfifo_data_i     (uart_tx_fifo_data      ),
    .uart_tx_end_o          (uart_tx_end            ),
    .ne_flag                (ne_flag                ),
    .fe_flag                (fe_flag                ),
    .pe_flag                (pe_flag                ),
    .en_ctrl                (en_ctrl                )

);


endmodule
