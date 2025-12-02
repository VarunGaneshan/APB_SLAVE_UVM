`timescale 1ns/1ns

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "project_configs.sv"
`include "apb_if.sv"
`include "apbtop.v"
  `include "apb_sequence_item.sv"
  `include "apb_sequence.sv"
  `include "apb_sequencer.sv"
  `include "apb_driver.sv"
  `include "apb_active_monitor.sv"
  `include "apb_passive_monitor.sv"
  `include "apb_active_agent.sv"
  `include "apb_passive_agent.sv"
  `include "apb_scoreboard.sv"
  `include "apb_subscriber.sv"
  `include "apb_environment.sv"
  `include "apb_test.sv"
  `include "apb_bind.sv"
  `include "apb_assertions.sv"

module top;
  bit pclk;
  bit presetn;
  
  // Clock generation - 10ns period (100MHz)
  initial pclk = 1'b0;
  always #5 pclk = ~pclk;
  
  // Reset generation
  initial begin
    presetn = 1'b0;
    #15 presetn = 1'b1;
    `uvm_info("TOP", "Reset de-asserted", UVM_LOW)
  end
  
  // APB Interface instantiation
  apb_if intf(pclk, presetn);

  // DUT instantiation - APB Slave
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

  // Set interface in config DB 
  // Change to specific comps later
  initial begin
    uvm_config_db#(virtual apb_if)::set(null, "*", "vif", intf);
  end
  
  // Simulation control
  initial begin
    `uvm_info("TOP", "=== APB SLAVE UVM VERIFICATION START ===", UVM_LOW)
    run_test(); 
  end
  
endmodule
