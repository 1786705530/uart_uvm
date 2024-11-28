`include "reg_param.v"

package uart_reg_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // register sequence item
  class reg_trans extends uvm_sequence_item;

    rand bit[31:0]  addr        ;
    rand bit        cmd         ;
    rand bit[31:0]  data        ;
    bit rsp;

    constraint cstr {
        soft cmd inside {`WRITE, `READ};

    };

    `uvm_object_utils_begin(reg_trans)
      `uvm_field_int(addr  , UVM_ALL_ON)
      `uvm_field_int(cmd   , UVM_ALL_ON)
      `uvm_field_int(data  , UVM_ALL_ON)
    `uvm_object_utils_end

    function new (string name = "reg_trans");
      super.new(name);
    endfunction
  endclass



  class reg_driver extends uvm_driver #(reg_trans);
    virtual reg_intf intf;

    `uvm_component_utils(reg_driver)
  
    function new (string name = "reg_driver", uvm_component parent);
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
            intf.peripheral_data_in   <= 0;
            intf.peripheral_read_en   <= 0;
            intf.peripheral_write_en  <= 0;
            intf.peripheral_base_addr <= 0;
            intf.peripheral_addr_in   <= 0;
      end
    endtask

    task do_drive();
      reg_trans req, rsp;
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
    
    task reg_write(reg_trans t);
      @(posedge intf.clk_125 iff intf.rst_n_125);
      case(t.cmd)
        `WRITE: begin 
                  intf.drv_ck.peripheral_addr_in    <= t.addr; 
                  intf.drv_ck.peripheral_base_addr  <= {16'h0,t.addr[31:16]}; 
                  intf.drv_ck.peripheral_read_en    <= 0; 
                  intf.drv_ck.peripheral_write_en   <= 1; 
                  intf.drv_ck.peripheral_data_in    <= t.data; 
                end
        `READ:  begin 
                  intf.drv_ck.peripheral_addr_in    <= t.addr; 
                  intf.drv_ck.peripheral_base_addr  <= {16'h0,t.addr[31:16]}; 
                  intf.drv_ck.peripheral_read_en    <= 1; 
                  intf.drv_ck.peripheral_write_en   <= 0; 
                  intf.drv_ck.peripheral_data_in    <= 0;
                  do begin
                    @(posedge intf.clk_125 iff intf.rst_n_125);
                    t.data = intf.peripheral_data_out; 
                    intf.drv_ck.peripheral_addr_in    <= 0; 
                    intf.drv_ck.peripheral_base_addr  <= 0; 
                    intf.drv_ck.peripheral_read_en    <= 0; 
                  end while(! intf.peripheral_data_out_en);
                end
      endcase
      reg_idle();
      `uvm_info(get_type_name(), $sformatf("sent addr %2x, cmd %1b, data %8x", t.addr, t.cmd, t.data), UVM_HIGH)
    endtask
    
    task reg_idle();
      @(posedge intf.clk_125);
        intf.drv_ck.peripheral_addr_in    <= 0; 
        intf.drv_ck.peripheral_base_addr  <= 0; 
        intf.drv_ck.peripheral_read_en    <= 0; 
        intf.drv_ck.peripheral_write_en   <= 0; 
        intf.drv_ck.peripheral_data_in    <= 0; 
    endtask
  endclass

  class reg_sequencer extends uvm_sequencer #(reg_trans);
    `uvm_component_utils(reg_sequencer)
    function new (string name = "reg_sequencer", uvm_component parent);
      super.new(name, parent);
    endfunction
  endclass: reg_sequencer

  class reg_base_sequence extends uvm_sequence #(reg_trans);
    rand bit[31:0] addr = -1;
    rand bit      cmd = -1;
    rand bit[31:0] data = -1;

    constraint cstr{
      soft addr == -1;
      soft cmd == -1;
      soft data == -1;
    }

    `uvm_object_utils_begin(reg_base_sequence)
      `uvm_field_int(addr, UVM_ALL_ON)
      `uvm_field_int(cmd, UVM_ALL_ON)
      `uvm_field_int(data, UVM_ALL_ON)
    `uvm_object_utils_end
    `uvm_declare_p_sequencer(reg_sequencer)

    function new (string name = "reg_base_sequence");
      super.new(name);
    endfunction

    task body();
      send_trans();
    endtask

    // generate transaction and put into local mailbox
    task send_trans();
      reg_trans req, rsp;
      `uvm_do_with(req, {local::addr >= 0 -> addr == local::addr;
                         local::cmd >= 0 -> cmd == local::cmd;
                         local::data >= 0 -> data == local::data;
                         })
      `uvm_info(get_type_name(), req.sprint(), UVM_HIGH)
      get_response(rsp);
      `uvm_info(get_type_name(), rsp.sprint(), UVM_HIGH)
      if(req.cmd == `READ) 
        this.data = rsp.data;
      assert(rsp.rsp)
        else $error("[RSPERR] %0t error response received!", $time);
    endtask

    function void post_randomize();
      string s;
      s = {s, "AFTER RANDOMIZATION \n"};
      s = {s, "=======================================\n"};
      s = {s, "reg_base_sequence object content is as below: \n"};
      s = {s, super.sprint()};
      s = {s, "=======================================\n"};
      `uvm_info(get_type_name(), s, UVM_HIGH)
    endfunction
  endclass: reg_base_sequence

  //class idle_reg_sequence extends reg_base_sequence;
  //  constraint cstr{
  //    addr == 0;
  //    cmd == `IDLE;
  //    data == 0;
  //  }
  //  `uvm_object_utils(idle_reg_sequence)
  //  function new (string name = "idle_reg_sequence");
  //    super.new(name);
  //  endfunction
  //endclass: idle_reg_sequence

  class write_reg_sequence extends reg_base_sequence;
    constraint cstr{
      cmd == `WRITE;
    }
    `uvm_object_utils(write_reg_sequence)
    function new (string name = "write_reg_sequence");
      super.new(name);
    endfunction
  endclass: write_reg_sequence

  class read_reg_sequence extends reg_base_sequence;
    constraint cstr{
      cmd == `READ;
    }
    `uvm_object_utils(read_reg_sequence)
    function new (string name = "read_reg_sequence");
      super.new(name);
    endfunction
  endclass: read_reg_sequence 

  // register monitor
  class reg_monitor extends uvm_monitor;
    virtual reg_intf intf;
    //uvm_blocking_put_port #(reg_trans) mon_bp_port;
    uvm_analysis_port #(reg_trans) mon_ana_port;

    `uvm_component_utils(reg_monitor)

    function new(string name="reg_monitor", uvm_component parent);
      super.new(name, parent);
      //mon_bp_port = new("mon_bp_port", this);
      mon_ana_port = new("mon_ana_port", this);
    endfunction

    task run_phase(uvm_phase phase);
      this.mon_trans();
    endtask

    task mon_trans();
      reg_trans m;
      forever begin
        @(posedge intf.clk_125 iff (intf.rst_n_125 && (intf.mon_ck.peripheral_write_en || intf.mon_ck.peripheral_read_en) != 0));
        m = new();
        if(intf.peripheral_addr_in[31:16] == intf.peripheral_base_addr[15:0]) begin
            m.addr = intf.mon_ck.peripheral_addr_in;
        end
        if(intf.mon_ck.peripheral_write_en == 1) begin
            m.data = intf.mon_ck.peripheral_data_in;
            m.cmd = `WRITE;
        end
        else if(intf.mon_ck.peripheral_read_en == 1) begin
            m.cmd = `READ;
            @(posedge intf.mon_ck.peripheral_data_out_en);
            m.data = intf.mon_ck.peripheral_data_out;
        end
        //mon_bp_port.put(m);
        mon_ana_port.write(m);
        `uvm_info(get_type_name(), $sformatf("monitored addr %2x, cmd %b, data %8x", m.addr, m.cmd, m.data), UVM_HIGH)
      end
    endtask
  endclass: reg_monitor


 class reg_agent_config extends uvm_object;
   `uvm_object_utils(reg_agent_config)

    virtual reg_intf vif;
    bit active = 1;

    function new(string name = "modem_config");
       super.new(name);
    endfunction
 endclass: reg_agent_config

  // register agent
  class reg_agent extends uvm_agent;
    reg_driver driver;
    reg_monitor monitor;
    reg_sequencer sequencer;
    reg_agent_config r_cfg;

    `uvm_component_utils(reg_agent)

    function new(string name = "reg_agent", uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if(!uvm_config_db #(reg_agent_config)::get(uvm_root::get(), "", "reg_agent_config", r_cfg)) begin
        `uvm_error("build_phase", "reg agent config not found")
      end
      if(r_cfg.active == UVM_ACTIVE) begin
        driver = reg_driver::type_id::create("driver", this);
        sequencer = reg_sequencer::type_id::create("sequencer", this);
      end
      monitor = reg_monitor::type_id::create("monitor", this);
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
