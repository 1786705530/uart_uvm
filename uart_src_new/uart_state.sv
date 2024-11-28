module uart_state (
    input                               clk_i                                   ,
    input                               rstn_i                                  ,//
//
    input       [ 3:0]                  uart_brr_i                              ,//波特率设置值
    input                               uart_ps_i                               ,//奇偶校验位选择
    input                               uart_sb_i                               ,//停止位设置值
    input                               uart_pce_i                              ,//奇偶校验位使能
//
    output                              uart_rxvld_o                            ,//
    output     [ 7:0]                   uart_rxdata_o                           ,//
    // data//
    input                               uart_txfifo_empty_i                     ,//
    output                              uart_txfifo_rden_o                      ,//
    input      [31:0]                   uart_txfifo_data_i                      ,//
//
    output                              uart_tx_end_o                           ,//
///////////////////
    output                              uart_paribit                            ,
    output                              uart_stopbit                            ,
    output                              uart_txreq                              ,
    output      [ 7:0]                  uart_txdata                             ,
    input                               uart_txend                              ,//


    input       [ 7:0]                  uart_rxdata                             ,
    input                               uart_rxvld                              ,//
    output      [ 3:0]                  uart_brr                                ,
    output  reg [31:0]                  baud_cnt_max                            ,//
    output  reg [31:0]                  baud_cnt_max_half                       ,//

    output  reg                         en_ctrl                                  //


);

reg             [ 3:0]                  uart_nstate                             ;//串口控制状态机下一个状态
reg             [ 3:0]                  uart_cstate                             ;//串口控制状态机当前状态
reg                                     txfifo_rden                             ;//发送FIFO读取数据标志位
//
reg                                     cnt_clr                                 ;//延时计数器清空标志
reg             [31:0]                  delay_cnt                               ;//延时计数器
reg             [31:0]                  txfifo_rddata                           ;//发送FIFO剩余数据量
//
//

(* keep = "true" *)    reg                                 rst_reg1                                ;
(* keep = "true" *)    reg                                 rst_reg2                                ;
(* keep = "true" *)    reg                                 rst_reg3                                ;
(* keep = "true" *)    reg                                 rst_reg4                                ;
(* keep = "true" *)    reg                                 rst                                     ;


typedef enum  {W1MS, IDLE, RDFIFO, DISRDFIFO, WAITSEND1, SEND1, WAITSEND2, SEND2, WAITSEND3, SEND3, WAITSEND4, SEND4} state_enum;
state_enum uart_cstate,uart_nstate;

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

    assign uart_paribit         = (uart_pce_i == 1'b0) ? 2'b00
                                 : uart_ps_i ? 2'b01 : 2'b10        ;
        
    assign uart_stopbit         = uart_sb_i                         ;
    assign uart_txfifo_rden_o   = txfifo_rden                       ;
    assign uart_rxvld_o         = uart_rxvld                        ;
    assign uart_rxdata_o        = uart_rxdata                       ;
    assign uart_tx_end_o        = uart_txend                        ;


always @(posedge clk_i)
begin
    if(rst) 
        begin
            baud_cnt_max <= 'd0;
        end
        else 
            begin
                case(uart_brr)
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
                    default :baud_cnt_max <= baud_cnt_max;//
                endcase
            end
end
        
always @(posedge clk_i)
begin
    if(rst) 
            begin
                baud_cnt_max_half <= 'd0;
            end
        else 
            begin
                baud_cnt_max_half <= {1'b0,baud_cnt_max[31:1]};
            end
end

always @(posedge clk_i)
begin
    if(rst) 
            begin
                uart_brr <= 'd0;
            end
        else 
            begin
                uart_brr <= uart_brr_i;
            end
end
    
always @(posedge clk_i)
begin
    if(rst) 
        begin
            delay_cnt <= 'd0;
        end
    else if (cnt_clr) 
        begin
            delay_cnt <= 16'd0;
        end
    else 
        begin
            delay_cnt <= delay_cnt + 1'b1;
        end
end

always @(posedge clk_i)
begin
    if(rst) 
            begin
                uart_cstate <= W1MS;
            end
        else 
            begin
                uart_cstate <= uart_nstate;
            end
end


//串口发送控制寄存器
    always @(*)
    begin
        uart_nstate = W1MS;
        case (uart_cstate)                       //上点后1MS才进入等待FIFO空满的状态
        W1MS:
        begin
            if (delay_cnt == 32'hffff)
                begin
                    uart_nstate = IDLE;
                end
            else 
                begin
                    uart_nstate = W1MS;
                end
        end
        
        IDLE:
        begin                                   //一直在此状态等待FIFO不为空，然后读取FIFO
            if (uart_txfifo_empty_i == 1'b0)
                begin
                    uart_nstate = RDFIFO;
                end
            else 
                begin
                    uart_nstate = IDLE;
                end
        end
            
        RDFIFO:
        begin
            uart_nstate = DISRDFIFO;
        end
            
        DISRDFIFO:
        begin
            uart_nstate = WAITSEND1;
        end
        
        WAITSEND1:
        begin
            if (delay_cnt == 16'd30) 
                begin
                    uart_nstate = SEND1;    
                end
            else 
                begin
                    uart_nstate = WAITSEND1;
                end
        end

        SEND1:
        begin
            if (uart_txend) 
                begin
                    uart_nstate = WAITSEND2;    
                end
            else 
                begin
                    uart_nstate = SEND1;
                end
        end
         
        WAITSEND2:
        begin
            if (delay_cnt == 16'd20) 
                begin
                    uart_nstate = SEND2;    
                end
            else 
                begin
                    uart_nstate = WAITSEND2;
                end
        end

        SEND2:
        begin
            if (uart_txend) 
                begin
                    uart_nstate = WAITSEND3;    
                end
            else 
                begin
                    uart_nstate = SEND2;
                end
        end

        WAITSEND3:
        begin
            if (delay_cnt == 16'd20) 
                begin
                    uart_nstate = SEND3;    
                end
            else 
                begin
                    uart_nstate = WAITSEND3;
                end
        end

        SEND3:
        begin
            if (uart_txend) 
                begin
                    uart_nstate = WAITSEND4;    
                end
            else 
                begin
                    uart_nstate = SEND3;
                end
        end

        WAITSEND4:
        begin
            if (delay_cnt == 16'd20) 
                begin
                    uart_nstate = SEND4;    
                end
            else 
                begin
                    uart_nstate = WAITSEND4;
                end
        end

        SEND4:
        begin
            if (uart_txend) 
                begin
                    uart_nstate = IDLE;    
                end
            else 
                begin
                    uart_nstate = SEND4;
                end
        end


        default : uart_nstate = W1MS;
        endcase
end
    

always @(posedge clk_i)
begin
    if(rst) 
        begin
            cnt_clr <= 1'b1;
        end
    else begin
        case (uart_cstate)                       //上点后1MS才进入等待FIFO空满的状态
        W1MS:
        begin
          //cnt_clr <= 1'b0;                    //使用计时器时，打开计时器
          //if (delay_cnt == 32'hffff)
          //    begin
          //        cnt_clr <= 1'b1;
          //    end
            cnt_clr<=(delay_cnt == 32'hffff);
        end
        
        WAITSEND1:
        begin
          //cnt_clr <= 1'b0;
          //if (delay_cnt == 16'd30) 
          //    begin
          //        cnt_clr <= 1'b1;
          //    end
            cnt_clr<=(delay_cnt == 16'd30);
        end

        WAITSEND2:
        begin
          //cnt_clr <= 1'b0;
          //if (delay_cnt == 16'd20) 
          //begin
          //    cnt_clr <= 1'b1; 
          //end
            cnt_clr<=(delay_cnt == 16'd20);
        end

        WAITSEND3:
        begin
          //cnt_clr <= 1'b0;
          //if (delay_cnt == 16'd20) 
          //begin
          //    cnt_clr <= 1'b1;    
          //end
            cnt_clr<=(delay_cnt == 16'd20);
        end

        WAITSEND4:
        begin
          //cnt_clr <= 1'b0;
          //if (delay_cnt == 16'd20) 
          //begin
          //    cnt_clr <= 1'b1;    
          //end
            cnt_clr<=(delay_cnt == 16'd20);
        end


        default : cnt_clr <= 'd1;
        endcase
    end
end
    
always @(posedge clk_i)
begin
    if(rst) 
        begin
            txfifo_rden <= 1'b0;
        end
    else if (uart_cstate == IDLE && uart_txfifo_empty_i == 1'b0) 
        begin
            txfifo_rden <= 1'b1;
        end
    else if (uart_cstate == RDFIFO) 
        begin
            txfifo_rden <= 1'b0;
        end
    else 
        begin
            txfifo_rden <= txfifo_rden;
        end
end
    
always @(posedge clk_i)
begin
    if(rst) 
        begin
            en_ctrl <= 1'b0;
        end
    else if (uart_cstate == WAITSEND1)
        begin                                 //将数据1依次送给串口IP，等待uart_txend发送完成，然后跳转状态
            en_ctrl <= 1'b1;
        end
    else if (uart_cstate == 'd11 && uart_txend == 1'b1) 
        begin
            en_ctrl <= 1'b0;
        end
    else 
        begin
            en_ctrl <= en_ctrl;
        end
end
    
always @(posedge clk_i)
begin
    if(rst) 
        begin
            uart_txdata <= 'd0;
        end
    else 
        begin
            case (uart_cstate) 
    
            SEND1:
                begin
                    uart_txdata <= txfifo_rddata[7:0];
                end
             
            SEND2:
                begin
                    uart_txdata <= txfifo_rddata[15:8];
                end
    
            SEND3:
                begin
                    uart_txdata <= txfifo_rddata[23:16];
                end
    
            SEND4:
                begin
                    uart_txdata <= txfifo_rddata[31:24];
                end
    
    
            default : uart_txdata <= uart_txdata;
            endcase
        end
end   
    
always @(posedge clk_i)
begin
    if(rst) 
            begin
                txfifo_rddata <= 'd0;
            end
    else if (uart_cstate == DISRDFIFO) 
        begin
            txfifo_rddata <= uart_txfifo_data_i;
        end
    else 
        begin
            txfifo_rddata <= txfifo_rddata;
        end
end

always @(posedge clk_i)
begin
    if(rst) 
        begin
            uart_txreq <= 1'b0;
        end
    else 
        begin
            case (uart_cstate) 
            SEND1:
            begin
                uart_txreq <= 1'b1;
                if (uart_txend) 
                    begin
                        uart_txreq <= 1'b0;
                    end
            end
             
            SEND2:
            begin
                uart_txreq <= 1'b1;
                if (uart_txend) 
                    begin
                        uart_txreq <= 1'b0;
                    end
            end
    
            SEND3:
            begin
                uart_txreq <= 1'b1;
                if (uart_txend) 
                    begin
                        uart_txreq <= 1'b0;
                    end
            end
    
            SEND4:
            begin
                uart_txreq <= 1'b1;
                if (uart_txend) 
                    begin
                        uart_txreq <= 1'b0;
                    end
            end
    
    
            default : uart_txreq <= 'd0;
            endcase
        end
end
endmodule : uart_state