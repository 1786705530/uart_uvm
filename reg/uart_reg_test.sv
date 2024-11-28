`include "reg_param.v"
package uart_reg_test;

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import uart_reg_pkg::*;
  import uart_rgm_pkg::*;
//`include "reg_coverage.svh"
  import reg_coverage_pkg::*;
  import reg_slave_pkg::*;
  import rst_pkg::*;

  class uart_reg_virtual_sequencer extends uvm_sequencer;
    reg_sequencer reg_sqr;
    reg_slave_sequencer reg_s_sqr;
    uart_rgm rgm;
    virtual top_intf intf  ;
    virtual ctrl_intf ctrl_reg_if  ;

    `uvm_component_utils(uart_reg_virtual_sequencer)

    function new (string name = "uart_reg_virtual_sequencer", uvm_component parent);
      super.new(name, parent);
    endfunction


    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      if(!uvm_config_db#(virtual ctrl_intf)::get(this,"","ctrl_reg_if", ctrl_reg_if)) begin
        `uvm_fatal("GETVIF","cannot get vif handle from config DB")
      end
      if(!uvm_config_db#(virtual top_intf)::get(uvm_root::get(),"","top_intf", intf)) begin
        `uvm_fatal("GETVIF","cannot get top_intf handle from config DB")
      end
    endfunction
  endclass

  `uvm_analysis_imp_decl(_reg)
  `uvm_analysis_imp_decl(_slave)


  class uart_checker extends uvm_scoreboard;

      bit[31:0] sta_val;
      bit[31:0] nec_val;
      bit[31:0] fec_val;
      bit[31:0] pec_val;

      bit[31:0] sta_cnt;
      bit[31:0] nec_cnt;
      bit[31:0] fec_cnt;
      bit[31:0] pec_cnt;

      reg_slave_trans rs_trans [$];

      virtual top_intf intf  ;
  
      uvm_analysis_imp_reg #(reg_trans,uart_checker) ana_imp_reg;
      uvm_analysis_imp_slave #(reg_slave_trans,uart_checker) ana_imp_slave;
  
      `uvm_component_utils(uart_checker)
      function new (string name = "uart_checker", uvm_component parent);
        super.new(name, parent);
        ana_imp_reg = new("ana_imp_reg", this);
        ana_imp_slave = new("ana_imp_slave", this);
      endfunction
  
      function void build_phase(uvm_phase phase);
        super.build_phase(phase);
  
        if(!uvm_config_db#(virtual top_intf)::get(uvm_root::get(),"","top_intf", intf)) begin
          `uvm_fatal("GETVIF","cannot get top_intf handle from config DB")
        end
      endfunction


      function void write_reg(reg_trans t);
        if(t.addr[15:0] == 16'h1000 && t.cmd == `READ)
          void'(this.diff_value(sta_cnt,t.data, "sta_error"));
        else if(t.addr[15:0] == 16'h1004 && t.cmd == `READ)
          void'(this.diff_value(nec_cnt,t.data, "nec_error"));
        else if(t.addr[15:0] == 16'h1008 && t.cmd == `READ)
          void'(this.diff_value(fec_cnt,t.data, "fec_error"));
        else if(t.addr[15:0] == 16'h100C && t.cmd == `READ)
          void'(this.diff_value(pec_cnt,t.data, "pec_error"));
      endfunction

      function void write_slave(reg_slave_trans m);
        rs_trans.push_back(m);
      endfunction
      

      task run_phase(uvm_phase phase);
        fork
          cnt();
        join
      endtask


      task cnt();
        reg_slave_trans m;
        forever begin
          @(posedge intf.clk_125);
          if(intf.rst_n_125 == 1'b0)begin
            sta_cnt = 32'h0;
            nec_cnt = 32'h0;
            fec_cnt = 32'h0;
            pec_cnt = 32'h0;
          end
          else if(rs_trans.size() != 'd0)begin
            m = rs_trans.pop_front;
            if(sta_cnt[23:16] == 8'd255) begin
              sta_cnt[23:16] = sta_cnt[23:16];
            end
            else begin
              sta_cnt[23:16] = sta_cnt[23:16] + m.NEC;
            end
            if(sta_cnt[15:8] == 8'd255) begin
              sta_cnt[15:8] = sta_cnt[15:8];
            end
            else begin
              sta_cnt[15:8] = sta_cnt[15:8] + m.FEC;
            end
            if(sta_cnt[7:0] == 8'd255) begin
              sta_cnt[7:0] = sta_cnt[7:0];
            end
            else begin
              sta_cnt[7:0] = sta_cnt[7:0] + m.PEC;
            end
            if(nec_cnt == 32'hffff_ffff) begin
              nec_cnt = nec_cnt;
            end
            else begin
              nec_cnt = nec_cnt + m.NEC;
            end
            if(fec_cnt == 32'hffff_ffff) begin
              fec_cnt = fec_cnt;
            end
            else begin
              fec_cnt = fec_cnt + m.FEC;
            end
            if(pec_cnt == 32'hffff_ffff) begin
              pec_cnt = pec_cnt;
            end
            else begin
              pec_cnt = pec_cnt + m.PEC;
            end
          end
        end
      endtask



      function bit diff_value(int val1, int val2, string id = "value_compare");
        if(val1 != val2) begin
          `uvm_error("[CMPERR]", $sformatf("ERROR! %s val1 %8x != val2 %8x", id, val1, val2)) 
          return 0;
        end
        else begin
          `uvm_info("[CMPSUC]", $sformatf("SUCCESS! %s val1 %8x == val2 %8x", id, val1, val2), UVM_LOW)
          return 1;
        end
      endfunction
  
  endclass: uart_checker

  class uart_reg_env extends uvm_env;
    reg_agent reg_agt;
    reg_slave_agent reg_s_agt;
    rst_agent rst_agt;
    uart_reg_virtual_sequencer virt_sqr;
    uart_rgm rgm;
    reg_coverage r_cvg;
    reg2uart_adapter adapter;
    uart_checker chkr;

    uvm_reg_predictor #(reg_trans) predictor;

    `uvm_component_utils(uart_reg_env)

    function new (string name = "uart_reg_env", uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      this.reg_agt = reg_agent::type_id::create("reg_agt", this);
      this.reg_s_agt = reg_slave_agent::type_id::create("reg_s_agt", this);
      this.rst_agt = rst_agent::type_id::create("rst_agt", this);
      virt_sqr = uart_reg_virtual_sequencer::type_id::create("virt_sqr", this);
      rgm = uart_rgm::type_id::create("rgm", this);
      chkr = uart_checker::type_id::create("chkr", this);
      rgm.build();
      r_cvg = reg_coverage::type_id::create("r_cvg", this);
      adapter = reg2uart_adapter::type_id::create("adapter", this);
      predictor = uvm_reg_predictor#(reg_trans)::type_id::create("predictor", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      virt_sqr.reg_sqr = reg_agt.sequencer;
      virt_sqr.reg_s_sqr = reg_s_agt.sequencer;
      rgm.map.set_sequencer(reg_agt.sequencer, adapter);
      reg_agt.monitor.mon_ana_port.connect(predictor.bus_in);
      reg_agt.monitor.mon_ana_port.connect(r_cvg.analysis_export);
      reg_agt.monitor.mon_ana_port.connect(chkr.ana_imp_reg);
      reg_s_agt.monitor.mon_ana_port.connect(chkr.ana_imp_slave);
      predictor.map = rgm.map;
      predictor.adapter = adapter;
      virt_sqr.rgm = rgm;
      r_cvg.rgm = rgm;
    endfunction
  endclass: uart_reg_env


  class uart_reg_base_virtual_sequence extends uvm_sequence;
    //idle_reg_sequence idle_reg_seq;
    write_reg_sequence write_reg_seq;
    read_reg_sequence read_reg_seq;
    reg_slave_base_sequence reg_slave_base_seq;
    uart_rgm rgm;

    `uvm_object_utils(uart_reg_base_virtual_sequence)
    `uvm_declare_p_sequencer(uart_reg_virtual_sequencer)

    function new (string name = "uart_reg_base_virtual_sequence");
      super.new(name);
    endfunction

    virtual task body();
      `uvm_info(get_type_name(), "=====================STARTED=====================", UVM_LOW)
      rgm = p_sequencer.rgm;

      this.do_reg();

      `uvm_info(get_type_name(), "=====================FINISHED=====================", UVM_LOW)
    endtask

    virtual task do_reg();
    endtask


    virtual function bit diff_value(int val1, int val2, string id = "value_compare");
    endfunction


  endclass

  class uart_reg_base_test extends uvm_test;
    uart_reg_env env;
    virtual reg_intf reg_vif  ;
    reg_agent_config r_cfg;
    reg_slave_agent_config r_s_cfg;

    `uvm_component_utils(uart_reg_base_test)

    function new(string name = "uart_reg_base_test", uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);

      r_cfg = reg_agent_config::type_id::create("r_cfg");
      r_s_cfg = reg_slave_agent_config::type_id::create("r_s_cfg");
      if(!uvm_config_db#(virtual reg_intf)::get(this,"","reg_vif", r_cfg.vif)) begin
        `uvm_fatal("GETVIF","cannot get vif handle from config DB")
      end
      uvm_config_db #(reg_agent_config)::set(uvm_root::get(), "", "reg_agent_config", r_cfg);
      
      if(!uvm_config_db#(virtual reg_slave_intf)::get(this,"","reg_slave_if", r_s_cfg.vif)) begin
        `uvm_fatal("GETVIF","cannot get vif handle from config DB")
      end
      uvm_config_db #(reg_slave_agent_config)::set(uvm_root::get(), "", "reg_slave_agent_config", r_s_cfg);


      this.env = uart_reg_env::type_id::create("env", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      //this.set_interface(reg_vif);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
      super.end_of_elaboration_phase(phase);
      uvm_root::get().set_report_verbosity_level_hier(UVM_HIGH);
      uvm_root::get().set_report_max_quit_count(3);
      uvm_root::get().set_timeout(10ms);
    endfunction

    task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      this.run_top_virtual_sequence();
      phase.drop_objection(this);
    endtask

    virtual task run_top_virtual_sequence();
    endtask

    //virtual function void set_interface(virtual reg_intf reg_vif);
    //  this.env.reg_agt.set_interface(reg_vif);
    //endfunction
  endclass: uart_reg_base_test




class rand_wr extends uvm_object;
  rand bit [31:0] wr_val;

    `uvm_object_utils_begin(rand_wr)
      `uvm_field_int(wr_val , UVM_ALL_ON)
    `uvm_object_utils_end

    function new (string name = "rand_wr");
      super.new(name);
    endfunction

endclass

class error_maker extends uvm_object;
  rand bit  NEC;
  rand bit  PEC;
  rand bit  FEC;
  rand bit [7:0] idle;

    `uvm_object_utils_begin(error_maker)
      `uvm_field_int(NEC , UVM_ALL_ON)
      `uvm_field_int(PEC , UVM_ALL_ON)
      `uvm_field_int(FEC , UVM_ALL_ON)
      `uvm_field_int(idle , UVM_ALL_ON)
    `uvm_object_utils_end

    function new (string name = "error_maker");
      super.new(name);
    endfunction

endclass

  class uart_acc_nc_sequence extends uart_reg_base_virtual_sequence;
    `uvm_object_utils(uart_acc_nc_sequence)
    function new (string name = "uart_acc_nc_sequence");
      super.new(name);
    endfunction

    task do_reg();

      rand_wr wr_ctrl;
      rand_wr wr_sta ;
      rand_wr wr_nec ;
      rand_wr wr_fec ;
      rand_wr wr_pec ;
      error_maker em;
      bit[31:0] rd_val;
      bit[31:0] sta_val;
      bit[31:0] nec_val;
      bit[31:0] fec_val;
      bit[31:0] pec_val;

      bit[31:0] sta_cnt;
      bit[31:0] nec_cnt;
      bit[31:0] fec_cnt;
      bit[31:0] pec_cnt;
      uvm_status_e status;
      @(negedge p_sequencer.intf.rst_n_125);
      @(posedge p_sequencer.intf.rst_n_125);
      @(posedge p_sequencer.intf.clk_125);

//      repeat(200) begin
//        wr_ctrl = new();
//        assert(wr_ctrl.randomize());
//        rgm.uart_ctrl_reg.write(status, wr_ctrl.wr_val ,UVM_FRONTDOOR, .parent(this));
//        rgm.uart_ctrl_reg.read(status, rd_val ,UVM_FRONTDOOR, .parent(this));
//        void'(this.ctrl_diff_value(wr_ctrl.wr_val,rd_val, "CTRL_WR"));
//        void'(this.ctrl_diff_value(wr_ctrl.wr_val,p_sequencer.ctrl_reg_if.axi_uart_cr, "CTRL_REG"));
//        wr_ctrl = null;
//      end

      repeat(1000) begin
        //制造错误
        em = new();
        assert(em.randomize());
        em.print();
        `uvm_do_on_with(reg_slave_base_seq, p_sequencer.reg_s_sqr, {NEC == em.NEC; PEC == em.PEC;FEC == em.FEC;})

        //写入干扰

        wr_sta = new();
        assert(wr_sta.randomize());
        wr_nec = new();
        assert(wr_nec.randomize());
        wr_fec = new();
        assert(wr_fec.randomize());
        wr_pec = new();
        assert(wr_pec.randomize());

        rgm.uart_ctrl_reg.write(status, wr_sta.wr_val ,UVM_FRONTDOOR, .parent(this));
        rgm.sta_reg.read(status, sta_val ,UVM_FRONTDOOR, .parent(this));

        rgm.uart_ctrl_reg.write(status, wr_nec.wr_val ,UVM_FRONTDOOR, .parent(this));
        rgm.nec_reg.read(status, nec_val ,UVM_FRONTDOOR, .parent(this));

        rgm.uart_ctrl_reg.write(status, wr_fec.wr_val ,UVM_FRONTDOOR, .parent(this));
        rgm.fec_reg.read(status, fec_val ,UVM_FRONTDOOR, .parent(this));

        rgm.uart_ctrl_reg.write(status, wr_pec.wr_val ,UVM_FRONTDOOR, .parent(this));
        rgm.pec_reg.read(status, pec_val ,UVM_FRONTDOOR, .parent(this));
        repeat(em.idle) @(posedge p_sequencer.intf.clk_125);
        em = null;
      end
    endtask

    function bit ctrl_diff_value(int wr_val, int rd_val, string id = "value_compare");
      if((wr_val[5:0] != rd_val[5:0])||(wr_val[11:8] != rd_val[11:8])||(rd_val[31:12] != 'h0)||(rd_val[7:6] != 'h0)) begin
        `uvm_error("[CMPERR]", $sformatf("ERROR! %s wr_val %8x != rd_val %8x", id, wr_val, rd_val)) 
        return 0;
      end
      else begin
        `uvm_info("[CMPSUC]", $sformatf("SUCCESS! %s wr_val %8x == rd_val %8x", id, wr_val, rd_val), UVM_LOW)
        return 1;
      end
    endfunction

    


  endclass: uart_acc_nc_sequence

  class uart_acc_nc_test extends uart_reg_base_test;

    `uvm_component_utils(uart_acc_nc_test)

    function new(string name = "uart_acc_nc_test", uvm_component parent);
      super.new(name, parent);
    endfunction

    task run_top_virtual_sequence();
      uart_acc_nc_sequence top_seq = new();
      top_seq.start(env.virt_sqr);
    endtask
  endclass: uart_acc_nc_test






















































  class uart_acc_sequence extends uart_reg_base_virtual_sequence;
    `uvm_object_utils(uart_acc_sequence)
    function new (string name = "uart_acc_sequence");
      super.new(name);
    endfunction

    task do_reg();

      rand_wr wr_ctrl;
      rand_wr wr_sta ;
      rand_wr wr_nec ;
      rand_wr wr_fec ;
      rand_wr wr_pec ;
      error_maker em;
      bit[31:0] rd_val;
      bit[31:0] sta_val;
      bit[31:0] nec_val;
      bit[31:0] fec_val;
      bit[31:0] pec_val;

      bit[31:0] sta_cnt;
      bit[31:0] nec_cnt;
      bit[31:0] fec_cnt;
      bit[31:0] pec_cnt;
      uvm_status_e status;
      @(negedge p_sequencer.intf.rst_n_125);
      @(posedge p_sequencer.intf.rst_n_125);
      @(posedge p_sequencer.intf.clk_125);

//      repeat(200) begin
//        wr_ctrl = new();
//        assert(wr_ctrl.randomize());
//        rgm.uart_ctrl_reg.write(status, wr_ctrl.wr_val ,UVM_FRONTDOOR, .parent(this));
//        rgm.uart_ctrl_reg.read(status, rd_val ,UVM_FRONTDOOR, .parent(this));
//        void'(this.ctrl_diff_value(wr_ctrl.wr_val,rd_val, "CTRL_WR"));
//        void'(this.ctrl_diff_value(wr_ctrl.wr_val,p_sequencer.ctrl_reg_if.axi_uart_cr, "CTRL_REG"));
//        wr_ctrl = null;
//      end

      repeat(1000) begin
        //制造错误
        em = new();
        assert(em.randomize());
        em.print();
        `uvm_do_on_with(reg_slave_base_seq, p_sequencer.reg_s_sqr, {NEC == em.NEC; PEC == em.PEC;FEC == em.FEC;})
        error_cnt(em.NEC, em.FEC, em.PEC, sta_cnt, nec_cnt, fec_cnt, pec_cnt);

        //写入干扰

        wr_sta = new();
        assert(wr_sta.randomize());
        wr_nec = new();
        assert(wr_nec.randomize());
        wr_fec = new();
        assert(wr_fec.randomize());
        wr_pec = new();
        assert(wr_pec.randomize());

        rgm.uart_ctrl_reg.write(status, wr_sta.wr_val ,UVM_FRONTDOOR, .parent(this));
        rgm.sta_reg.read(status, sta_val ,UVM_FRONTDOOR, .parent(this));
        void'(this.diff_value(sta_val,sta_cnt, "sta_error"));

        rgm.uart_ctrl_reg.write(status, wr_nec.wr_val ,UVM_FRONTDOOR, .parent(this));
        rgm.nec_reg.read(status, nec_val ,UVM_FRONTDOOR, .parent(this));
        void'(this.diff_value(nec_val,nec_cnt, "nec_error"));

        rgm.uart_ctrl_reg.write(status, wr_fec.wr_val ,UVM_FRONTDOOR, .parent(this));
        rgm.fec_reg.read(status, fec_val ,UVM_FRONTDOOR, .parent(this));
        void'(this.diff_value(fec_val,fec_cnt, "fec_error"));

        rgm.uart_ctrl_reg.write(status, wr_pec.wr_val ,UVM_FRONTDOOR, .parent(this));
        rgm.pec_reg.read(status, pec_val ,UVM_FRONTDOOR, .parent(this));
        void'(this.diff_value(pec_val,pec_cnt, "pec_error"));
        repeat(em.idle) @(posedge p_sequencer.intf.clk_125);
        em = null;
      end
    endtask

    function bit ctrl_diff_value(int wr_val, int rd_val, string id = "value_compare");
      if((wr_val[5:0] != rd_val[5:0])||(wr_val[11:8] != rd_val[11:8])||(rd_val[31:12] != 'h0)||(rd_val[7:6] != 'h0)) begin
        `uvm_error("[CMPERR]", $sformatf("ERROR! %s wr_val %8x != rd_val %8x", id, wr_val, rd_val)) 
        return 0;
      end
      else begin
        `uvm_info("[CMPSUC]", $sformatf("SUCCESS! %s wr_val %8x == rd_val %8x", id, wr_val, rd_val), UVM_LOW)
        return 1;
      end
    endfunction

    function void error_cnt(bit error1, bit error2, bit error3,ref bit [31:0] sta_cnt,ref bit [31:0] nec_cnt,ref bit [31:0] fec_cnt,ref bit [31:0] pec_cnt);
      if(sta_cnt[23:16] == 8'd255) begin
        sta_cnt[23:16] = sta_cnt[23:16];
      end
      else begin
        sta_cnt[23:16] = sta_cnt[23:16] + error1;
      end
      if(sta_cnt[15:8] == 8'd255) begin
        sta_cnt[15:8] = sta_cnt[15:8];
      end
      else begin
        sta_cnt[15:8] = sta_cnt[15:8] + error2;
      end
      if(sta_cnt[7:0] == 8'd255) begin
        sta_cnt[7:0] = sta_cnt[7:0];
      end
      else begin
        sta_cnt[7:0] = sta_cnt[7:0] + error3;
      end
      if(nec_cnt == 32'hffff_ffff) begin
        nec_cnt = nec_cnt;
      end
      else begin
        nec_cnt = nec_cnt + error1;
      end
      if(fec_cnt == 32'hffff_ffff) begin
        fec_cnt = fec_cnt;
      end
      else begin
        fec_cnt = fec_cnt + error2;
      end
      if(pec_cnt == 32'hffff_ffff) begin
        pec_cnt = pec_cnt;
      end
      else begin
        pec_cnt = pec_cnt + error3;
      end
    endfunction


    function bit diff_value(int val1, int val2, string id = "value_compare");
      if(val1 != val2) begin
        `uvm_error("[CMPERR]", $sformatf("ERROR! %s val1 %8x != val2 %8x", id, val1, val2)) 
        return 0;
      end
      else begin
        `uvm_info("[CMPSUC]", $sformatf("SUCCESS! %s val1 %8x == val2 %8x", id, val1, val2), UVM_LOW)
        return 1;
      end
    endfunction

  endclass: uart_acc_sequence

  class uart_acc_test extends uart_reg_base_test;

    `uvm_component_utils(uart_acc_test)

    function new(string name = "uart_acc_test", uvm_component parent);
      super.new(name, parent);
    endfunction

    task run_top_virtual_sequence();
      uart_acc_sequence top_seq = new();
      top_seq.start(env.virt_sqr);
    endtask
  endclass: uart_acc_test




endpackage










//useless




//  class uart_reg_data_consistence_basic_virtual_sequence extends uart_reg_base_virtual_sequence;
//    `uvm_object_utils(uart_reg_data_consistence_basic_virtual_sequence)
//    function new (string name = "uart_reg_data_consistence_basic_virtual_sequence");
//      super.new(name);
//    endfunction
//    task do_reg();
//      bit[31:0] wr_val, rd_val;
//      uvm_status_e status;
//      // slv0 with len=8,  prio=0, en=1
//      wr_val = (1<<3)+(0<<1)+1;
//      rgm.uart_ctrl_reg.write(status, wr_val);
//      rgm.uart_ctrl_reg.read(status, rd_val);
//      void'(this.diff_value(wr_val, rd_val, "compare0"));
//
//      // slv1 with len=16, prio=1, en=1
//      wr_val = (2<<3)+(1<<1)+1;
//      rgm.uart_ctrl_reg.write(status, wr_val);
//      rgm.uart_ctrl_reg.read(status, rd_val);
//      void'(this.diff_value(wr_val, rd_val, "compare1"));
//
//      // slv2 with len=32, prio=2, en=1
//      wr_val = (3<<3)+(2<<1)+1;
//      rgm.uart_ctrl_reg.write(status, wr_val);
//      rgm.uart_ctrl_reg.read(status, rd_val);
//      void'(this.diff_value(wr_val, rd_val, "compare2"));
//
//      // send IDLE command
////      `uvm_do_on(idle_reg_seq, p_sequencer.reg_sqr)
//    endtask
//
//    
//  endclass: uart_reg_data_consistence_basic_virtual_sequence
//
//  class uart_reg_data_consistence_basic_test extends uart_reg_base_test;
//
//    `uvm_component_utils(uart_reg_data_consistence_basic_test)
//
//    function new(string name = "uart_reg_data_consistence_basic_test", uvm_component parent);
//      super.new(name, parent);
//    endfunction
//
//    task run_top_virtual_sequence();
//      uart_reg_data_consistence_basic_virtual_sequence top_seq = new();
//      top_seq.start(env.virt_sqr);
//    endtask
//  endclass: uart_reg_data_consistence_basic_test
//
//
//  class uart_reg_builtin_virtual_sequence extends uart_reg_base_virtual_sequence;
//    `uvm_object_utils(uart_reg_builtin_virtual_sequence)
//    function new (string name = "uart_reg_builtin_virtual_sequence");
//      super.new(name);
//    endfunction
//
//    task do_reg();
//      uvm_reg_hw_reset_seq reg_rst_seq = new(); 
//      uvm_reg_bit_bash_seq reg_bit_bash_seq = new();
//      uvm_reg_access_seq reg_acc_seq = new();
//
//      // wait reset asserted and release
//      @(negedge p_sequencer.intf.rst_n_125);
//      @(posedge p_sequencer.intf.rst_n_125);
//
//      `uvm_info("BLTINSEQ", "register reset sequence started", UVM_LOW)
//      rgm.reset();
//      reg_rst_seq.model = rgm;
//      reg_rst_seq.start(p_sequencer.reg_sqr);
//      `uvm_info("BLTINSEQ", "register reset sequence finished", UVM_LOW)
//
//      `uvm_info("BLTINSEQ", "register bit bash sequence started", UVM_LOW)
//      // reset hardware register and register model
//      p_sequencer.intf.rst_n_125 <= 'b0;
//      repeat(5) @(posedge p_sequencer.intf.clk_125);
//      p_sequencer.intf.rst_n_125 <= 'b1;
//      rgm.reset();
//      reg_bit_bash_seq.model = rgm;
//      reg_bit_bash_seq.start(p_sequencer.reg_sqr);
//      `uvm_info("BLTINSEQ", "register bit bash sequence finished", UVM_LOW)
//
//      `uvm_info("BLTINSEQ", "register access sequence started", UVM_LOW)
//      // reset hardware register and register model
//      p_sequencer.intf.rst_n_125 <= 'b0;
//      repeat(5) @(posedge p_sequencer.intf.clk_125);
//      p_sequencer.intf.rst_n_125 <= 'b1;
//      rgm.reset();
//      reg_acc_seq.model = rgm;
//      reg_acc_seq.start(p_sequencer.reg_sqr);
//      `uvm_info("BLTINSEQ", "register access sequence finished", UVM_LOW)
//    endtask
//  endclass: uart_reg_builtin_virtual_sequence
//
//  class uart_reg_builtin_test extends uart_reg_base_test;
//
//    `uvm_component_utils(uart_reg_builtin_test)
//
//    function new(string name = "uart_reg_builtin_test", uvm_component parent);
//      super.new(name, parent);
//    endfunction
//
//    task run_top_virtual_sequence();
//      uart_reg_builtin_virtual_sequence top_seq = new();
//      top_seq.start(env.virt_sqr);
//    endtask
//  endclass: uart_reg_builtin_test
