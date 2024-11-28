`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/06 17:56:21
// Design Name: 
// Module Name: uart_rx_buffer_read_reg
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


module uart_rx_buffer_read_reg(
        input                           clk                 ,//ifc_clk
        input                           rst_n               ,
        output                          uart_rx_fifo_rden_1 ,
        output                          uart_rx_fifo_rden_2 ,
        input [7:0]                     uart_rx_fifo_data_1 ,
        input [7:0]                     uart_rx_fifo_data_2 ,
        input                           uart_rx_fifo_empty_1,
        input                           uart_rx_fifo_empty_2,
        input [9:0]                     uart_rfdn_1         ,
        input [9:0]                     uart_rfdn_2         ,
        input                           frame_ping_pong_flag,
        input         [31:0]            bus_data_in         ,
        input         [31:0]            bus_addr_in         ,
        input                           bus_read_en         ,
        input                           bus_write_en        ,
        input         [31:0]            bus_base_addr       ,    
        output reg    [31:0]            bus_data_out        ,
        output reg                      bus_data_out_en 
    );


wire uart_rx_fifo_rden;
wire [7:0]uart_rx_fifo_data;

reg [2:0]req_data_quantity;
reg [2:0]req_data_cnt;

wire uart_rx_fifo_empty;
wire[10:0]uart_rfdn;

wire slv_reg_rden;
assign slv_reg_rden = bus_read_en && (bus_addr_in[31:16] == bus_base_addr[15:0]);

always@(posedge clk)
    if(rst_n == 'd0)
        req_data_quantity <= 'd0;
    else if(bus_addr_in[15:0] == 16'h2004 && slv_reg_rden && uart_rx_fifo_empty)
        req_data_quantity <= 'd0;
    else if(bus_addr_in[15:0] == 16'h2004 && slv_reg_rden && uart_rfdn >= 'd4)
        req_data_quantity <= 'd4;
    else if(bus_addr_in[15:0] == 16'h2004 && slv_reg_rden && uart_rfdn < 'd4)
        req_data_quantity <= uart_rfdn[2:0];

reg uart_rx_fifo_rden_f1;
always@(posedge clk)
    if(rst_n == 'd0)
        uart_rx_fifo_rden_f1 <= 'd0;
    else 
        uart_rx_fifo_rden_f1 <= uart_rx_fifo_rden;

always@(posedge clk)
    if(rst_n == 'd0)
        req_data_cnt <= 'd0;
    else if(bus_addr_in[15:0] == 16'h2004 && slv_reg_rden)
        req_data_cnt <= 'd0;
    else if(uart_rx_fifo_rden)
        req_data_cnt <= req_data_cnt + 1'b1;

reg [31:0]axi_uart_rd;
always@(posedge clk)
    if(rst_n == 'd0)
        axi_uart_rd <= 'd0;
    else if(bus_addr_in[15:0] == 16'h2004 && slv_reg_rden)
        axi_uart_rd <= 'd0;
    else if(uart_rx_fifo_rden_f1 && req_data_cnt =='d1)
        axi_uart_rd[7:0] <= uart_rx_fifo_data;
    else if(uart_rx_fifo_rden_f1 && req_data_cnt =='d2)
        axi_uart_rd[15:8] <= uart_rx_fifo_data;
    else if(uart_rx_fifo_rden_f1 && req_data_cnt =='d3)
        axi_uart_rd[23:16] <= uart_rx_fifo_data;
    else if(uart_rx_fifo_rden_f1 && req_data_cnt =='d4)
        axi_uart_rd[31:24] <= uart_rx_fifo_data;

reg [5:0]slv_reg_rden_reg;
always@(posedge clk)
    if(rst_n == 'd0)
        slv_reg_rden_reg <= 'd0;
    else 
        slv_reg_rden_reg <= {slv_reg_rden_reg[4:0],slv_reg_rden};



wire [31:0]axi_uart_lt;
wire [31:0]axi_uart_rfdn;
assign axi_uart_lt          = {29'd0,req_data_quantity}                     ;
assign axi_uart_rfdn        = {21'b0,uart_rfdn}                             ;
reg [31:0]reg_data_out;
reg reg_data_out_en;

always @(*)
    if(bus_addr_in[15:0] == 16'h2004 && slv_reg_rden_reg[5])
    begin 
        reg_data_out <= axi_uart_rd;
        reg_data_out_en <= 'd1;
    end
    else if(slv_reg_rden) 
        case(bus_addr_in[15:0])
            16'h2000       : begin reg_data_out <= axi_uart_rfdn ; reg_data_out_en <= 'd1; end //
            16'h2008       : begin reg_data_out <= axi_uart_lt   ; reg_data_out_en <= 'd1; end 
            default        : begin reg_data_out <= 32'h0         ; reg_data_out_en <= 'd0; end 
        endcase
    else 
    begin 
        reg_data_out <= 32'h0; 
        reg_data_out_en <= 'd0; 
    end
     
always@(posedge clk)
    if(rst_n == 'd0)
        bus_data_out <= 'd0;
    else if(reg_data_out_en)
        bus_data_out <= reg_data_out;

always@(posedge clk)
    if(rst_n == 'd0)
        bus_data_out_en <= 'd0;
    else if(reg_data_out_en)
        bus_data_out_en <= 1'b1;
    else 
        bus_data_out_en <= 'd0;



assign uart_rfdn = (frame_ping_pong_flag == 'd0) ? {1'b0,uart_rfdn_2} : {1'b0,uart_rfdn_1};//frame_ping_pong_flag为0时写FIFO1，读FIFO2
                                                                             //frame_ping_pong_flag为1时写FIFO2，读FIFO1
assign uart_rx_fifo_rden_1  = (frame_ping_pong_flag == 'd0) ? 'd0 : uart_rx_fifo_rden;
                                
assign uart_rx_fifo_rden_2  = (frame_ping_pong_flag == 'd1) ? 'd0 : uart_rx_fifo_rden;
                                
assign uart_rx_fifo_data  = (frame_ping_pong_flag == 'd0) ? uart_rx_fifo_data_2 : uart_rx_fifo_data_1;
                                
assign uart_rx_fifo_empty  = (frame_ping_pong_flag == 'd0) ? uart_rx_fifo_empty_2 : uart_rx_fifo_empty_1;

assign uart_rx_fifo_rden = (req_data_cnt != req_data_quantity)? 1'b1 : 1'b0;



endmodule
