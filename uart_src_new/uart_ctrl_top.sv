`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: BoundaryAI
// Engineer: Hzh
// Create Date: 2023_7_24
// Module Name: uart_ctrl_top
// Description: uart_ctrl_top
// Revision: uart_ctrl_top
//////////////////////////////////////////////////////////////////////////////////

module uart_ctrl_top (
    input                               clk_i                                   ,
    input                               rstn_i                                  ,//
//
    input       [ 3:0]                  uart_brr_i                              ,//波特率设置值
    input                               uart_sr_i                               ,//采样率设置值
    input                               uart_ps_i                               ,//奇偶校验位选择
    input                               uart_sb_i                               ,//停止位设置值
    input                               uart_pce_i                              ,//奇偶校验位使能
//
    input                               uart_re                                 ,//
    output                              uart_tx                                 ,//
    input                               uart_rx                                 ,//
    output                              uart_rxvld_o                            ,//
    output     [ 7:0]                   uart_rxdata_o                           ,//
    // data//
    input                               uart_txfifo_empty_i                     ,//
    output                              uart_txfifo_rden_o                      ,//
    input      [31:0]                   uart_txfifo_data_i                      ,//
//
    output                              uart_tx_end_o                           ,//
    output                              ne_flag                                 ,//
    output                              fe_flag                                 ,//
    output                              pe_flag                                 ,//
    output                              en_ctrl                                  //

);



//******************************************************************************//
// Local parameters Declarations
//******************************************************************************//
//******************************************************************************//
// Signal Declarations
//******************************************************************************//
wire            [ 1:0]                   uart_paribit                            ;
wire                                     uart_stopbit                            ;

wire                                     uart_txreq                              ;//串口发送请求
wire             [ 7:0]                  uart_txdata                             ;//串口应发送数据
wire                                     uart_txend                              ;//串口发送结束标志
//
wire                                     uart_rxvld                              ;//发送
wire            [ 7:0]                   uart_rxdata                             ;//
//
wire             [3:0]                    uart_brr                                ;//
//
wire             [31:0]                   baud_cnt_max                           ;//
wire             [31:0]                   baud_cnt_max_half                      ;//
parameter CLK_FREQ = 32'd125_000_000;
//******************************************************************************//
// Code
//******************************************************************************//


uart_tx uart_tx_u(
    .clk_i                  (clk_i              ),
    .rstn_i                 (rstn_i             ),
    .tx                     (uart_tx            ),
    .pi_data                (uart_txdata        ),
    .pi_flag                (uart_txreq         ),
    .baud_cnt_max           (baud_cnt_max       ),
    .baud_cnt_max_half      (baud_cnt_max_half  ),
    .paribit                (uart_paribit       ),
    .stopbit                (uart_stopbit       ),  
    .txend                  (uart_txend         )


    );

uart_rx uart_rx_u(
    .clk_i                  (clk_i              ),
    .rstn_i                 (rstn_i             ),
    .uart_re                (uart_re            ),
    .rx                     (uart_rx            ),
    .baud                   (uart_brr           ),
    .po_data                (uart_rxdata        ),
    .po_flag                (uart_rxvld         ),
    .paribit                (uart_paribit       ),
    .stopbit                (uart_stopbit       ),
    .baud_cnt_max           (baud_cnt_max       ),
    .baud_cnt_max_half      (baud_cnt_max_half  ),
    .ne_flag                (ne_flag            ),
    .fe_flag                (fe_flag            ),
    .pe_flag                (pe_flag            )

    );



    uart_state uart_state
    (
        .clk_i                      (clk_i              ),
        .rstn_i                     (rstn_i             ),//

        .uart_brr_i                 (uart_brr_i         ),//波特率设置值
        .uart_ps_i                  (uart_ps_i          ),//奇偶校验位选择
        .uart_sb_i                  (uart_sb_i          ),//停止位设置值
        .uart_pce_i                 (uart_pce_i         ),//奇偶校验位使能

        .uart_rxvld_o               (uart_rxvld_o       ),//
        .uart_rxdata_o              (uart_rxdata_o      ),//

        .uart_txfifo_empty_i        (uart_txfifo_empty_i  ),//
        .uart_txfifo_rden_o         (uart_txfifo_rden_o   ),//
        .uart_txfifo_data_i         (uart_txfifo_data_i   ),//

        .uart_tx_end_o              (uart_tx_end_o      ),//

        .uart_paribit               (uart_paribit      ),
        .uart_stopbit               (uart_stopbit      ),
        .uart_txreq                 (uart_txreq        ),
        .uart_txdata                (uart_txdata       ),
        .uart_txend                 (uart_txend        ),//


        .uart_rxdata                (uart_rxdata       ),
        .uart_rxvld                 (uart_rxvld        ),//
        .uart_brr                   (uart_brr          ),
        .baud_cnt_max               (baud_cnt_max      ),//
        .baud_cnt_max_half          (baud_cnt_max_half ),//

        .en_ctrl                    (en_ctrl          ) //
);
endmodule



//uart_tx_rx uart_tx_rx
//    (
//        .rstn_i                 (rstn_i                 ),
//        .clk_i                  (clk_i                  ),
//            
//        .uart_re                (uart_re                ),
//        .uart_rx                (uart_rx                ),
//        .uart_tx                (uart_tx                ),
//            
//        .uart_brr               (uart_brr               ),
//        .uart_paribit           (uart_paribit           ),
//        .uart_stopbit           (uart_stopbit           ),
//        .uart_txreq             (uart_txreq             ), 
//        
//        .uart_txend             (uart_txend             ),
//        .uart_txdata            (uart_txdata            ),
//        .uart_rxvld             (uart_rxvld             ),
//        .uart_rxdata            (uart_rxdata            ),
//        .baud_cnt_max           (baud_cnt_max           ),
//        .baud_cnt_max_half      (baud_cnt_max_half      ),
//        .ne_flag                (ne_flag                ),
//        .fe_flag                (fe_flag                ),
//        .pe_flag                (pe_flag                )
//
//    );
