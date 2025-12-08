 class apb_base_test extends uvm_test;
  `uvm_component_utils(apb_base_test)
  
  apb_env env;

  function new(string name = "apb_base_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = apb_env::type_id::create("env", this);
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    `uvm_info(get_type_name(), "Topology:", UVM_LOW)
    uvm_top.print_topology();
  endfunction

  
  virtual function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    `uvm_info(get_type_name(), "=== TEST STARTED ===", UVM_LOW)
  endfunction

  virtual function void report_phase(uvm_phase phase);
    uvm_report_server svr;
    super.report_phase(phase);
    
    svr = uvm_report_server::get_server();
    
    `uvm_info(get_type_name(), "=== TEST COMPLETE ===", UVM_LOW)
    
    if(svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR) == 0) begin
      `uvm_info(get_type_name(), "*** TEST PASSED ***", UVM_LOW)
    end else begin
      `uvm_error(get_type_name(), "*** TEST FAILED ***")
    end
  endfunction
endclass

class apb_write_test extends apb_base_test;
  `uvm_component_utils(apb_write_test)
  
  apb_write_sequence seq;

  function new(string name = "apb_write_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this);
    
    seq = apb_write_sequence::type_id::create("seq");
    seq.start(env.active_agent.sequencer);
    
    #100;
    phase.drop_objection(this);
  endtask
endclass

class apb_read_test extends apb_base_test;
  `uvm_component_utils(apb_read_test) 
  
  apb_read_sequence seq;

  function new(string name = "apb_read_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this);
    
    seq = apb_read_sequence::type_id::create("seq");
    seq.start(env.active_agent.sequencer);
    
    #100;
    phase.drop_objection(this);
  endtask
endclass

class apb_write_read_test extends apb_base_test;
  `uvm_component_utils(apb_write_read_test)
  
  apb_write_read_sequence seq;

  function new(string name = "apb_write_read_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this);
    
    seq = apb_write_read_sequence::type_id::create("seq");
    seq.start(env.active_agent.sequencer);
    
    #100;
    phase.drop_objection(this);
  endtask
endclass

class apb_byte_strobe_test extends apb_base_test;
  `uvm_component_utils(apb_byte_strobe_test)
  
  apb_byte_strobe_sequence seq;

  function new(string name = "apb_byte_strobe_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this);
    
    seq = apb_byte_strobe_sequence::type_id::create("seq");
    seq.start(env.active_agent.sequencer);
    
    #100;
    phase.drop_objection(this);
  endtask
endclass

class apb_error_test extends apb_base_test;
  `uvm_component_utils(apb_error_test)
  
  apb_error_sequence seq;

  function new(string name = "apb_error_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this);
    
    repeat(10) begin
      seq = apb_error_sequence::type_id::create("seq");
      seq.start(env.active_agent.sequencer);
    end
    
    #100;
    phase.drop_objection(this);
  endtask
endclass

class apb_random_test extends apb_base_test;
  `uvm_component_utils(apb_random_test)
  
  apb_random_sequence seq;

  function new(string name = "apb_random_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this);
    
    seq = apb_random_sequence::type_id::create("seq");
    seq.start(env.active_agent.sequencer);
    
    #100;
    phase.drop_objection(this);
  endtask
endclass

class apb_burst_test extends apb_base_test;
  `uvm_component_utils(apb_burst_test)
  
  apb_burst_write_sequence write_seq;
  apb_burst_read_sequence read_seq;

  function new(string name = "apb_burst_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this);
    
    write_seq = apb_burst_write_sequence::type_id::create("write_seq");
    write_seq.burst_length = 32;
    write_seq.start(env.active_agent.sequencer);
    
    read_seq = apb_burst_read_sequence::type_id::create("read_seq");
    read_seq.burst_length = 32;
    read_seq.start(env.active_agent.sequencer);
    
    #100;
    phase.drop_objection(this);
  endtask
endclass

class apb_regression_test extends apb_base_test;
  `uvm_component_utils(apb_regression_test)
  
  apb_write_read_sequence wr_seq;
  apb_byte_strobe_sequence strb_seq;
  apb_error_sequence err_seq;
  apb_random_sequence rand_seq;
  apb_burst_write_sequence burst_w_seq;
  apb_burst_read_sequence burst_r_seq;

  function new(string name = "apb_regression_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this);
    
    `uvm_info(get_type_name(), "Starting Write-Read sequence", UVM_LOW)
    wr_seq = apb_write_read_sequence::type_id::create("wr_seq");
    wr_seq.start(env.active_agent.sequencer);
    
    `uvm_info(get_type_name(), "Starting Byte Strobe sequence", UVM_LOW)
    strb_seq = apb_byte_strobe_sequence::type_id::create("strb_seq");
    strb_seq.start(env.active_agent.sequencer);
    
    `uvm_info(get_type_name(), "Starting Error sequence", UVM_LOW)
    repeat(5) begin
      err_seq = apb_error_sequence::type_id::create("err_seq");
      err_seq.start(env.active_agent.sequencer);
    end
    
    `uvm_info(get_type_name(), "Starting Burst sequences", UVM_LOW)
    burst_w_seq = apb_burst_write_sequence::type_id::create("burst_w_seq");
    burst_w_seq.burst_length = 64;
    burst_w_seq.start(env.active_agent.sequencer);
    
    burst_r_seq = apb_burst_read_sequence::type_id::create("burst_r_seq");
    burst_r_seq.burst_length = 64;
    burst_r_seq.start(env.active_agent.sequencer);
    
    `uvm_info(get_type_name(), "Starting Random sequence", UVM_LOW)
    rand_seq = apb_random_sequence::type_id::create("rand_seq");
    rand_seq.start(env.active_agent.sequencer);

    phase.drop_objection(this);
  endtask
endclass
