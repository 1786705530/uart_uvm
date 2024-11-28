`include "reg_param.v"

package uart_rgm_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import uart_reg_pkg::*;

    class ctrl_reg extends uvm_reg;
        `uvm_object_utils(ctrl_reg)
        uvm_reg_field reserved1;
        rand uvm_reg_field BRR;
        uvm_reg_field reserved2;
        rand uvm_reg_field SB;
        rand uvm_reg_field SR;
        rand uvm_reg_field PCD;
        rand uvm_reg_field PS;
        rand uvm_reg_field TE;
        rand uvm_reg_field RE;

      function new(string name = "ctrl_reg");
        super.new(name, 32, UVM_CVR_ALL);
      endfunction
      
      virtual function void build();
          reserved1 = uvm_reg_field::type_id::create("reserved1");
          BRR       = uvm_reg_field::type_id::create("BRR      ");
          reserved2 = uvm_reg_field::type_id::create("reserved2");
          SB        = uvm_reg_field::type_id::create("SB       ");
          SR        = uvm_reg_field::type_id::create("SR       ");
          PCD       = uvm_reg_field::type_id::create("PCD      ");
          PS        = uvm_reg_field::type_id::create("PS       ");
          TE        = uvm_reg_field::type_id::create("TE       ");
          RE        = uvm_reg_field::type_id::create("RE       ");
  
          reserved1 .configure(this, 20, 12, "RW", 0, 20'h0, 1, 0, 0);
          BRR       .configure(this,  4,  8, "RW", 0,  4'h0, 1, 0, 0);
          reserved2 .configure(this,  2,  6, "RW", 0,  2'h0, 1, 0, 0);
          SB        .configure(this,  1,  5, "RW", 0,  1'h0, 1, 0, 0);
          SR        .configure(this,  1,  4, "RW", 0,  1'h0, 1, 0, 0);
          PCD       .configure(this,  1,  3, "RW", 0,  1'h0, 1, 0, 0);
          PS        .configure(this,  1,  2, "RW", 0,  1'h0, 1, 0, 0);
          TE        .configure(this,  1,  1, "RW", 0,  1'h0, 1, 0, 0);
          RE        .configure(this,  1,  0, "RW", 0,  1'h0, 1, 0, 0);
      endfunction
  
    endclass


    class status_reg extends uvm_reg;
        `uvm_object_utils(status_reg)
        uvm_reg_field reserved1;
        rand uvm_reg_field NF;
        rand uvm_reg_field FE;
        rand uvm_reg_field PE;
    
        function new(string name = "status_reg");
          super.new(name, 32, UVM_CVR_ALL);
        endfunction
        
        virtual function void build();
            reserved1 = uvm_reg_field::type_id::create("reserved1");
            NF        = uvm_reg_field::type_id::create("NF"       );
            FE        = uvm_reg_field::type_id::create("FE"       );
            PE        = uvm_reg_field::type_id::create("PE"       );
    
            reserved1 .configure(this, 8,  24, "RW", 0,  8'h0, 1, 0, 0);
            NF       .configure(this,  8,  16, "RW", 0,  8'h0, 1, 0, 0);
            FE       .configure(this,  8,  8,  "RW", 0,  8'h0, 1, 0, 0);
            PE       .configure(this,  8,  0,  "RW", 0,  8'h0, 1, 0, 0);
        endfunction
    
    endclass

    class error_cnt_reg extends uvm_reg;
      `uvm_object_utils(error_cnt_reg)
      rand uvm_reg_field error_cnt;
    
      function new(string name = "error_cnt_reg");
        super.new(name, 32, UVM_CVR_ALL);
      endfunction
      
      virtual function void build();
          error_cnt        = uvm_reg_field::type_id::create("error_cnt"       );
          error_cnt       .configure(this,  32,  0,  "RW", 0,  32'h0, 1, 0, 0);
      endfunction
    
  endclass



  class uart_rgm extends uvm_reg_block;
    `uvm_object_utils(uart_rgm)
    rand ctrl_reg uart_ctrl_reg ;
    rand status_reg sta_reg       ;
    rand error_cnt_reg nec_reg       ;
    rand error_cnt_reg fec_reg       ;
    rand error_cnt_reg pec_reg       ;

    uvm_reg_map map;

    function new(string name = "uart_rgm");
      super.new(name, UVM_CVR_ALL);
    endfunction

    virtual function void build();
      uart_ctrl_reg = ctrl_reg::type_id::create("uart_ctrl_reg");
      uart_ctrl_reg.configure(this);
      uart_ctrl_reg.build();
      sta_reg = status_reg::type_id::create("sta_reg");
      sta_reg.configure(this);
      sta_reg.build();
      nec_reg = error_cnt_reg::type_id::create("nec_reg");
      nec_reg.configure(this);
      nec_reg.build();
      fec_reg = error_cnt_reg::type_id::create("fec_reg");
      fec_reg.configure(this);
      fec_reg.build();
      pec_reg = error_cnt_reg::type_id::create("pec_reg");
      pec_reg.configure(this);
      pec_reg.build();


      map = create_map("map", 'h0, 4, UVM_LITTLE_ENDIAN);

      map.add_reg(uart_ctrl_reg, 32'h0000_0000, "RW");
      map.add_reg( sta_reg     , 32'h0000_1000, "RW");
      map.add_reg( nec_reg     , 32'h0000_1004, "RW");
      map.add_reg( fec_reg     , 32'h0000_1008, "RW");
      map.add_reg( pec_reg     , 32'h0000_100C, "RW");

      //uart_ctrl_reg.add_hdl_path_slice($sformatf("mem[%0d]", `UART_CR), 0, 32);
      uart_ctrl_reg.add_hdl_path_slice("axi_uart_cr", 0, 32);
      sta_reg.add_hdl_path_slice("axi_uart_st_reg" , 0, 32);
      nec_reg.add_hdl_path_slice("axi_uart_tnc", 0, 32);
      fec_reg.add_hdl_path_slice("axi_uart_tfc", 0, 32);
      pec_reg.add_hdl_path_slice("axi_uart_tpc", 0, 32);


      add_hdl_path("tb.uartctrl_reg_u1");

      lock_model();
    endfunction
  endclass


  class reg2uart_adapter extends uvm_reg_adapter;
    `uvm_object_utils(reg2uart_adapter)
    function new(string name = "reg2uart_adapter");
      super.new(name);
      provides_responses = 1;
    endfunction
    function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
      reg_trans t = reg_trans::type_id::create("t");
      t.cmd = (rw.kind == UVM_WRITE) ? `WRITE : `READ;
      t.addr = rw.addr;
      t.data = rw.data;
      `uvm_info("reg2bus", "run_times", UVM_LOW)
      return t;
    endfunction
    function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
      reg_trans t;
      if (!$cast(t, bus_item)) begin
        `uvm_fatal("CASTFAIL","Provided bus_item is not of the correct type")
        return;
      end
      rw.kind = (t.cmd == `WRITE) ? UVM_WRITE : UVM_READ;
      rw.addr = t.addr;
      rw.data = t.data;
      rw.status = UVM_IS_OK;
    endfunction
  endclass


endpackage: uart_rgm_pkg