
package reg_slave_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // register sequence item
  class reg_slave_trans extends uvm_sequence_item;

    rand bit        NEC        ;
    rand bit        FEC        ;
    rand bit        PEC        ;
    bit rsp;


    `uvm_object_utils_begin(reg_slave_trans)
      `uvm_field_int(NEC  , UVM_ALL_ON)
      `uvm_field_int(FEC  , UVM_ALL_ON)
      `uvm_field_int(PEC  , UVM_ALL_ON)
    `uvm_object_utils_end

    function new (string name = "reg_slave_trans");
      super.new(name);
    endfunction
  endclass



  class reg_slave_driver extends uvm_driver #(reg_slave_trans);
    virtual reg_slave_intf intf;

    `uvm_component_utils(reg_slave_driver)
  
    function new (string name = "reg_slave_driver", uvm_component parent);
      super.new(name, parent);
    endfunction
  
    task run_phase(uvm_phase phase);
      fork
        this.do_drive();
        this.do_reset();
      join
    endtask

    task do_reset();
      forever begin
        @(negedge intf.rst_n_125);
            intf.ne_flag  <= 0;
            intf.fe_flag  <= 0;
            intf.pe_flag  <= 0;
      end
    endtask

    task do_drive();
      reg_slave_trans req, rsp;
      @(posedge intf.rst_n_125);
      forever begin
        seq_item_port.get_next_item(req);
        this.reg_write(req);
        void'($cast(rsp, req.clone()));
        rsp.rsp = 1;
        rsp.set_sequence_id(req.get_sequence_id());
        seq_item_port.item_done(rsp);
      end
    endtask  
    
    task reg_write(reg_slave_trans t);
      @(posedge intf.clk_125 iff intf.rst_n_125);
        intf.ne_flag  <= t.NEC;
        intf.fe_flag  <= t.FEC;
        intf.pe_flag  <= t.PEC;
      reg_idle();
      `uvm_info(get_type_name(), $sformatf("sent NEC %b, FEC %b, PEC %b",  t.NEC, t.FEC, t.PEC), UVM_HIGH)
    endtask
    
    task reg_idle();
      @(posedge intf.clk_125);
            intf.ne_flag  <= 0;
            intf.fe_flag  <= 0;
            intf.pe_flag  <= 0;
    endtask
  endclass

  class reg_slave_sequencer extends uvm_sequencer #(reg_slave_trans);
    `uvm_component_utils(reg_slave_sequencer)
    function new (string name = "reg_slave_sequencer", uvm_component parent);
      super.new(name, parent);
    endfunction
  endclass: reg_slave_sequencer

  class reg_slave_base_sequence extends uvm_sequence #(reg_slave_trans);
    rand bit        NEC        ;
    rand bit        FEC        ;
    rand bit        PEC        ;

    constraint cstr{
      soft NEC == -1;
      soft FEC == -1;
      soft PEC == -1;
    }

    `uvm_object_utils_begin(reg_slave_base_sequence)
      `uvm_field_int(NEC , UVM_ALL_ON)
      `uvm_field_int(FEC , UVM_ALL_ON)
      `uvm_field_int(PEC , UVM_ALL_ON)
    `uvm_object_utils_end
    `uvm_declare_p_sequencer(reg_slave_sequencer)

    function new (string name = "reg_slave_base_sequence");
      super.new(name);
    endfunction

    task body();
      send_trans();
    endtask

    // generate transaction and put into local mailbox
    task send_trans();
      reg_slave_trans req, rsp;
      `uvm_do_with(req, {local::NEC >= 0 -> NEC == local::NEC;
                         local::FEC >= 0 -> FEC == local::FEC;
                         local::PEC >= 0 -> PEC == local::PEC;
                         })
      `uvm_info(get_type_name(), req.sprint(), UVM_HIGH)
      get_response(rsp);
      `uvm_info(get_type_name(), rsp.sprint(), UVM_HIGH)
      assert(rsp.rsp)
        else $error("[RSPERR] %0t error response received!", $time);
    endtask

    function void post_randomize();
      string s;
      s = {s, "AFTER RANDOMIZATION \n"};
      s = {s, "=======================================\n"};
      s = {s, "reg_slave_base_sequence object content is as below: \n"};
      s = {s, super.sprint()};
      s = {s, "=======================================\n"};
      `uvm_info(get_type_name(), s, UVM_HIGH)
    endfunction
  endclass: reg_slave_base_sequence



  // register monitor
  class reg_slave_monitor extends uvm_monitor;
    virtual reg_slave_intf intf;
    //uvm_blocking_put_port #(reg_slave_trans) mon_bp_port;
    uvm_analysis_port #(reg_slave_trans) mon_ana_port;

    `uvm_component_utils(reg_slave_monitor)

    function new(string name="reg_slave_monitor", uvm_component parent);
      super.new(name, parent);
      //mon_bp_port = new("mon_bp_port", this);
      mon_ana_port = new("mon_ana_port", this);
    endfunction

    task run_phase(uvm_phase phase);
      this.mon_trans();
    endtask


    task mon_trans();
      reg_slave_trans m;
      forever begin
        @(posedge intf.clk_125 iff (intf.rst_n_125 && ((intf.mon_ck.ne_flag || intf.mon_ck.fe_flag || intf.mon_ck.pe_flag) != 0 )));
        m = new();
            m.NEC  = intf.mon_ck.ne_flag ;
            m.FEC  = intf.mon_ck.fe_flag ;
            m.PEC  = intf.mon_ck.pe_flag ;
        //mon_bp_port.put(m);
        mon_ana_port.write(m);
        `uvm_info(get_type_name(), $sformatf("monitored  NEC %b, FEC %b, PEC %b", m.NEC, m.FEC, m.PEC), UVM_HIGH)
      end
    endtask
  endclass: reg_slave_monitor


 class reg_slave_agent_config extends uvm_object;
   `uvm_object_utils(reg_slave_agent_config)

    virtual reg_slave_intf vif;
    bit active = 1;

    function new(string name = "modem_config");
       super.new(name);
    endfunction
 endclass: reg_slave_agent_config

  // register agent
  class reg_slave_agent extends uvm_agent;
    reg_slave_driver driver;
    reg_slave_monitor monitor;
    reg_slave_sequencer sequencer;
    reg_slave_agent_config r_cfg;

    `uvm_component_utils(reg_slave_agent)

    function new(string name = "reg_slave_agent", uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if(!uvm_config_db #(reg_slave_agent_config)::get(uvm_root::get(), "", "reg_slave_agent_config", r_cfg)) begin
        `uvm_error("build_phase", "reg agent config not found")
      end
      if(r_cfg.active == UVM_ACTIVE) begin
        driver = reg_slave_driver::type_id::create("driver", this);
        sequencer = reg_slave_sequencer::type_id::create("sequencer", this);
      end
      monitor = reg_slave_monitor::type_id::create("monitor", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      monitor.intf = r_cfg.vif;
      if(r_cfg.active == UVM_ACTIVE) begin
        driver.seq_item_port.connect(sequencer.seq_item_export);
        driver.intf = r_cfg.vif;
      end
    endfunction
  endclass

endpackage
