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
    input                               clock_125                               ,
    input                               rst_n_125                               ,//


    input      [11:0]                   uart_cr                                 ,

    output                              uart_tx                                 ,//
    input                               uart_rx                                 ,//
    output                              uart_rxvld                            ,//
    output     [ 7:0]                   uart_rxdata                           ,//
    input                               uart_txfifo_empty                       ,//
    output                              uart_txfifo_rden                        ,//
    input      [31:0]                   uart_txfifo_data                        ,//
    output                              ne_flag                                 ,//
    output                              fe_flag                                 ,//
    output                              pe_flag                                 ,//
    output                              en_ctrl                                  //

);


    wire                                uart_txreq                              ;//串口发送请求
    wire       [ 7:0]                   uart_txdata                             ;//串口应发送数据
    wire                                uart_txend                              ;//串口发送结束标志



    uart_tx uart_tx_u(
        .clock_125              (clock_125          ),
        .rst_n_125              (rst_n_125          ),
        .tx                     (uart_tx            ),
        
        .uart_cr                (uart_cr            ),
        .pi_data                (uart_txdata        ),
        .pi_flag                (uart_txreq         ),
        .txend                  (uart_txend         )
    );

    uart_rx uart_rx_u(
        .clock_125              (clock_125          ),
        .rst_n_125              (rst_n_125          ),
        .rx                     (uart_tx            ),
        .po_data                (uart_rxdata        ),
        .po_flag                (uart_rxvld         ),

        .uart_cr                (uart_cr            ),


        .ne_flag                (ne_flag            ),
        .fe_flag                (fe_flag            ),
        .pe_flag                (pe_flag            )
    );

    uart_state uart_state_u(
        .clock_125              (clock_125          ),
        .rst_n_125              (rst_n_125          ),//

        .uart_cr                (uart_cr            ),
        .uart_txfifo_empty      (uart_txfifo_empty  ),//
        .uart_txfifo_rden       (uart_txfifo_rden   ),//
        .uart_txfifo_data       (uart_txfifo_data   ),//
        .uart_txreq             (uart_txreq         ),
        .uart_txdata            (uart_txdata        ),
        .uart_txend             (uart_txend         ),//
        .en_ctrl                (en_ctrl            ) //
    );
endmodule
