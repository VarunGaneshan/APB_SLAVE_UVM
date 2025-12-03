`timescale 1ns/1ns

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "project_configs.sv"
`include "apb_if.sv"
`include "apbtop.v"
`include "apb_pkg.sv"
import apb_pkg::*;
`include "apb_bind.sv"
`include "apb_assertions.sv"

module top;
  bit pclk;
  bit presetn;
  
  // Clock generation - 10ns period (100MHz)
  initial pclk = 1'b0;
  always #5 pclk = ~pclk;

  initial begin
    presetn = 1'b0;
    #15 presetn = 1'b1;
    `uvm_info("TOP", "Reset de-asserted", UVM_LOW)
  end

  apb_if intf(pclk, presetn);

  apb_slave #(
    .ADDR_WIDTH(`ADDR_WIDTH),
    .DATA_WIDTH(`DATA_WIDTH),
    .MEM_DEPTH(`MEM_DEPTH)
  ) DUT (
    .PCLK    (intf.pclk),
    .PRESETn (intf.presetn),
    .PADDR   (intf.paddr),
    .PSEL    (intf.psel),
    .PENABLE (intf.penable),
    .PWRITE  (intf.pwrite),
    .PWDATA  (intf.pwdata),
    .PSTRB   (intf.pstrb),
    .PRDATA  (intf.prdata),
    .PREADY  (intf.pready),
    .PSLVERR (intf.pslverr)
  );

  initial begin
    uvm_config_db#(virtual apb_if)::set(null,"uvm_test_top.env.active_agent.driver","vif",intf);
    uvm_config_db#(virtual apb_if)::set(null,"uvm_test_top.env.active_agent.active_monitor","vif",intf);
    uvm_config_db#(virtual apb_if)::set(null,"uvm_test_top.env.passive_agent.passive_monitor","vif",intf);
    uvm_config_db#(virtual apb_if)::set(null,"uvm_test_top.env.scoreboard","vif",intf);
  end
  
  initial begin
    `uvm_info("TOP", "=== APB SLAVE UVM VERIFICATION START ===", UVM_LOW)
    run_test(); 
  #100 $finish;
  end
  
endmodule
