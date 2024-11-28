package reg_coverage_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import uart_reg_pkg::*;
  import uart_rgm_pkg::*;

  class reg_coverage extends uvm_subscriber #(reg_trans);
    uart_rgm rgm;
    reg_trans trans;

    `uvm_component_utils(reg_coverage)

    covergroup CTRL_REG(string name) with function sample (bit cmd);
      option.per_instance = 1;
      CR_reserved1   :       coverpoint rgm.uart_ctrl_reg.reserved1    .value[19:0]      {
                                              type_option.weight = 0                              ;
                                              bins reserve_vals  = { 20'h0 }                      ;
                                              bins specific_vals = { 20'h1, 20'hFFFFF, 20'hFFFFE }; 
                                              bins low_half      = {[20'h2 : 20'h7FFFF]}          ; 
                                              bins high_half     = {[20'h80000 : 20'hFFFFD]}      ; 
                                            }
      CR_BRR         :       coverpoint rgm.uart_ctrl_reg.BRR          .value[3:0]         
                                            {
                                            type_option.weight = 0     ;
                                            bins baud9600         = {0}; 
                                            bins baud19200        = {1}; 
                                            bins baud38400        = {2}; 
                                            bins baud57600        = {3}; 
                                            bins baud115200       = {4}; 
                                            bins baud1M           = {5}; 
                                            bins baud2M           = {6}; 
                                            bins baud3M           = {7}; 
                                            bins baud4M           = {8}; 
                                            bins baud5M           = {9}; 
                                            bins baud921600       = {10}; 
                                            bins baud230400       = {11}; 
                                            bins baudelse       = {[12:$]}; 
                                            }
      CR_reserved2   :       coverpoint rgm.uart_ctrl_reg.reserved2    .value[1:0]         {
                                              type_option.weight = 0                              ;
                                              bins reserve_vals  = { 2'h0 }                      ;
                                              bins val1          = { 2'h1 }                      ;
                                              bins val2          = { 2'h2 }                      ; 
                                              bins val3          = { 2'h3 }                      ;
                                            }
      CR_SB          :       coverpoint rgm.uart_ctrl_reg.SB           .value[0:0]         {type_option.weight = 0;}
      CR_SR          :       coverpoint rgm.uart_ctrl_reg.SR           .value[0:0]         {type_option.weight = 0;}
      CR_PCD         :       coverpoint rgm.uart_ctrl_reg.PCD          .value[0:0]         {type_option.weight = 0;}
      CR_PS          :       coverpoint rgm.uart_ctrl_reg.PS           .value[0:0]         {type_option.weight = 0;}
      CR_TE          :       coverpoint rgm.uart_ctrl_reg.TE           .value[0:0]         {type_option.weight = 0;}
      CR_RE          :       coverpoint rgm.uart_ctrl_reg.RE           .value[0:0]         {type_option.weight = 0;}

      CMD            :       coverpoint cmd    
                                            {
                                            type_option.weight = 0       ;
                                            bins rd = {1}                ;
                                            bins wr = {0}                ;
                                            }


      CROSS_CMD_CRRESV1 :       cross CMD,CR_reserved1{
                                                      bins         rd_resvr  = binsof(CMD.rd) &&  binsof(CR_reserved1.reserve_vals );
                                                      illegal_bins rd_nresvr = binsof(CMD.rd) && !binsof(CR_reserved1.reserve_vals ); 
                                                      bins         wr_resvr  = binsof(CMD.wr) &&  binsof(CR_reserved1.reserve_vals );
                                                      bins         wr_sv     = binsof(CMD.wr) &&  binsof(CR_reserved1.specific_vals);
                                                      bins         wr_lh     = binsof(CMD.wr) &&  binsof(CR_reserved1.low_half     );
                                                      bins         wr_hh     = binsof(CMD.wr) &&  binsof(CR_reserved1.high_half    );
                                                      }
      CROSS_CMD_CRBRR   :       cross CMD,CR_BRR                                              ;
      CROSS_CMD_CRRESV2 :       cross CMD,CR_reserved2{
                                                      bins         rd_resvr  = binsof(CMD.rd) &&  binsof(CR_reserved2.reserve_vals );
                                                      illegal_bins rd_nresvr = binsof(CMD.rd) && !binsof(CR_reserved2.reserve_vals ); 
                                                      bins         wr_resvr  = binsof(CMD.wr) &&  binsof(CR_reserved2.reserve_vals );
                                                      bins         wr_sv     = binsof(CMD.wr) &&  binsof(CR_reserved2.val1         );
                                                      bins         wr_lh     = binsof(CMD.wr) &&  binsof(CR_reserved2.val2         );
                                                      bins         wr_hh     = binsof(CMD.wr) &&  binsof(CR_reserved2.val3         );
                                                      }
      CROSS_CMD_CRSB    :       cross CMD,CR_SB                                               ;
      CROSS_CMD_CRSR    :       cross CMD,CR_SR                                               ;
      CROSS_CMD_CRPCD   :       cross CMD,CR_PCD                                              ;
      CROSS_CMD_CRPS    :       cross CMD,CR_PS                                               ;
      CROSS_CMD_CRTE    :       cross CMD,CR_TE                                               ;
      CROSS_CMD_CRRE    :       cross CMD,CR_RE                                               ;

    endgroup : CTRL_REG

    covergroup STATE_REG(string name) with function sample (bit cmd);
      option.cross_num_print_missing = 50;
      SR_reserved1   :       coverpoint rgm.sta_reg.reserved1          .value[7:0]          {
                                              type_option.weight = 0                              ;
                                              bins reserve_vals  = { 8'h0 }                      ;
                                              bins specific_vals = { 8'h1, 8'hFF, 8'hFE }; 
                                              bins low_half      = {[8'h2 : 8'h7F]}          ; 
                                              bins high_half     = {[8'h80 : 8'hFD]}      ; 
                                            }
      SR_NF          :       coverpoint rgm.sta_reg.NF                 .value[7:0]         {
                                              type_option.weight = 0                              ;
                                              bins specific_vals = { 8'h0,8'h1, 8'hFF, 8'hFE }    ; 
                                              bins low_half      = {[8'h2 : 8'h7F]}               ; 
                                              bins high_half     = {[8'h80 : 8'hFD]}              ; 
                                            }
      SR_FE          :       coverpoint rgm.sta_reg.FE                 .value[7:0]         {
                                              type_option.weight = 0                              ;
                                              bins specific_vals = { 8'h0,8'h1, 8'hFF, 8'hFE }    ; 
                                              bins low_half      = {[8'h2 : 8'h7F]}               ; 
                                              bins high_half     = {[8'h80 : 8'hFD]}              ; 
                                            }
      SR_PE          :       coverpoint rgm.sta_reg.PE                 .value[7:0]         {
                                              type_option.weight = 0                              ;
                                              bins specific_vals = { 8'h0,8'h1, 8'hFF, 8'hFE }    ; 
                                              bins low_half      = {[8'h2 : 8'h7F]}               ; 
                                              bins high_half     = {[8'h80 : 8'hFD]}              ; 
                                            }


      CMD            :       coverpoint cmd    
                                            {
                                            type_option.weight = 0       ;
                                            bins rd = {1}                ;
                                            bins wr = {0}                ;
                                            }
      CROSS_CMD_CRRESV1 :       cross CMD,SR_reserved1{
                                                      bins         rd_resvr  = binsof(CMD.rd) &&  binsof(SR_reserved1.reserve_vals );
                                                      illegal_bins rd_nresvr = binsof(CMD.rd) && !binsof(SR_reserved1.reserve_vals ); 
                                                      bins         wr_resvr  = binsof(CMD.wr) &&  binsof(SR_reserved1.reserve_vals );
                                                      bins         wr_sv     = binsof(CMD.wr) &&  binsof(SR_reserved1.specific_vals);
                                                      bins         wr_lh     = binsof(CMD.wr) &&  binsof(SR_reserved1.low_half     );
                                                      bins         wr_hh     = binsof(CMD.wr) &&  binsof(SR_reserved1.high_half    );
                                                      }
      CROSS_CMD_CRNF    :       cross CMD,SR_NF                                               ;
      CROSS_CMD_CRFE    :       cross CMD,SR_FE                                               ;
      CROSS_CMD_CRPE    :       cross CMD,SR_PE                                               ;
    endgroup : STATE_REG

    covergroup NEC_REG(string name) with function sample (bit cmd);
      option.cross_num_print_missing = 50;
      NEC            :       coverpoint rgm.nec_reg.error_cnt          .value[31:0]        {
                                              type_option.weight = 0                                           ;
                                              bins specific_vals = { 32'h0, 32'h1, 32'hFFFFFFFF, 32'hFFFFFFFE };
                                              bins low_half      = {[32'h2 : 32'h7FFFFFFF]}                    ;  
                                              bins high_half     = {[32'h80000000 : 32'hFFFFFFFD]}             ;
                                            }
      CMD            :       coverpoint cmd    
                                            {
                                            type_option.weight = 0       ;
                                            bins rd = {1}                ;
                                            bins wr = {0}                ;
                                            }
      CROSS_CMD_CRNF    :       cross CMD,NEC                                               ;
    endgroup : NEC_REG

    covergroup FEC_REG(string name) with function sample (bit cmd);
      option.cross_num_print_missing = 50;
      FEC            :       coverpoint rgm.fec_reg.error_cnt          .value[31:0]        {
                                              type_option.weight = 0                                           ;
                                              bins specific_vals = { 32'h0, 32'h1, 32'hFFFFFFFF, 32'hFFFFFFFE };
                                              bins low_half      = {[32'h2 : 32'h7FFFFFFF]}                    ; 
                                              bins high_half     = {[32'h80000000 : 32'hFFFFFFFD]}             ;
                                            }
      CMD            :       coverpoint cmd    
                                            {
                                            type_option.weight = 0       ;
                                            bins rd = {1}                ;
                                            bins wr = {0}                ;
                                            }
      CROSS_CMD_CRNF    :       cross CMD,FEC                                               ;
    endgroup : FEC_REG

    covergroup PEC_REG(string name) with function sample (bit cmd);
      option.cross_num_print_missing = 50;
      PEC            :       coverpoint rgm.pec_reg.error_cnt          .value[31:0]        {
                                              type_option.weight = 0                                           ;
                                              bins specific_vals = { 32'h0, 32'h1, 32'hFFFFFFFF, 32'hFFFFFFFE };
                                              bins low_half      = {[32'h2 : 32'h7FFFFFFF]}                    ; 
                                              bins high_half     = {[32'h80000000 : 32'hFFFFFFFD]}             ;
                                            }
      CMD            :       coverpoint cmd    
                                            {
                                            type_option.weight = 0       ;
                                            bins rd = {1}                ;
                                            bins wr = {0}                ;
                                            }
      CROSS_CMD_CRNF    :       cross CMD,PEC                                               ;
    endgroup : PEC_REG


    function new (string name, uvm_component parent);
      super.new(name,parent);
      CTRL_REG   = new(name);
      STATE_REG  = new(name);
      NEC_REG    = new(name);
      FEC_REG    = new(name);
      PEC_REG    = new(name);
    endfunction

    function void write(T t);
      //$display("%p",t);
      $display("**********************************************************************************");
      t.print;
      //this.trans = t;
      $display("**********************************************************************************");
      if(t.addr[15:0] == 16'h0)
        CTRL_REG.sample(t.cmd);
      else if(t.addr[15:0] == 16'h1000)
        STATE_REG.sample(t.cmd);
      else if(t.addr[15:0] == 16'h1004)
        NEC_REG.sample(t.cmd);
      else if(t.addr[15:0] == 16'h1008)
        FEC_REG.sample(t.cmd);
      else if(t.addr[15:0] == 16'h100C)
        PEC_REG.sample(t.cmd);
    endfunction
  endclass

endpackage