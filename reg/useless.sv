
  class uart_acc_sequence extends uart_reg_base_virtual_sequence;
    `uvm_object_utils(uart_acc_sequence)
    function new (string name = "uart_acc_sequence");
      super.new(name);
    endfunction

    task do_reg();

      rand_wr_ctrl wr_ctrl;
      bit[31:0] wr_val, rd_val;
      uvm_status_e status;
      @(negedge p_sequencer.intf.rst_n_125);
      @(posedge p_sequencer.intf.rst_n_125);
      @(posedge p_sequencer.intf.clk_125);

//      rgm.reset();

//      wr_val = 32'h00FF_FFF1;
//      rgm.uart_ctrl_reg.write(status, wr_val ,UVM_FRONTDOOR, .parent(this));
//      //rgm.uart_ctrl_reg.poke(status, wr_val , .parent(this));
//
//      //rd_val = rgm.uart_ctrl_reg.get();
//      //rgm.uart_ctrl_reg.set(status, 32'h00FF_EAF1);
//      //rgm.uart_ctrl_reg.get(status, rd_val);
//
//      rgm.uart_ctrl_reg.read(status, rd_val ,UVM_FRONTDOOR, .parent(this));
//      void'(this.diff_value(wr_val, rd_val, "compare0"));
//
//
//      wr_val = 32'h00FF_FFF1;
//      //rgm.nec_reg.write(status, wr_val ,UVM_BACKDOOR, .parent(this));
//      //rgm.nec_reg.poke(status, wr_val , .parent(this));
//      rgm.nec_reg.write(status, wr_val ,UVM_FRONTDOOR, .parent(this));
//      rgm.nec_reg.read(status, rd_val ,UVM_FRONTDOOR, .parent(this));
//      void'(this.diff_value(wr_val, rd_val, "compare0"));


      //set all value of WR registers via uvm_reg::set()
      repeat(200) begin
        wr_ctrl = new();
        assert(wr_ctrl.randomize());
        rgm.uart_ctrl_reg.write(status, wr_ctrl.wr_val ,UVM_FRONTDOOR, .parent(this));
        rgm.uart_ctrl_reg.read(status, rd_val ,UVM_FRONTDOOR, .parent(this));
        wr_ctrl = null;
      end
//      `uvm_info("[wr_val]",$sformatf("wr_val = %0h", wr_val), UVM_LOW)
//      `uvm_info("[rd_val]",$sformatf("rd_val = %0h", rd_val), UVM_LOW)
      rd_val = rgm.uart_ctrl_reg.get();
//      `uvm_info("[rd_val]",$sformatf("rd_val = %0h", rd_val), UVM_LOW)

//      `uvm_do_on_with(reg_slave_base_seq, p_sequencer.reg_s_sqr, {NEC == 1; PEC == 1;})
//        `uvm_do_on(write_reg_sequence, p_sequencer.reg_sqr)
//        `uvm_do_on_with(write_reg_seq, p_sequencer.reg_sqr, {addr == 32'h0000_0000; data == wr_val;})
        `uvm_do_on_with(reg_slave_base_seq, p_sequencer.reg_s_sqr, {NEC == 1; PEC == 1;FEC == 0;})


//      rgm.update(status);
      //#100ns;

      wr_val = 32'h0000_00AA; 
      rgm.uart_ctrl_reg.write(status, wr_val ,UVM_FRONTDOOR, .parent(this));
      @(posedge p_sequencer.intf.clk_125);
      rgm.nec_reg.peek(status, rd_val , .parent(this));
//      rgm.uart_ctrl_reg.read(status, rd_val ,UVM_FRONTDOOR, .parent(this));

      @(posedge p_sequencer.intf.clk_125);

    endtask