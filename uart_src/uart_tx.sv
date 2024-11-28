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
	input 				clock_125 				,
	input 				rst_n_125 				,
	output reg 			tx 						,//
		
    input [11:0]  		uart_cr                 ,


	input [7:0] 		pi_data	 				,//应发送数据
	input 				pi_flag 				,//应发送数据有效标志
	//
	output  reg			txend 					 //发送完成标志


);
	reg [31:0] 			cnt_baud				;//波特率计数器
//	reg 		 		bit_flag				;//bit标志
	reg [3:0] 			bit_cnt 				;//bit计数器

	reg [7:0] 			data_reg 				;//数据寄存器
	reg 				pari_reg 				;//奇偶校验值计算器
	reg [31:0]			baud_cnt_max 			;//波特率计数器最大值
	wire				oddpari 				;//奇校验值寄存器
	wire				evenpari 				;//偶校验值寄存器
	reg             	rst_reg1                ;
	reg             	rst_reg2                ;
	reg             	rst_reg3                ;
	reg             	rst_reg4                ;
	reg             	rst_125                 ;
	wire            	uart_te                 ;

	reg      			pari_ce_reg				;
	reg      			pari_se_reg				;
	reg      			stopbit_reg				;



	typedef enum  {IDLE, START_BIT, SEND, PARITY, STOP_BIT1, STOP_BIT2, FINISH} state_enum;
	//				空闲   起始位  发送数据 奇偶检验  第一停止位 第二停止位   完成 
	state_enum uart_tx_state,uart_tx_nstate;
	
	localparam 		bit_cnt_max = 4'd8 		;
	assign oddpari  = !pari_reg 	        ; 
	assign evenpari =  pari_reg 	        ; 

	assign uart_te = uart_cr[1] 			;


	always @(posedge clock_125)
		if(rst_125) 
			stopbit_reg <= 'd0;
		else if(uart_tx_state == IDLE)
			stopbit_reg <= uart_cr[5];
		else 
			stopbit_reg <= stopbit_reg;

	always @(negedge rst_n_125,posedge clock_125) 
		if (!rst_n_125) 
			begin
				rst_125   <= 1'b1;
				rst_reg1  <= 1'b1;
				rst_reg2  <= 1'b1;
				rst_reg3  <= 1'b1;
				rst_reg4  <= 1'b1;
			end
		else 
			begin
				rst_reg1  <= 1'b0;
				rst_reg2  <= rst_reg1;
				rst_reg3  <= rst_reg2;
				rst_reg4  <= rst_reg3;
				rst_125   <= rst_reg4;
			end

	always @(posedge clock_125)
		if(rst_125) 
			data_reg <= 'd0;
		else if (uart_tx_state == IDLE)
			data_reg <= pi_data;
		else 
			data_reg <= data_reg;
	
	always @(posedge clock_125)
		if(rst_125) 
			baud_cnt_max <= 'd0;
		else if(uart_tx_state == IDLE)
        	case(uart_cr[11:8])
        	    4'd0    :baud_cnt_max <= 32'd13020   ;//13020.833333333333333333333333333
        	    4'd1    :baud_cnt_max <= 32'd6510    ;//6510.4166666666666666666666666667
        	    4'd2    :baud_cnt_max <= 32'd3255    ;//3255.2083333333333333333333333333
        	    4'd3    :baud_cnt_max <= 32'd2170    ;//2170.1388888888888888888888888889
        	    4'd4    :baud_cnt_max <= 32'd1085    ;//1085.0694444444444444444444444444
        	    4'd5    :baud_cnt_max <= 32'd125     ;//125
        	    4'd6    :baud_cnt_max <= 32'd62      ;//62.5
        	    4'd7    :baud_cnt_max <= 32'd41      ;//41.666666666666666666666666666667
        	    4'd8    :baud_cnt_max <= 32'd31      ;//31.25
        	    4'd9    :baud_cnt_max <= 32'd25      ;//25
        	    4'd10   :baud_cnt_max <= 32'd135     ;//135.63368055555555555555555555556
        	    4'd11   :baud_cnt_max <= 32'd542     ;//542.53472222222222222222222222222
                4'd12   :baud_cnt_max <= 32'd271     ;//
        	    default :baud_cnt_max <= baud_cnt_max;//
        	endcase
		else 
			baud_cnt_max <= baud_cnt_max;

	always @(posedge clock_125)
		if(rst_125)  
			pari_reg <= 1'b0;	
		else if (pi_flag == 1'b1) 
			pari_reg <= pi_data[0] + pi_data[1] + pi_data[2] + pi_data[3] + pi_data[4] + pi_data[5] + pi_data[6] + pi_data[7];
		else 
			pari_reg <= pari_reg;	

	//寄存器寄存奇偶校验位设置
	always @(posedge clock_125)
		if(rst_125) 
			pari_ce_reg <= 'd0;
		else if(uart_tx_state == IDLE)
			pari_ce_reg <= uart_cr[3];
		else 
			pari_ce_reg <= pari_ce_reg;

	always @(posedge clock_125)
		if(rst_125) 
			pari_se_reg <= 'd0;
		else if(uart_tx_state == IDLE)
			pari_se_reg <= uart_cr[2];
		else 
			pari_se_reg <= pari_se_reg;


	always @(posedge clock_125)
		if(rst_125)  
			cnt_baud <= 'd0;
		else if(cnt_baud == baud_cnt_max - 1'b1) 
			cnt_baud <= 'd0;
		else if(uart_tx_state != IDLE) 
			cnt_baud <= cnt_baud + 1'b1;
		else if(uart_tx_state == IDLE) 
			cnt_baud <= 'd0;
		else 
			cnt_baud <= cnt_baud;

//	always @(posedge clock_125)
//		if(rst_125) 
//			bit_flag <= 1'b0;	
//		else if (uart_tx_state == SEND && cnt_baud == baud_cnt_max - 2'd2) 
//			bit_flag <= 1'b1;
//		else 
//			bit_flag <= 1'b0;	

	always @(posedge clock_125)
		if(rst_125) 
			bit_cnt <= 4'd0;
		else if (uart_tx_state != SEND) 
			bit_cnt <= 4'd0;
//		else if(bit_flag == 1'b1) 
//			bit_cnt <= bit_cnt + 4'd1;
		else if(cnt_baud == baud_cnt_max - 1'd1) 
			bit_cnt <= bit_cnt + 4'd1;
	
	always @(posedge clock_125)
		if(rst_125) 
			uart_tx_state <= IDLE;
		else 
			uart_tx_state <= uart_tx_nstate;

	always @(*) 
		case(uart_tx_state)
			IDLE:
				if(pi_flag && uart_te)
					uart_tx_nstate = START_BIT;
				else 
					uart_tx_nstate = IDLE;
			START_BIT:
				if(cnt_baud == baud_cnt_max - 1'b1)
					uart_tx_nstate = SEND;
				else 
					uart_tx_nstate = START_BIT;	
			SEND:
				if(cnt_baud == baud_cnt_max - 1'b1 && bit_cnt == bit_cnt_max - 1'b1 && pari_ce_reg == 'b0)
					uart_tx_nstate = STOP_BIT1;
				else if(cnt_baud == baud_cnt_max - 1'b1 && bit_cnt == bit_cnt_max - 1'b1)
						uart_tx_nstate = PARITY;
				else 
					uart_tx_nstate = SEND;
			PARITY:
				if(cnt_baud == baud_cnt_max - 1'b1)
					uart_tx_nstate = STOP_BIT1;
				else 
					uart_tx_nstate = PARITY;
			STOP_BIT1:
				if(cnt_baud == baud_cnt_max - 1'b1 && stopbit_reg == 1'b0)//1
					uart_tx_nstate = FINISH;
				else if (cnt_baud == baud_cnt_max - 1'b1 && stopbit_reg == 1'b1) //2
					uart_tx_nstate = STOP_BIT2;
				else 
					uart_tx_nstate = STOP_BIT1;
			STOP_BIT2:
				if(cnt_baud == baud_cnt_max - 1'b1)
					uart_tx_nstate = FINISH;
				else 
					uart_tx_nstate = STOP_BIT2;
			FINISH:
				uart_tx_nstate = IDLE;
			default:
				uart_tx_nstate = IDLE;
		endcase
	
	//产生发送波形
	always @(posedge clock_125)
		if(rst_125) 
			tx <= 1'b1;
		else if (uart_tx_state == START_BIT)
			tx <= 1'b0;
		else if (uart_tx_state == IDLE) 
			tx <= 1'b1;
		else if (uart_tx_state == PARITY && pari_se_reg == 1'b1) 
			tx <= oddpari;
		else if (uart_tx_state == PARITY && pari_se_reg == 1'b0) 
			tx <= evenpari;
		else if (uart_tx_state == SEND) 
			tx <= data_reg[bit_cnt];
		else if (uart_tx_state == STOP_BIT1 || uart_tx_state == STOP_BIT2) 
			tx <= 1'b1;
		else 
			tx <= tx;

	//产生发送完成标志
	always @(posedge clock_125)
		if(rst_125) 
			txend <= 1'b0;	
		else if (uart_tx_state == FINISH) 
			txend <= 1'b1;
		else 
			txend <= 1'b0;	

endmodule
