`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/08/06 17:04:15
// Design Name: 
// Module Name: uartctrl_reg
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


module uartctrl_reg(

        input               clk_125                 ,
        input               rst_n_125               ,
        input               pe_flag                 ,
        input               fe_flag                 ,
        input               ne_flag                 ,
        output reg[31:0]    axi_uart_cr             ,
        input [31: 0]       peripheral_data_in      ,
        input [31: 0]       peripheral_addr_in      ,
        input               peripheral_read_en      ,
        input               peripheral_write_en     ,
        input [31:0]        peripheral_base_addr    ,    
        output reg [31: 0]  peripheral_data_out     ,
        output reg          peripheral_data_out_en  
    );



reg[7:0] uart_pe_cnt;
reg[7:0] uart_fe_cnt;
reg[7:0] uart_ne_cnt;
wire [31:0]axi_uart_st;
wire [31:0]axi_uart_rfdn;
wire [31:0]axi_uart_tfi;
reg [31:0]axi_uart_tnc;
reg [31:0]axi_uart_tfc;
reg [31:0]axi_uart_tpc;

wire slv_reg_wren;
assign slv_reg_wren = (peripheral_write_en && peripheral_addr_in[31:16] == peripheral_base_addr[15:0]) ? 1'b1 : 1'b0;

wire slv_reg_rden;
assign slv_reg_rden = peripheral_read_en && (peripheral_addr_in[31:16] == peripheral_base_addr[15:0]);




always@(posedge clk_125)
    if(rst_n_125 == 'd0)
        axi_uart_cr <= 'd0;
    else if(slv_reg_wren)
        if(peripheral_addr_in[15:2] == 'h0)
            axi_uart_cr <= peripheral_data_in;

reg [31:0]reg_data_out;
reg reg_data_out_en;

always @(*)
    if(slv_reg_rden) 
        case(peripheral_addr_in[15:0])
            16'h0000       : begin reg_data_out = axi_uart_cr ; reg_data_out_en <= 'd1; end   
            16'h1000       : begin reg_data_out = axi_uart_st ; reg_data_out_en <= 'd1; end 
            16'h1004       : begin reg_data_out = axi_uart_tnc; reg_data_out_en <= 'd1; end 
            16'h1008       : begin reg_data_out = axi_uart_tfc; reg_data_out_en <= 'd1; end 
            16'h100C       : begin reg_data_out = axi_uart_tpc; reg_data_out_en <= 'd1; end             
            default        : begin reg_data_out = 32'h0       ; reg_data_out_en <= 'd0; end 
        endcase
    else 
    begin 
        reg_data_out <= 32'h0; 
        reg_data_out_en <= 'd0; 
    end



always@(posedge clk_125)
    if(rst_n_125 == 'd0)
        peripheral_data_out <= 'd0;
    else if (reg_data_out_en)
        peripheral_data_out <= reg_data_out;    

always@(posedge clk_125)
    if(rst_n_125 == 'd0)
        peripheral_data_out_en <= 'd0;
    else if (reg_data_out_en)
        peripheral_data_out_en <= 'd1;
    else 
        peripheral_data_out_en <= 'd0;


always@(posedge clk_125)
    if(rst_n_125 == 'd0)
        uart_pe_cnt <= 'd0;
    else if(pe_flag&(~&uart_pe_cnt))
        uart_pe_cnt <= uart_pe_cnt + 1'b1;

always@(posedge clk_125)
    if(rst_n_125 == 'd0)
        uart_fe_cnt <= 'd0;
    else if(fe_flag&(~&uart_fe_cnt))
        uart_fe_cnt <= uart_fe_cnt + 1'b1;

always@(posedge clk_125)
    if(rst_n_125 == 'd0)
        uart_ne_cnt <= 'd0;
    else if(ne_flag&(~&uart_ne_cnt))
        uart_ne_cnt <= uart_ne_cnt + 1'b1;

always@(posedge clk_125)
    if(rst_n_125 == 'd0)
        axi_uart_tpc <= 'd0;
    else if(pe_flag&(~&axi_uart_tpc))
        axi_uart_tpc <= axi_uart_tpc + 1'b1;

always@(posedge clk_125)
    if(rst_n_125 == 'd0)
        axi_uart_tfc <= 'd0;
    else if(fe_flag&(~&axi_uart_tfc))
        axi_uart_tfc <= axi_uart_tfc + 1'b1;

always@(posedge clk_125)
    if(rst_n_125 == 'd0)
        axi_uart_tnc <= 'd0;
    else if(ne_flag&(~&axi_uart_tnc))
        axi_uart_tnc <= axi_uart_tnc + 1'b1;


assign axi_uart_st = {8'd0,uart_ne_cnt,uart_fe_cnt,uart_pe_cnt};

endmodule
