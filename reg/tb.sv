`timescale 1ns/1ns


interface reg_intf(input clk_125, input rst_n_125);

  logic [31:0] peripheral_data_in     ;
  logic [31:0] peripheral_addr_in     ;
  logic        peripheral_read_en     ;
  logic        peripheral_write_en    ;
  logic [31:0] peripheral_base_addr   ;
  logic [31:0] peripheral_data_out    ;
  logic        peripheral_data_out_en ;

  clocking drv_ck @(posedge clk_125);
    default input #1ns output #1ns;
    output  peripheral_data_in      ,
            peripheral_addr_in      ,
            peripheral_read_en      ,
            peripheral_write_en     ,
            peripheral_base_addr    ;
    input   peripheral_data_out     ,
            peripheral_data_out_en  ;
  endclocking

  clocking mon_ck @(posedge clk_125);
    default input #1ns output #1ns;
    input   peripheral_data_in        ,
            peripheral_addr_in        ,
            peripheral_read_en        ,
            peripheral_write_en       ,
            peripheral_base_addr      ,
            peripheral_data_out       ,
            peripheral_data_out_en    ;
  endclocking
endinterface




interface reg_slave_intf(input clk_125, input rst_n_125);

  logic        ne_flag                  ;
  logic        fe_flag                  ;
  logic        pe_flag                  ;

  clocking drv_ck @(posedge clk_125);
    default input #1ns output #1ns;
    output  ne_flag                     ,
            fe_flag                     ,
            pe_flag                     ;
  endclocking

  clocking mon_ck @(posedge clk_125);
    default input #1ns output #1ns;
    input  ne_flag                      ,
           fe_flag                      ,
           pe_flag                      ;
  endclocking
endinterface


interface ctrl_intf(input clk_125, input rst_n_125);

  logic [31:0] axi_uart_cr              ;

  clocking drv_ck @(posedge clk_125);
    default input #1ns output #1ns;
    input   axi_uart_cr                 ;
  endclocking

  clocking mon_ck @(posedge clk_125);
    default input #1ns output #1ns;
    input  axi_uart_cr                  ;
  endclocking
endinterface


interface top_intf(output logic clk_125);
  logic rst_n_125                       ;


  initial begin 
    clk_125 <= 0;
    forever begin
      #4 clk_125 <= !clk_125;
    end
  end

  clocking drv_ck @(posedge clk_125);
    output   rst_n_125                 ;
  endclocking

  clocking mon_ck @(posedge clk_125);
    input  rst_n_125                  ;
  endclocking

  task init();
    @(posedge clk_125);
    this.rst_n_125 <= 1'b1;
  endtask

endinterface

module tb;
  logic         clk_125;
  logic         rst_n_125;


uartctrl_reg uartctrl_reg_u1
(
    .clk_125                (clk_125                ),
    .rst_n_125              (rst_n_125              ),
    .axi_uart_cr            (ctrl_reg_if.axi_uart_cr      ),//
    .ne_flag                (reg_slave_if.ne_flag          ),//
    .fe_flag                (reg_slave_if.fe_flag          ),//
    .pe_flag                (reg_slave_if.pe_flag          ),//
    .peripheral_data_in     (reg_if.peripheral_data_in     ),
    .peripheral_addr_in     (reg_if.peripheral_addr_in     ),
    .peripheral_read_en     (reg_if.peripheral_read_en     ),
    .peripheral_write_en    (reg_if.peripheral_write_en    ),
    .peripheral_base_addr   (reg_if.peripheral_base_addr   ),
    .peripheral_data_out    (reg_if.peripheral_data_out    ),
    .peripheral_data_out_en (reg_if.peripheral_data_out_en )

);


  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import uart_reg_pkg::*;
  import uart_reg_test::*;
  import reg_slave_pkg::*;



    reg_intf    reg_if(.*);
    top_intf    top_intf(.*);
    reg_slave_intf  reg_slave_if(.*);
    ctrl_intf   ctrl_reg_if(.*);


  initial begin 
    uvm_config_db#(virtual reg_intf)::set(uvm_root::get(), "uvm_test_top", "reg_vif", reg_if);
    uvm_config_db#(virtual top_intf)::set(uvm_root::get(), "", "top_intf", top_intf);
    uvm_config_db#(virtual reg_slave_intf)::set(uvm_root::get(), "", "reg_slave_if", reg_slave_if);
    uvm_config_db#(virtual ctrl_intf)::set(uvm_root::get(), "", "ctrl_reg_if", ctrl_reg_if);
    run_test("uart_acc_nc_test");
  end

endmodule



