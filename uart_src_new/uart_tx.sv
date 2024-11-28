`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: BoundaryAI
// Engineer: Hzh
// Create Date: 2023_7_24
// Module Name: uart_tx
// Description: uart_tx
// Revision: uart_tx
//////////////////////////////////////////////////////////////////////////////////

module uart_tx(
	input 				clk_i 					,
	input 				rstn_i 					,
	output reg 			tx 						,//
		
	input [7:0] 		pi_data	 				,//应发送数据
	input 				pi_flag 				,//应发送数据有效标志
	input [31:0] 		baud_cnt_max 			,//波特率计算最大值
    input [31:0] 		baud_cnt_max_half     	,//波特率计算最大半值
	//
    input [ 1:0] 		paribit   		  		,//奇偶校验设置
    input	 	 		stopbit   		  		,//停止位设置
	output  reg			txend 					 //发送完成标志


);
//================================================================
	reg [31:0] 		cnt_baud				;//波特率计数器
	reg 		 	bit_flag				;//bit标志
	reg [3:0] 		bit_cnt 				;//bit计数器
	reg [3:0] 		bit_cnt_Max 			;//bit计数最大值
	reg [1:0] 		paribit_reg				;//奇偶校验设置寄存器
	//
	reg [1:0] 		pi_redge_reg 			;//用于监测应发送数据有效标志
	reg 	  		pi_redge  				;//用于监测应发送数据有效标志
//
	reg [7:0] 		data_reg 				;//数据寄存器
	reg 			pari_reg 				;//奇偶校验值计算器
	reg [31:0]		baud_cnt_max_reg 		;//波特率计数器最大值
	reg [31:0]		baud_cnt_max_half_reg 	;//波特率计数最大半值
	reg [7:0] 		uart_tx_nstate 			;//发送状态机下一状态
//
	reg [7:0] 		uart_tx_state 			;//发送状态机当前状态
	reg 			oddpari_reg 			;//奇校验值寄存器
	reg 			evenpari_reg 			;//偶校验值寄存器

//================================================================
//state machine
	localparam IDLE		 = 8'd0				;//空闲
	localparam START_BIT = 8'd1				;//起始位
	localparam SEND_DATA = 8'd2				;//发送数据阶段
	localparam PARI_BIT  = 8'd3				;//奇偶检验阶段
	localparam STOP_BIT1 = 8'd4				;//第一bit停止位阶段
	localparam STOP_BIT2 = 8'd5				;//第二bit停止位阶段
	localparam FINISH 	 = 8'd7				;//完成
	localparam PARI		 = 8'd8				;//奇偶校验阶段

//================================================================


(* keep = "true" *)    reg                                 rst_reg1                                ;
(* keep = "true" *)    reg                                 rst_reg2                                ;
(* keep = "true" *)    reg                                 rst_reg3                                ;
(* keep = "true" *)    reg                                 rst_reg4                                ;
(* keep = "true" *)    reg                                 rst                                     ;


typedef enum  {IDLE, START_BIT, SEND_DATA, PARI_BIT, STOP_BIT1, STOP_BIT2, FINISH, PARI} state_enum;
state_enum uart_tx_state,uart_tx_nstate;


always @(negedge rstn_i,posedge clk_i) 
begin
    if (!rstn_i) 
        begin
            rst         <= 1'b1;
            rst_reg1    <= 1'b1;
            rst_reg2    <= 1'b1;
            rst_reg3    <= 1'b1;
            rst_reg4    <= 1'b1;
        end
    else 
        begin
            rst_reg1    <= 1'b0;
            rst_reg2    <= rst_reg1;
            rst_reg3    <= rst_reg2;
            rst_reg4    <= rst_reg3;
            rst         <= rst_reg4;
        end
end


//

always @(posedge clk_i)
begin
    if(rst) 
		begin
			pi_redge_reg <= 'd0;
		end
	else 
		begin
			pi_redge_reg <= {pi_redge_reg[0],pi_flag};
		end
end
//
always @(posedge clk_i)
begin
    if(rst) 
		begin
			pi_redge <= 'd0;
		end
	else if(pi_redge_reg[0] == 1'b1 && pi_redge_reg[1] == 1'b0) 
		begin
			pi_redge <= 1'b1;
		end
	else 
		begin
			pi_redge <= 'd0;
		end
end
//
always @(posedge clk_i)
begin
    if(rst) 
		begin
			data_reg<='d0;
		end
	else if (pi_redge == 1'b1)
		begin
			data_reg<=pi_data;
		end
	else 
		begin
			data_reg<=data_reg;
		end
end
//
always @(posedge clk_i)
begin
    if(rst) 
		begin
			bit_cnt_Max<='d0;
		end
	else if (pi_redge == 1'b1)
		begin
			bit_cnt_Max<=4'd8;
		end
	else 
		begin
			bit_cnt_Max<=bit_cnt_Max;
		end
end

always @(posedge clk_i)
begin
    if(rst) 
		begin
			baud_cnt_max_reg<='d0;
		end
	else if (pi_redge == 1'b1) 
		begin
			baud_cnt_max_reg<=baud_cnt_max;
		end
	else 
		begin
			baud_cnt_max_reg<=baud_cnt_max_reg;
		end
end
//
//================================================================
always @(posedge clk_i)
begin
    if(rst)  
		begin
			pari_reg<=1'b0;	
		end
	else if (pi_redge == 1'b1) 
		begin
			pari_reg<= pi_data[0] + pi_data[1] + pi_data[2] + pi_data[3] + pi_data[4] + pi_data[5] + pi_data[6] + pi_data[7];
		end
	else 
		begin
			pari_reg<=pari_reg;	
		end
end
//
always @(posedge clk_i)
begin
    if(rst)  
		begin
			oddpari_reg<='d0;
		end
	else 
		begin
			oddpari_reg<=!pari_reg;
		end
end
//
always @(posedge clk_i)
begin
    if(rst) 
		begin
			evenpari_reg<='d0;
		end
	else 
		begin
			evenpari_reg<=pari_reg;
		end
end
//
always @(posedge clk_i)
begin
    if(rst)  
		begin
			paribit_reg<='d0;
		end
	else if (pi_redge == 1'b1) 
		begin
			paribit_reg<=paribit;
		end
	else 
		begin
			paribit_reg<=paribit_reg;
		end
end
//
//================================================================
always @(posedge clk_i)
begin
    if(rst)  
		begin
			cnt_baud <= 'd0;
		end
	else if(cnt_baud == baud_cnt_max_reg - 1'b1) 
		begin
			cnt_baud <= 'd0;
		end
	else if(uart_tx_state != IDLE) 
		begin
			cnt_baud <= cnt_baud + 1'b1;
		end
	else if(uart_tx_state == IDLE) 
		begin
			cnt_baud <= 'd0;
		end
	else 
		begin
			cnt_baud <= cnt_baud;
		end
end
//
always @(posedge clk_i)
begin
    if(rst) 
		begin
			bit_flag<=1'b0;	
		end
	else if (uart_tx_state == SEND_DATA && cnt_baud==baud_cnt_max_reg -2'd2) 
		begin
			bit_flag<=1'b1;
		end
	else 
		begin
			bit_flag<=1'b0;	
		end
end
//
always @(posedge clk_i)
begin
    if(rst) 
		begin
			bit_cnt<=4'd0;
		end
	else if (uart_tx_state != SEND_DATA) 
		begin
			bit_cnt<=4'd0;
		end
	else if(bit_flag==1'b1) 
		begin
			bit_cnt<=bit_cnt+4'd1;
		end
end
//
//================================================================

always @(posedge clk_i)
begin
    if(rst) 
		begin
			uart_tx_state <= 'd0;
		end
	else 
		begin
			uart_tx_state <= uart_tx_nstate;
		end
end
//
always @(*) 
begin
	uart_tx_nstate = IDLE;
	case(uart_tx_state)
		IDLE:
			if(pi_redge)
				uart_tx_nstate = START_BIT;
			else 
				uart_tx_nstate = IDLE;
		START_BIT:
			if(cnt_baud == baud_cnt_max_reg - 1'b1)
				uart_tx_nstate = SEND_DATA;
			else 
				uart_tx_nstate = START_BIT;	
		SEND_DATA:
			if(cnt_baud == baud_cnt_max_reg - 1'b1 && bit_cnt == bit_cnt_Max - 1'b1)begin
				if (paribit_reg == 2'b00) 
					uart_tx_nstate = STOP_BIT1;
	 			else 
	 				uart_tx_nstate = PARI;
			end
			else 
				uart_tx_nstate = SEND_DATA;
		PARI:
			if(cnt_baud == baud_cnt_max_reg - 1'b1)
				uart_tx_nstate = STOP_BIT1;
	 		else 
	 			uart_tx_nstate = PARI;
		STOP_BIT1:
			if(cnt_baud == baud_cnt_max_reg - 1'b1 && stopbit == 1'b0)//1
				uart_tx_nstate = FINISH;
			else if (cnt_baud == baud_cnt_max_reg - 1'b1 && stopbit == 1'b1) //2
				uart_tx_nstate = STOP_BIT2;
			else 
				uart_tx_nstate = STOP_BIT1;
		STOP_BIT2:
			if(cnt_baud == baud_cnt_max_reg - 1'b1)
				uart_tx_nstate = FINISH;
			else 
				uart_tx_nstate = STOP_BIT2;
		FINISH:
			uart_tx_nstate = IDLE;
		default:
			uart_tx_nstate = IDLE;
	endcase
end
//产生发送波形
//================================================================
always @(posedge clk_i)
begin
    if(rst) 
		begin
			tx<=1'b1;
		end
	else if (uart_tx_state == START_BIT)
		begin
			tx<=1'b0;
		end
	else if (uart_tx_state == IDLE) 
		begin
			tx<=1'b1;
		end
	else if (uart_tx_state == PARI && paribit_reg == 2'b01) 
		begin
			tx<=oddpari_reg;
		end
	else if (uart_tx_state == PARI && paribit_reg == 2'b10) 
		begin
			tx<=evenpari_reg;
		end
	else if (uart_tx_state == SEND_DATA) 
		begin
			tx<=data_reg[bit_cnt];
		end
	else if (uart_tx_state == STOP_BIT1 || uart_tx_state == STOP_BIT2) 
		begin
			tx<=1'b1;
		end
	else 
		begin
			tx<=tx;
		end
end
//产生发送完成标志
always @(posedge clk_i)
begin
    if(rst) 
		begin
			txend<=1'b0;	
		end
	else if (uart_tx_state == FINISH) 
		begin
			txend<=1'b1;
		end
	else 
		begin
			txend<=1'b0;	
		end
end

endmodule
