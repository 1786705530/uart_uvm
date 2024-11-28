`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: BoundaryAI
// Engineer: Hzh
// Create Date: 2023_7_24
// Module Name: uart_rx
// Description: uart_rx
// Revision: uart_rx
//////////////////////////////////////////////////////////////////////////////////

module uart_rx(
    input               clk_i               ,//AXI时钟125M
    input               rstn_i              ,//复位

    input               uart_re             ,//UART RE脚
    input               rx                  ,//UART RX脚
    input       [ 3:0]  baud                ,//波特率
    
    output reg  [7:0]   po_data             ,//接收到的数据
    output reg          po_flag             ,//接收到数据的标志
    input       [ 1:0]  paribit             ,//奇偶校验位控制 00 无奇偶校验 01 奇校验 10 偶校验
    input               stopbit             ,//停止位 1 两位停止位 0 一位停止位
    input       [31:0]  baud_cnt_max        ,//当前波特率下一个bit的时钟周期个数
    input       [31:0]  baud_cnt_max_half   ,//当前波特率下一个bit的时钟周期个数的一半
    output reg          ne_flag             ,//噪声错误标志
    output reg          fe_flag             ,//帧错误标志
    output reg          pe_flag             ,//奇偶校验错误标志
    
);
//================================================================
    reg [3:0]       rx_fedge_reg            ;//接收下降沿判断标志
    reg             rx_fedge                ;//接收下降沿
//
    //
    reg             bit_judge               ;//十六倍采样bit值判断寄存器
//
    reg [2:0]       rx_reg                  ;//RX引脚移位寄存器
//
//
    reg [31:0]      cnt_baud                ;//波特率计数器
    reg             bit_flag                ;//接收到1bit标志
    reg             bit_judege_flag         ;//bit值判断标志
    reg [3:0]       bit_cnt                 ;//bit计数器
    reg [3:0]       bit_cnt_max             ;//当前UART格式bit个数
    reg [1:0]       paribit_reg             ;//奇偶校验bit锁存器，监测到下降沿时，自动锁定当前接收格式
    //
//
    reg             pari_reg                ;//奇偶计算原始值
    reg             oddpari_reg             ;//奇校验计算值
    reg             evenpari_reg            ;//偶校验计算值
    reg [31:0]      baud_cnt_max_reg        ;//当前波特率下单bit时钟周期数锁存器，监测到下降沿时，自动锁定当前接收格式
//
//
    reg [7:0]       uart_rx_nstate          ;//下一个状态寄存器
    reg [7:0]       uart_rx_state           ;//状态寄存器
//
//
    reg             noise_error_flag        ;//噪声错误标志，持续
    reg [1:0]       noise_error_reg         ;//用于噪声错误标志判断
    reg             noise_error_redge       ;//用于噪声错误标志判断
    reg             parity_error_flag       ;//奇偶校验错误标志，持续
    reg [1:0]       parity_error_reg        ;//用于奇偶校验错误标志判断
    reg             parity_error_redge      ;//用于奇偶校验错误标志判断
    reg             frame_error_flag        ;//帧错误标志，持续
    reg [1:0]       frame_error_reg         ;//用于帧错误标志判断
    reg             frame_error_redge       ;//用于帧错误标志判断


    reg [31:0]      idle_cnt                ;

    reg [1:0]       rx_reg_tmp              ;
    reg             rx_real                 ;
//================================================================
//state machine
    localparam IDLE         = 8'd0          ;//空闲，等待RX下降沿
    localparam START_BIT    = 8'd1          ;//起始位
    localparam RECEIVE      = 8'd3          ;//接收数据
    localparam STOP_BIT1    = 8'd4          ;//第一个停止位
    localparam STOP_BIT2    = 8'd5          ;//第二个停止位
    localparam JUDGE        = 8'd6          ;//判断
    localparam FINISH       = 8'd7          ;//结束
    localparam PARITY       = 8'd8          ;//奇偶校验
    localparam WIDLE        = 8'd9          ;//奇偶校验
//
//================================================================

(* keep = "true" *)    reg                                 rst_reg1                                ;
(* keep = "true" *)    reg                                 rst_reg2                                ;
(* keep = "true" *)    reg                                 rst_reg3                                ;
(* keep = "true" *)    reg                                 rst_reg4                                ;
(* keep = "true" *)    reg                                 rst                                     ;


typedef enum  {IDLE, START_BIT, RECEIVE, STOP_BIT1, STOP_BIT2, JUDGE, FINISH, PARITY, WIDLE} state_enum;
state_enum uart_rx_state,uart_rx_nstate;


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

always @(posedge clk_i) 
begin
    if (rst) 
        begin
            rx_real <= 'd1;
        end
    else if(rx_reg_tmp == 2'b11)
        begin
            rx_real <= 'b1;
        end
    else if(rx_reg_tmp == 2'b00)
        begin
            rx_real <= 'b0;
        end
end

always @(posedge clk_i) 
begin
    if (rst) 
        begin
            rx_reg_tmp <= 'b11;
        end
    else
        begin
            rx_reg_tmp <= {rx_reg_tmp[0],rx};
        end
end
//用于判断下降沿
always @(posedge clk_i)
begin
    if(rst) 
        begin
            rx_fedge_reg <= 'd0;
        end
    else 
        begin
            rx_fedge_reg <= {rx_fedge_reg[2:0],rx_real};
        end
end
//用于判断下降沿
always @(posedge clk_i)
begin
    if(rst)  
        begin
            rx_fedge <= 'd0;
        end
    else if(rx_fedge_reg[3:1] == 3'b111 && rx_fedge_reg[0] == 1'b0) 
        begin
            rx_fedge <= 1'b1;
        end
    else 
        begin
            rx_fedge <= 'd0;
        end
end

always @(posedge clk_i)
begin
    if(rst) 
        begin
            bit_judge <= 'd0;
        end
    else if(rx_real==1'd1) 
        begin
            bit_judge <= 'd1;
        end
    else 
        begin
            bit_judge <= 'd0;
        end
end




always @(posedge clk_i)
begin
    if(rst) 
        begin
            bit_cnt_max<='d0;
        end
    else 
        begin
            bit_cnt_max<='d8;
        end
end

always @(posedge clk_i)
begin
    if(rst) 
        begin
            baud_cnt_max_reg<='d0;
        end
    else 
        begin
            baud_cnt_max_reg<=baud_cnt_max;
        end
end
//波特率计数器
always @(posedge clk_i)
begin
    if(rst) 
        begin
            cnt_baud <= 'd0;
        end
    else if(uart_rx_state != IDLE && cnt_baud == baud_cnt_max_reg -1'b1) 
        begin
            cnt_baud <= 'd0;
        end
    else if(uart_rx_state == IDLE) 
        begin
            cnt_baud <= 'd0;
        end
    else if(uart_rx_state != IDLE && uart_rx_state != WIDLE) 
        begin
            cnt_baud <= cnt_baud + 1'b1;
        end
    else 
        begin
            cnt_baud <= cnt_baud;
        end
end
//采样1bit成功标志
always @(posedge clk_i)
begin
    if(rst) 
        begin
            bit_flag<=1'b0; 
        end
    else if (uart_rx_state == RECEIVE && cnt_baud==baud_cnt_max_reg -2'd2) 
        begin
            bit_flag<=1'b1;
        end
    else 
        begin
            bit_flag<=1'b0; 
        end
end
//bit计数器
always @(posedge clk_i)
begin
    if(rst) 
        begin
            bit_cnt<=4'd0;
        end
    else if(uart_rx_state == IDLE) 
        begin
            bit_cnt<=4'd0;
        end
    else if (cnt_baud == baud_cnt_max_reg - 1'b1 && bit_cnt == bit_cnt_max - 1'b1) 
        begin
            bit_cnt<=4'd0;
        end
    else if(bit_flag==1'b1) 
        begin
            bit_cnt<=bit_cnt+4'd1;
        end
end
//bit判断标志
always @(posedge clk_i)
begin
    if(rst) 
        begin
            bit_judege_flag<=1'b0;  
        end
    else if (uart_rx_state == RECEIVE && cnt_baud==baud_cnt_max_half) 
        begin
            bit_judege_flag<=1'b1;
        end
    else 
        begin
            bit_judege_flag<=1'b0;  
        end
end
//输出接收到的数据
always @(posedge clk_i)
begin
    if(rst) 
        begin
            po_data <= 'd0;
        end
    else if (uart_rx_state == IDLE) 
        begin
            po_data <= 'd0;
        end
    else if(bit_judege_flag==1'b1) 
        begin
            case(bit_cnt)
                4'd0:po_data[0] <= bit_judge;
                4'd1:po_data[1] <= bit_judge;
                4'd2:po_data[2] <= bit_judge;
                4'd3:po_data[3] <= bit_judge;
                4'd4:po_data[4] <= bit_judge;
                4'd5:po_data[5] <= bit_judge;
                4'd6:po_data[6] <= bit_judge;
                4'd7:po_data[7] <= bit_judge;
                default:po_data <= po_data;
            endcase
        end
    else 
        begin
            po_data <= po_data;
        end
end
//寄存器寄存奇偶校验位设置
always @(posedge clk_i)
begin
    if(rst) 
        begin
            paribit_reg<='d0;
        end
    else 
        begin
            paribit_reg<=paribit;
        end
end
//奇偶校验原始值计算
always @(posedge clk_i)
begin
    if(rst) 
        begin
            pari_reg<=1'b0; 
        end
    else if (uart_rx_state == PARITY) 
        begin
            pari_reg<= po_data[0]+ po_data[1]+ po_data[2]+ po_data[3]+ po_data[4]+ po_data[5]+ po_data[6]+ po_data[7];
        end
    else 
        begin
            pari_reg<=pari_reg; 
        end
end

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

always @(posedge clk_i)
begin
    if(rst) 
        begin
            uart_rx_state<=WIDLE;
        end
    else 
        begin
            uart_rx_state<=uart_rx_nstate;
        end
end
//
always @(*) 
begin
    uart_rx_nstate = WIDLE;
    case(uart_rx_state) 
        WIDLE:
            if(uart_rx_state == WIDLE && idle_cnt == (baud_cnt_max_reg<<3) && uart_re == 1'b1)
                uart_rx_nstate = IDLE;
            else 
                uart_rx_nstate = WIDLE;
        IDLE:
            if(rx_fedge)
                uart_rx_nstate = START_BIT;
            else if(uart_re == 1'b0)
                uart_rx_nstate = WIDLE;
            else 
                uart_rx_nstate = IDLE;
        START_BIT:
            if(cnt_baud == baud_cnt_max_reg - 1'b1)
                uart_rx_nstate = RECEIVE;
            else 
                uart_rx_nstate = START_BIT;
        RECEIVE:
            if(cnt_baud == baud_cnt_max_reg - 1'b1 && bit_cnt == bit_cnt_max - 1'b1)begin
                if (paribit_reg == 2'b00) 
                    uart_rx_nstate = STOP_BIT1;
                else 
                    uart_rx_nstate = PARITY;
            end
            else 
                uart_rx_nstate = RECEIVE;   
        PARITY:
            if (cnt_baud == baud_cnt_max_reg - 1'b1) 
                uart_rx_nstate = STOP_BIT1;
            else 
                uart_rx_nstate = PARITY;
        STOP_BIT1:
            if(cnt_baud == baud_cnt_max_reg - 1'b1 && stopbit == 1'b1)//1
                uart_rx_nstate = STOP_BIT2;
            else if(cnt_baud == baud_cnt_max_half && stopbit == 1'b0) //2
                uart_rx_nstate = JUDGE;
            else 
                uart_rx_nstate = STOP_BIT1;
        STOP_BIT2:
            if(cnt_baud == baud_cnt_max_half)//1
                uart_rx_nstate = JUDGE;
            else 
                uart_rx_nstate = STOP_BIT2;
        JUDGE:
            if(noise_error_flag == 1'b1 || frame_error_flag == 1'b1 || parity_error_flag == 1'b1)//1
                uart_rx_nstate = IDLE;
            else 
                uart_rx_nstate = FINISH;
        FINISH:
            uart_rx_nstate = IDLE;
        default:
            uart_rx_nstate = IDLE;
    endcase
end


 

//噪声错误标志
always @(posedge clk_i)
begin
    if(rst) 
        begin
            noise_error_flag<='d0;
        end
    else if (uart_rx_state == IDLE) 
        begin
            noise_error_flag<='d0;
        end
    else if (uart_rx_state == START_BIT || uart_rx_state != RECEIVE && rx_width_cnt >= baud_cnt_max_half) 
        begin
            noise_error_flag<=1'b1;
        end
    else 
        begin
            noise_error_flag<=noise_error_flag;
        end
end

always @(posedge clk_i)
begin
    if(rst) 
        begin
            noise_error_reg<='d0;
        end
    else 
        begin
            noise_error_reg<={noise_error_reg[0],noise_error_flag};
        end
end

always @(posedge clk_i)
begin
    if(rst) 
        begin
            noise_error_redge<='d0;
        end
    else if (noise_error_reg == 2'd1) 
        begin
            noise_error_redge<=1'b1;
        end
    else 
        begin
            noise_error_redge<='d0;
        end
end
//奇偶校验错误标志
always @(posedge clk_i)
begin
    if(rst) 
        begin
            parity_error_flag<='d0;
        end
    else if (uart_rx_state == IDLE) 
        begin
            parity_error_flag<='d0;
        end
    else if (uart_rx_state == PARITY && cnt_baud == baud_cnt_max_reg - 1'b1 && oddpari_reg != bit_judge && paribit_reg == 2'b01 ) 
        begin
            parity_error_flag<=1'b1;
        end
    else if (uart_rx_state == PARITY && cnt_baud == baud_cnt_max_reg - 1'b1 && evenpari_reg != bit_judge && paribit_reg == 2'b10 ) 
        begin
            parity_error_flag<=1'b1;
        end
    else 
        begin
            parity_error_flag<=parity_error_flag;
        end
end

always @(posedge clk_i)
begin
    if(rst) 
        begin
            parity_error_reg<='d0;
        end
    else 
        begin
            parity_error_reg<={parity_error_reg[0],parity_error_flag};
        end
end

always @(posedge clk_i)
begin
    if(rst) 
        begin
            parity_error_redge<='d0;
        end
    else if (parity_error_reg == 2'd1) 
        begin
            parity_error_redge<=1'b1;
        end
    else 
        begin
            parity_error_redge<='d0;
        end
end
//帧错误标志
always @(posedge clk_i)
begin
    if(rst) 
        begin
            frame_error_flag<='d0;
        end
    else if (uart_rx_state == IDLE) 
        begin
            frame_error_flag<='d0;
        end
    else if (uart_rx_state == STOP_BIT1 && cnt_baud == baud_cnt_max_half && bit_judge != 1'b1) 
        begin
            frame_error_flag<=1'b1;
        end
    else if (uart_rx_state == STOP_BIT2 && cnt_baud == baud_cnt_max_half && bit_judge != 1'b1) 
        begin
            frame_error_flag<=1'b1;
        end
    else 
        begin
            frame_error_flag<=frame_error_flag;
        end
end

always @(posedge clk_i)
begin
    if(rst) 
        begin
            frame_error_reg<='d0;
        end
    else 
        begin
            frame_error_reg<={frame_error_reg[0],frame_error_flag};
        end
end

always @(posedge clk_i)
begin
    if(rst) 
        begin
            frame_error_redge<='d0;
        end
    else if (frame_error_reg == 2'd1) 
        begin
            frame_error_redge<=1'b1;
        end
    else 
        begin
            frame_error_redge<='d0;
        end
end

always @(posedge clk_i)
begin
    if(rst) 
        begin
            ne_flag<='d0;
        end
    else 
        begin
            ne_flag<=noise_error_redge;
        end
end

always @(posedge clk_i)
begin
    if(rst)  
        begin
            fe_flag<='d0;
        end
    else 
        begin
            fe_flag<=frame_error_redge;
        end
end

always @(posedge clk_i)
begin
    if(rst) 
        begin
            pe_flag<='d0;
        end
    else 
        begin
            pe_flag<=parity_error_redge;
        end
end

always @(posedge clk_i)
begin
    if(rst) 
        begin
            po_flag<='d0;
        end
    else if (uart_rx_state == FINISH) 
        begin
            po_flag<=1'b1;
        end
    else 
        begin
            po_flag<='d0;
        end
end

always @(posedge clk_i) 
begin
    if (rst) 
        begin
            idle_cnt<='d0;
        end
    else if (uart_rx_state == WIDLE && uart_re == 1'b1 && rx_real == 1'b1) 
        begin
            idle_cnt<= idle_cnt + 1'b1;
        end
    else 
        begin
            idle_cnt<='d0;
        end
end


    reg [31:0]      rx_width_cnt                ;

always @(posedge clk_i)
begin
    if(rst) 
        begin
            rx_width_cnt<='d0;
        end
    else if (uart_rx_state != START_BIT || uart_rx_state != RECEIVE) 
        begin
            rx_width_cnt<='d0;
        end
    else if (rx_fedge_reg[0]!=rx_real) 
        begin
            rx_width_cnt<='d0;
        end
    else 
        begin
            rx_width_cnt<=rx_width_cnt+1'b1;
        end
end

endmodule
