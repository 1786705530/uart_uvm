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
    input               clock_125           ,//AXI时钟125M
    input               rst_n_125           ,//复位
    input               rx                  ,//UART RX脚
    
    input      [11:0]   uart_cr             ,

    output reg  [7:0]   po_data             ,//接收到的数据
    output reg          po_flag             ,//接收到数据的标志

    output              ne_flag             ,//噪声错误标志
    output              fe_flag             ,//帧错误标志
    output              pe_flag             //奇偶校验错误标志
    
);
    reg [3:0]       rx_fedge_reg            ;//接收下降沿判断标志
    reg             rx_fedge                ;//接收下降沿
    reg [31:0]      cnt_baud                ;//波特率计数器

    reg [3:0]       bit_cnt                 ;//bit计数器
    reg             pari_ce_reg             ;//
    reg             pari_se_reg             ;//

    reg             pari_reg                ;//奇偶计算原始值
    wire            oddpari                 ;//奇校验计算值
    wire            evenpari                ;//偶校验计算值
    reg  [31:0]     baud_cnt_max            ;//
    wire [31:0]     baud_cnt_max_half       ;//
    reg             stopbit_reg             ;//
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

    reg             rst_reg1                ;
    reg             rst_reg2                ;
    reg             rst_reg3                ;
    reg             rst_reg4                ;
    reg             rst_125                 ;
    reg [31:0]      rx_width_cnt            ;

    wire            uart_re                 ;


    typedef enum  {WIDLE, IDLE, START_BIT, RECEIVE, PARITY, STOP_BIT1, STOP_BIT2, JUDGE, FINISH} state_enum;
    state_enum uart_rx_state,uart_rx_nstate;

    assign uart_re = uart_cr[0]             ;


    localparam      bit_cnt_max = 4'd8      ;

    assign oddpari  = !pari_reg             ; 
    assign evenpari =  pari_reg             ; 
    assign ne_flag  =  noise_error_redge    ; 
    assign fe_flag  =  frame_error_redge    ; 
    assign pe_flag  =  parity_error_redge   ; 

    always @(negedge rst_n_125,posedge clock_125) 
        if (!rst_n_125) 
            begin
                rst_125     <= 1'b1;
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
                rst_125     <= rst_reg4;
            end

    //用于判断下降沿
    always @(posedge clock_125)
        if(rst_125) 
            rx_fedge_reg <= 'd0;
        else 
            rx_fedge_reg <= {rx_fedge_reg[2:0],rx};
    
    //用于判断下降沿
    always @(posedge clock_125)
        if(rst_125)  
            rx_fedge <= 'd0;
        else if(rx_fedge_reg[3:1] == 3'b111 && rx_fedge_reg[0] == 1'b0) 
            rx_fedge <= 1'b1;
        else 
            rx_fedge <= 'd0;
    

    always @(posedge clock_125)
        if(rst_125) 
            baud_cnt_max <= 'd0;
        else if(uart_rx_state == IDLE)
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

    assign baud_cnt_max_half = baud_cnt_max >> 32'b1;

    //寄存器寄存奇偶校验位设置
    always @(posedge clock_125)
        if(rst_125) 
            pari_ce_reg <= 'd0;
        else if(uart_rx_state == IDLE)
            pari_ce_reg <= uart_cr[3];
        else 
            pari_ce_reg <= pari_ce_reg;

    always @(posedge clock_125)
        if(rst_125) 
            pari_se_reg <= 'd0;
        else if(uart_rx_state == IDLE)
            pari_se_reg <= uart_cr[2];
        else 
            pari_se_reg <= pari_se_reg;

    //寄存器寄存奇偶校验位设置
    always @(posedge clock_125)
        if(rst_125) 
            stopbit_reg <= 'd0;
        else if(uart_rx_state == IDLE)
            stopbit_reg <= uart_cr[5];
        else 
            stopbit_reg <= stopbit_reg;

    always @(posedge clock_125)
        if(rst_125) 
            cnt_baud <= 'd0;
        else if(uart_rx_state == IDLE || uart_rx_state == WIDLE) 
            cnt_baud <= 'd0;
        else if(cnt_baud == baud_cnt_max - 1'b1) 
            cnt_baud <= 'd0;
        else 
            cnt_baud <= cnt_baud + 1'b1;

    //bit计数器
    always @(posedge clock_125)
        if(rst_125) 
            bit_cnt <= 4'd0;
        else if(uart_rx_state != RECEIVE) 
            bit_cnt <= 4'd0;
        else if(cnt_baud == baud_cnt_max - 1'b1 && bit_cnt == bit_cnt_max - 1'b1)
            bit_cnt <= 4'd0;
        else if(cnt_baud == baud_cnt_max - 1'd1) 
            bit_cnt <= bit_cnt + 4'd1;

    //输出接收到的数据
    always @(posedge clock_125)
        if(rst_125) 
            po_data <= 'd0;
        else if (uart_rx_state == IDLE) 
            po_data <= 'd0;
        else if(uart_rx_state == RECEIVE && cnt_baud == baud_cnt_max_half) 
            case(bit_cnt)
                4'd0:po_data[0] <= rx;
                4'd1:po_data[1] <= rx;
                4'd2:po_data[2] <= rx;
                4'd3:po_data[3] <= rx;
                4'd4:po_data[4] <= rx;
                4'd5:po_data[5] <= rx;
                4'd6:po_data[6] <= rx;
                4'd7:po_data[7] <= rx;
                default:po_data <= po_data;
            endcase
        else 
            po_data <= po_data;

    //奇偶校验原始值计算
    always @(posedge clock_125)
        if(rst_125) 
            pari_reg <= 1'b0; 
        else if (uart_rx_state == PARITY) 
            pari_reg <= po_data[0]+ po_data[1] + po_data[2] + po_data[3] + po_data[4] + po_data[5] + po_data[6] + po_data[7];
        else 
            pari_reg <= pari_reg; 

    
    always @(posedge clock_125)
        if(rst_125) 
            uart_rx_state <= WIDLE;
        else 
            uart_rx_state <= uart_rx_nstate;

    always @(*) 
        case(uart_rx_state) 
            WIDLE:
                if(idle_cnt == (baud_cnt_max<<3) && uart_re == 1'b1)
                    uart_rx_nstate = IDLE;
                else 
                    uart_rx_nstate = WIDLE;
            IDLE:
                if(uart_re == 1'b0)
                    uart_rx_nstate = WIDLE;
                else if(rx_fedge)
                    uart_rx_nstate = START_BIT;
                else 
                    uart_rx_nstate = IDLE;
            START_BIT:
                if(cnt_baud == baud_cnt_max - 1'b1)
                    uart_rx_nstate = RECEIVE;
                else 
                    uart_rx_nstate = START_BIT;
            RECEIVE:
                if(cnt_baud == baud_cnt_max - 1'b1 && bit_cnt == bit_cnt_max - 1'b1)
                    if (pari_ce_reg == 'b0) 
                        uart_rx_nstate = STOP_BIT1;
                    else 
                        uart_rx_nstate = PARITY;
                else 
                    uart_rx_nstate = RECEIVE;   
            PARITY:
                if (cnt_baud == baud_cnt_max - 1'b1) 
                    uart_rx_nstate = STOP_BIT1;
                else 
                    uart_rx_nstate = PARITY;
            STOP_BIT1:
                if(cnt_baud == baud_cnt_max - 1'b1 && stopbit_reg == 1'b1)//1
                    uart_rx_nstate = STOP_BIT2;
                else if(cnt_baud == baud_cnt_max_half && stopbit_reg == 1'b0) //2
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
    
    //噪声错误标志
    always @(posedge clock_125)
        if(rst_125) 
            noise_error_flag <= 'd0;
        else if (uart_rx_state == IDLE) 
            noise_error_flag <= 'd0;
        else if ((uart_rx_state == START_BIT || uart_rx_state == RECEIVE) && rx_width_cnt <= baud_cnt_max_half && rx_fedge_reg[0] != rx) 
            noise_error_flag <= 1'b1;
        else 
            noise_error_flag <= noise_error_flag;
    
    always @(posedge clock_125)
        if(rst_125) 
            noise_error_reg <= 'd0;
        else 
            noise_error_reg <= {noise_error_reg[0],noise_error_flag};
    
    always @(posedge clock_125)
        if(rst_125) 
            noise_error_redge <= 'd0;
        else if (noise_error_reg == 2'd1) 
            noise_error_redge <= 1'b1;
        else 
            noise_error_redge <= 'd0;

    //奇偶校验错误标志
    always @(posedge clock_125)
        if(rst_125) 
            parity_error_flag <= 'd0;
        else if (uart_rx_state == IDLE) 
            parity_error_flag <= 'd0;
        else if (uart_rx_state == PARITY && cnt_baud == baud_cnt_max_half - 1'b1 && oddpari != rx && pari_se_reg == 1'b1 ) 
            parity_error_flag <= 1'b1;
        else if (uart_rx_state == PARITY && cnt_baud == baud_cnt_max_half - 1'b1 && evenpari != rx && pari_se_reg == 1'b0 ) 
            parity_error_flag <= 1'b1;
        else 
            parity_error_flag <= parity_error_flag;
    
    always @(posedge clock_125)
        if(rst_125) 
            parity_error_reg <= 'd0;
        else 
            parity_error_reg <= {parity_error_reg[0],parity_error_flag};
    
    always @(posedge clock_125)
        if(rst_125) 
            parity_error_redge <= 'd0;
        else if (parity_error_reg == 2'd1) 
            parity_error_redge <= 1'b1;
        else 
            parity_error_redge <= 'd0;

    //帧错误标志
    always @(posedge clock_125)
        if(rst_125) 
            frame_error_flag <= 'd0;
        else if (uart_rx_state == IDLE) 
            frame_error_flag <= 'd0;
        else if (uart_rx_state == STOP_BIT1 && cnt_baud == baud_cnt_max_half && rx != 1'b1) 
            frame_error_flag <= 1'b1;
        else if (uart_rx_state == STOP_BIT2 && cnt_baud == baud_cnt_max_half && rx != 1'b1) 
            frame_error_flag <= 1'b1;
        else 
            frame_error_flag <= frame_error_flag;
    
    always @(posedge clock_125)
        if(rst_125) 
            frame_error_reg <= 'd0;
        else 
            frame_error_reg <= {frame_error_reg[0],frame_error_flag};
    
    always @(posedge clock_125)
        if(rst_125) 
            frame_error_redge <= 'd0;
        else if (frame_error_reg == 2'd1) 
            frame_error_redge <= 1'b1;
        else 
            frame_error_redge <= 'd0;

    
    always @(posedge clock_125)
        if(rst_125) 
            po_flag <= 'd0;
        else if (uart_rx_state == FINISH) 
            po_flag <= 1'b1;
        else 
            po_flag <= 'd0;
    
    always @(posedge clock_125) 
        if (rst_125) 
            idle_cnt <= 'd0;
        else if (uart_rx_state == WIDLE && uart_re == 1'b1 && rx == 1'b1 && baud_cnt_max != 'b0) 
            idle_cnt <= idle_cnt + 1'b1;
        else 
            idle_cnt <= 'd0;
    
    always @(posedge clock_125)
        if(rst_125) 
            rx_width_cnt <= 'd0;
        else if (uart_rx_state != START_BIT && uart_rx_state != RECEIVE) 
            rx_width_cnt <= 'd0;
        else if (rx_fedge_reg[0]!=rx) 
            rx_width_cnt <= 'd0;
        else 
            rx_width_cnt<=rx_width_cnt+1'b1;

endmodule
