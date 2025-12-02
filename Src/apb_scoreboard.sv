class apb_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(apb_scoreboard)
  
  apb_sequence_item ip_trans, op_trans;
  virtual apb_if vif;
  
  // Statistics counters
  int passed_transactions;
  int failed_transactions;
  int write_transactions;
  int read_transactions;
  int error_transactions;
  
  // Analysis FIFOs
  uvm_tlm_analysis_fifo #(apb_sequence_item) ip_fifo;
  uvm_tlm_analysis_fifo #(apb_sequence_item) op_fifo;

  // Reference memory model (matches DUT memory)
  logic [`DATA_WIDTH-1:0] ref_memory [0:`MEM_DEPTH-1]; 

  function new(string name="apb_scoreboard", uvm_component parent=null);
    super.new(name, parent);
    ip_fifo = new("ip_fifo", this);
    op_fifo = new("op_fifo", this);
    passed_transactions = 0;
    failed_transactions = 0;
    write_transactions = 0;
    read_transactions = 0;
    error_transactions = 0;
    
    // Initialize reference memory to zero
    for (int i = 0; i < `MEM_DEPTH; i++) begin
      ref_memory[i] = 32'h0;
    end
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", "No virtual interface found");
    end
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    forever begin
      // Get input transaction (from active monitor)
      ip_fifo.get(ip_trans);
      `uvm_info(get_type_name(), 
                $sformatf("[%0t] Input: %s ADDR=0x%0h, WDATA=0x%0h, STRB=0b%04b", 
                         $time, 
                         ip_trans.pwrite ? "WRITE" : "READ",
                         ip_trans.paddr, 
                         ip_trans.pwdata,
                         ip_trans.pstrb), 
                UVM_MEDIUM);
      
      // Get output transaction (from passive monitor)
      op_fifo.get(op_trans);
      `uvm_info(get_type_name(), 
                $sformatf("[%0t] Output: PRDATA=0x%0h, PREADY=%0b, PSLVERR=%0b", 
                         $time, 
                         op_trans.prdata, 
                         op_trans.pready,
                         op_trans.pslverr), 
                UVM_MEDIUM);
      
      // Check and update reference model
      check_transaction(ip_trans, op_trans);
    end
  endtask

  // Main checking function
  function void check_transaction(apb_sequence_item ip, apb_sequence_item op);
    logic [`DATA_WIDTH-1:0] expected_data;
    logic expected_error;
    bit addr_valid;
    
    addr_valid = (ip.paddr < `MEM_DEPTH);
    expected_error = !addr_valid;
    
    if (ip.pwrite) begin
      // WRITE Operation
      write_transactions++;
      
      if (addr_valid) begin
        // Update reference memory with byte strobes
        for (int i = 0; i < `STRB_WIDTH; i++) begin
          if (ip.pstrb[i]) begin
            ref_memory[ip.paddr][i*8 +: 8] = ip.pwdata[i*8 +: 8];
          end
        end
        
        `uvm_info(get_type_name(), 
                  $sformatf("Reference Memory Updated: ADDR=0x%0h, DATA=0x%0h, STRB=0b%04b", 
                           ip.paddr, ref_memory[ip.paddr], ip.pstrb), 
                  UVM_HIGH);
        
        // Check error signal
        if (op.pslverr == 1'b0) begin
          passed_transactions++;
          `uvm_info(get_type_name(), 
                    $sformatf("WRITE PASS: ADDR=0x%0h, DATA=0x%0h", 
                             ip.paddr, ip.pwdata), 
                    UVM_LOW);
        end else begin
          failed_transactions++;
          `uvm_error(get_type_name(), 
                     $sformatf("WRITE FAIL: Unexpected error for valid address 0x%0h", 
                              ip.paddr));
        end
      end else begin
        // Out of range write
        error_transactions++;
        if (op.pslverr == 1'b1) begin
          passed_transactions++;
          `uvm_info(get_type_name(), 
                    $sformatf("ERROR DETECTION PASS: Out-of-range write to ADDR=0x%0h", 
                             ip.paddr), 
                    UVM_LOW);
        end else begin
          failed_transactions++;
          `uvm_error(get_type_name(), 
                     $sformatf("ERROR DETECTION FAIL: Missing error for out-of-range write to ADDR=0x%0h", 
                              ip.paddr));
        end
      end
      
    end else begin
      // READ Operation
      read_transactions++;
      
      if (addr_valid) begin
        expected_data = ref_memory[ip.paddr];
        
        // Check read data and error signal
        if (op.prdata == expected_data && op.pslverr == 1'b0) begin
          passed_transactions++;
          `uvm_info(get_type_name(), 
                    $sformatf("READ PASS: ADDR=0x%0h, Expected=0x%0h, Actual=0x%0h", 
                             ip.paddr, expected_data, op.prdata), 
                    UVM_LOW);
        end else begin
          failed_transactions++;
          if (op.prdata != expected_data) begin
            `uvm_error(get_type_name(), 
                       $sformatf("READ DATA MISMATCH: ADDR=0x%0h, Expected=0x%0h, Actual=0x%0h", 
                                ip.paddr, expected_data, op.prdata));
          end
          if (op.pslverr != 1'b0) begin
            `uvm_error(get_type_name(), 
                       $sformatf("READ ERROR MISMATCH: Unexpected error for valid address 0x%0h", 
                                ip.paddr));
          end
        end
      end else begin
        // Out of range read - expect error pattern and PSLVERR
        error_transactions++;
        expected_data = 32'hFFFFFFFF;  // Error pattern
        
        if (op.prdata == expected_data && op.pslverr == 1'b1) begin
          passed_transactions++;
          `uvm_info(get_type_name(), 
                    $sformatf("ERROR DETECTION PASS: Out-of-range read from ADDR=0x%0h returns 0x%0h with error", 
                             ip.paddr, op.prdata), 
                    UVM_LOW);
        end else begin
          failed_transactions++;
          if (op.prdata != expected_data) begin
            `uvm_error(get_type_name(), 
                       $sformatf("ERROR PATTERN MISMATCH: ADDR=0x%0h, Expected=0x%0h, Actual=0x%0h", 
                                ip.paddr, expected_data, op.prdata));
          end
          if (op.pslverr != 1'b1) begin
            `uvm_error(get_type_name(), 
                       $sformatf("ERROR FLAG MISSING: Out-of-range read from ADDR=0x%0h should set PSLVERR", 
                                ip.paddr));
          end
        end
      end
    end
    
    // Check PREADY (should always be 1 for this slave)
    if (op.pready != 1'b1) begin
      `uvm_warning(get_type_name(), 
                   $sformatf("PREADY not asserted (expected 1, got %0b)", op.pready));
    end
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    
    `uvm_info(get_type_name(), "============================================", UVM_LOW);
    `uvm_info(get_type_name(), "       APB SLAVE VERIFICATION SUMMARY       ", UVM_LOW);
    `uvm_info(get_type_name(), "============================================", UVM_LOW);
    `uvm_info(get_type_name(), $sformatf("Total Transactions:  %0d", passed_transactions + failed_transactions), UVM_LOW);
    `uvm_info(get_type_name(), $sformatf("  - Write Operations: %0d", write_transactions), UVM_LOW);
    `uvm_info(get_type_name(), $sformatf("  - Read Operations:  %0d", read_transactions), UVM_LOW);
    `uvm_info(get_type_name(), $sformatf("  - Error Cases:      %0d", error_transactions), UVM_LOW);
    `uvm_info(get_type_name(), "--------------------------------------------", UVM_LOW);
    `uvm_info(get_type_name(), $sformatf("PASSED:              %0d", passed_transactions), UVM_LOW);
    `uvm_info(get_type_name(), $sformatf("FAILED:              %0d", failed_transactions), UVM_LOW);
    `uvm_info(get_type_name(), "============================================", UVM_LOW);
    
    if (failed_transactions == 0) begin
      `uvm_info(get_type_name(), "*** ALL TESTS PASSED ***", UVM_LOW);
    end else begin
      `uvm_error(get_type_name(), $sformatf("*** %0d TESTS FAILED ***", failed_transactions));
    end
  endfunction
  
endclass


