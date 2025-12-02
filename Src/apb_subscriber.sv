class apb_subscriber extends uvm_subscriber #(apb_sequence_item);
  `uvm_component_utils(apb_subscriber)
  
  apb_sequence_item trans;
  real total_cov;
  
  //============================================================================
  // Coverage Groups
  //============================================================================
  
  // APB Protocol Signal Coverage
  covergroup apb_protocol_cg;
    option.per_instance = 1;
    option.name = "apb_protocol_coverage";
    
    cp_pwrite: coverpoint trans.pwrite {
      bins write = {1'b1};
      bins read  = {1'b0};
    }
    
    cp_psel: coverpoint trans.psel {
      bins selected     = {1'b1};
      bins not_selected = {1'b0};
    }
    
    cp_pready: coverpoint trans.pready {
      bins ready = {1'b1};
      bins not_ready = {1'b0};
    }
    
    cp_pslverr: coverpoint trans.pslverr {
      bins no_error = {1'b0};
      bins error    = {1'b1};
    }
  endgroup
  
  // Address Coverage
  covergroup address_cg;
    option.per_instance = 1;
    option.name = "address_coverage";
    
    cp_addr: coverpoint trans.paddr {
      bins low_range    = {[0:63]};
      bins mid_low      = {[64:127]};
      bins mid_high     = {[128:191]};
      bins high_range   = {[192:255]};
      bins boundary_low = {0};
      bins boundary_high= {255};
      bins out_of_range = {[256:$]};
    }
    
    cp_addr_valid: coverpoint (trans.paddr < `MEM_DEPTH) {
      bins valid   = {1'b1};
      bins invalid = {1'b0};
    }
  endgroup
  
  // Data Coverage
  covergroup data_cg;
    option.per_instance = 1;
    option.name = "data_coverage";
    
    cp_pwdata: coverpoint trans.pwdata iff (trans.pwrite) {
      bins all_zeros     = {32'h00000000};
      bins all_ones      = {32'hFFFFFFFF};
      bins alternating_1 = {32'hAAAAAAAA};
      bins alternating_2 = {32'h55555555};
      bins low_range     = {[32'h00000001:32'h0FFFFFFF]};
      bins mid_range     = {[32'h10000000:32'hEFFFFFFF]};
      bins high_range    = {[32'hF0000000:32'hFFFFFFFE]};
    }
    
    cp_prdata: coverpoint trans.prdata iff (!trans.pwrite) {
      bins all_zeros     = {32'h00000000};
      bins all_ones      = {32'hFFFFFFFF};
      bins alternating_1 = {32'hAAAAAAAA};
      bins alternating_2 = {32'h55555555};
      bins other         = default;
    }
  endgroup
  
  // Byte Strobe Coverage
  covergroup pstrb_cg;
    option.per_instance = 1;
    option.name = "byte_strobe_coverage";
    
    cp_pstrb: coverpoint trans.pstrb iff (trans.pwrite) {
      bins all_bytes    = {4'b1111};
      bins byte0_only   = {4'b0001};
      bins byte1_only   = {4'b0010};
      bins byte2_only   = {4'b0100};
      bins byte3_only   = {4'b1000};
      bins lower_half   = {4'b0011};
      bins upper_half   = {4'b1100};
      bins byte0_2      = {4'b0101};
      bins byte1_3      = {4'b1010};
      bins three_bytes_low  = {4'b0111};
      bins three_bytes_high = {4'b1110};
      bins three_bytes_01_3 = {4'b1011};
      bins three_bytes_0_23 = {4'b1101};
      bins no_bytes     = {4'b0000};
    }
  endgroup
  
  // Transfer Type Coverage
  covergroup transfer_cg;
    option.per_instance = 1;
    option.name = "transfer_type_coverage";
    
    cp_operation: cross trans.pwrite, trans.psel {
      bins write_selected = binsof(trans.pwrite) intersect {1} && 
                           binsof(trans.psel) intersect {1};
      bins read_selected  = binsof(trans.pwrite) intersect {0} && 
                           binsof(trans.psel) intersect {1};
      bins idle          = binsof(trans.psel) intersect {0};
    }
  endgroup
  
  // Write Operation Coverage
  covergroup write_cg;
    option.per_instance = 1;
    option.name = "write_operation_coverage";
    
    cp_write_addr: coverpoint trans.paddr iff (trans.pwrite && trans.psel) {
      bins addr_ranges[] = {[0:15], [16:31], [32:63], [64:127], 
                           [128:191], [192:239], [240:255]};
    }
    
    cp_write_strb_addr: cross trans.pstrb, trans.paddr iff (trans.pwrite && trans.psel) {
      option.cross_auto_bin_max = 16;
    }
  endgroup
  
  // Read Operation Coverage
  covergroup read_cg;
    option.per_instance = 1;
    option.name = "read_operation_coverage";
    
    cp_read_addr: coverpoint trans.paddr iff (!trans.pwrite && trans.psel) {
      bins addr_ranges[] = {[0:15], [16:31], [32:63], [64:127], 
                           [128:191], [192:239], [240:255]};
    }
    
    cp_read_data_valid: cross trans.prdata, trans.pslverr iff (!trans.pwrite && trans.psel) {
      bins valid_read = binsof(trans.pslverr) intersect {0};
      bins error_read = binsof(trans.pslverr) intersect {1};
    }
  endgroup
  
  // Error Condition Coverage
  covergroup error_cg;
    option.per_instance = 1;
    option.name = "error_condition_coverage";
    
    cp_error_addr: cross trans.pslverr, trans.paddr, trans.psel {
      bins error_on_invalid_addr = binsof(trans.pslverr) intersect {1} &&
                                   binsof(trans.psel) intersect {1} &&
                                   binsof(trans.paddr) intersect {[256:$]};
      bins no_error_on_valid = binsof(trans.pslverr) intersect {0} &&
                              binsof(trans.psel) intersect {1} &&
                              binsof(trans.paddr) intersect {[0:255]};
    }
    
    cp_error_pattern: coverpoint trans.prdata iff (trans.pslverr) {
      bins error_pattern = {32'hFFFFFFFF};
      bins other = default;
    }
  endgroup
  
  // Boundary Condition Coverage
  covergroup boundary_cg;
    option.per_instance = 1;
    option.name = "boundary_condition_coverage";
    
    cp_boundary_addr: coverpoint trans.paddr {
      bins first_addr     = {0};
      bins last_valid     = {255};
      bins first_invalid  = {256};
      bins max_addr       = {8'hFF};
    }
    
    cp_boundary_data: coverpoint trans.pwdata iff (trans.pwrite) {
      bins min_val = {32'h00000000};
      bins max_val = {32'hFFFFFFFF};
      bins mid_val = {32'h80000000};
    }
  endgroup

  //============================================================================
  // Constructor and Methods
  //============================================================================
  
  function new(string name = "apb_subscriber", uvm_component parent=null);
    super.new(name, parent);
    
    // Create coverage groups
    apb_protocol_cg = new();
    address_cg      = new();
    data_cg         = new();
    pstrb_cg        = new();
    transfer_cg     = new();
    write_cg        = new();
    read_cg         = new();
    error_cg        = new();
    boundary_cg     = new();
  endfunction
  
  // Sample coverage when transaction arrives
  function void write(apb_sequence_item t);
    trans = t;
    
    // Sample all coverage groups
    apb_protocol_cg.sample();
    address_cg.sample();
    data_cg.sample();
    pstrb_cg.sample();
    transfer_cg.sample();
    
    if (trans.pwrite && trans.psel) begin
      write_cg.sample();
    end
    
    if (!trans.pwrite && trans.psel) begin
      read_cg.sample();
    end
    
    error_cg.sample();
    boundary_cg.sample();
  endfunction

  function void extract_phase(uvm_phase phase);
    real protocol_cov, addr_cov, data_cov, strb_cov, transfer_cov;
    real write_op_cov, read_op_cov, error_cov_val, boundary_cov_val;
    
    super.extract_phase(phase);
    
    protocol_cov    = apb_protocol_cg.get_coverage();
    addr_cov        = address_cg.get_coverage();
    data_cov        = data_cg.get_coverage();
    strb_cov        = pstrb_cg.get_coverage();
    transfer_cov    = transfer_cg.get_coverage();
    write_op_cov    = write_cg.get_coverage();
    read_op_cov     = read_cg.get_coverage();
    error_cov_val   = error_cg.get_coverage();
    boundary_cov_val= boundary_cg.get_coverage();
    
    total_cov = (protocol_cov + addr_cov + data_cov + strb_cov + 
                transfer_cov + write_op_cov + read_op_cov + 
                error_cov_val + boundary_cov_val) / 9.0;
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    
    `uvm_info(get_type_name(), "============================================", UVM_LOW);
    `uvm_info(get_type_name(), "      FUNCTIONAL COVERAGE REPORT           ", UVM_LOW);
    `uvm_info(get_type_name(), "============================================", UVM_LOW);
    `uvm_info(get_type_name(), $sformatf("Protocol Coverage:    %0.2f%%", apb_protocol_cg.get_coverage()), UVM_LOW);
    `uvm_info(get_type_name(), $sformatf("Address Coverage:     %0.2f%%", address_cg.get_coverage()), UVM_LOW);
    `uvm_info(get_type_name(), $sformatf("Data Coverage:        %0.2f%%", data_cg.get_coverage()), UVM_LOW);
    `uvm_info(get_type_name(), $sformatf("Byte Strobe Coverage: %0.2f%%", pstrb_cg.get_coverage()), UVM_LOW);
    `uvm_info(get_type_name(), $sformatf("Transfer Coverage:    %0.2f%%", transfer_cg.get_coverage()), UVM_LOW);
    `uvm_info(get_type_name(), $sformatf("Write Op Coverage:    %0.2f%%", write_cg.get_coverage()), UVM_LOW);
    `uvm_info(get_type_name(), $sformatf("Read Op Coverage:     %0.2f%%", read_cg.get_coverage()), UVM_LOW);
    `uvm_info(get_type_name(), $sformatf("Error Coverage:       %0.2f%%", error_cg.get_coverage()), UVM_LOW);
    `uvm_info(get_type_name(), $sformatf("Boundary Coverage:    %0.2f%%", boundary_cg.get_coverage()), UVM_LOW);
    `uvm_info(get_type_name(), "--------------------------------------------", UVM_LOW);
    `uvm_info(get_type_name(), $sformatf("OVERALL COVERAGE:     %0.2f%%", total_cov), UVM_LOW);
    `uvm_info(get_type_name(), "============================================", UVM_LOW);
  endfunction 
  
endclass
