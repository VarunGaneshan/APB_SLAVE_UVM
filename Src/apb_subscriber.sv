class apb_subscriber extends uvm_component;
  `uvm_component_utils(apb_subscriber)
  
  apb_sequence_item t1, t2;
  real ip_cov, op_cov;
  
  uvm_tlm_analysis_fifo #(apb_sequence_item) ip_fifo;
  uvm_tlm_analysis_fifo #(apb_sequence_item) op_fifo;
  
  covergroup input_cov;
    PADDR_WRITE: coverpoint t1.paddr iff (t1.pwrite) {
      bins low_range = {[0:84]};
      bins mid_range = {[85:169]};
      bins high_range = {[170:255]};
    }
    
    PADDR_READ: coverpoint t1.paddr iff (!t1.pwrite) {
      bins low_range = {[0:84]};
      bins mid_range = {[85:169]};
      bins high_range = {[170:255]};
    }
    
    PWDATA: coverpoint t1.pwdata iff (t1.pwrite) {
      bins low_range = {[0:32'h55555555]};
      bins mid_range = {[32'h55555556:32'hAAAAAAAA]};
      bins high_range = {[32'hAAAAAAAB:32'hFFFFFFFF]};
    }
    
    PSTRB: coverpoint t1.pstrb iff (t1.pwrite) {
      bins strobe_bins[]={[1:15]};
    }
    
    WRITE_ADDR_X_STRB: cross PADDR_WRITE, PSTRB;
  endgroup
  
  covergroup output_cov;
    PRDATA: coverpoint t2.prdata {
      bins low_range = {[0:32'h55555555]};
      bins mid_range = {[32'h55555556:32'hAAAAAAAA]};
      bins high_range = {[32'hAAAAAAAB:32'hFFFFFFFF]};
    }
    
    PREADY: coverpoint t2.pready {
      bins ready = {1};
      ignore_bins not_ready = {0};
    }
    
    PSLVERR: coverpoint t2.pslverr {
      bins no_error = {0};
      ignore_bins error = {1};
    }
  endgroup

  function new(string name = "apb_subscriber", uvm_component parent=null);
    super.new(name, parent);
    ip_fifo = new("ip_fifo", this);
    op_fifo = new("op_fifo", this);
    input_cov = new();
    output_cov = new();
  endfunction
  
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      ip_fifo.get(t1);
      input_cov.sample();
      op_fifo.get(t2);
      output_cov.sample();
    end
  endtask
  
  function void extract_phase(uvm_phase phase);
    super.extract_phase(phase);
    ip_cov = input_cov.get_coverage();
    op_cov = output_cov.get_coverage();
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), "============================================", UVM_LOW);
    `uvm_info(get_type_name(), "      FUNCTIONAL COVERAGE REPORT           ", UVM_LOW);
    `uvm_info(get_type_name(), "============================================", UVM_LOW);
    `uvm_info(get_type_name(), $sformatf("Input Coverage:  %0.2f%%", ip_cov), UVM_LOW);
    `uvm_info(get_type_name(), $sformatf("Output Coverage: %0.2f%%", op_cov), UVM_LOW);
    `uvm_info(get_type_name(), "============================================", UVM_LOW);
  endfunction 
  
endclass
