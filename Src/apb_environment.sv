class apb_env extends uvm_env;
  `uvm_component_utils(apb_env)

  apb_active_agent  active_agent;
  apb_passive_agent passive_agent;
  apb_scoreboard    scoreboard;
  apb_subscriber    subscriber;

  function new(string name="apb_env", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    active_agent  = apb_active_agent::type_id::create("active_agent", this);
    passive_agent = apb_passive_agent::type_id::create("passive_agent", this);
    scoreboard = apb_scoreboard::type_id::create("scoreboard", this);
    subscriber = apb_subscriber::type_id::create("subscriber", this);
    
    // Set agent configuration
    uvm_config_db#(int)::set(this, "active_agent", "is_active", UVM_ACTIVE);
    uvm_config_db#(int)::set(this, "passive_agent", "is_active", UVM_PASSIVE);
    
    `uvm_info(get_type_name(), "Build phase complete", UVM_HIGH)
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // Connect active monitor to scoreboard and coverage
    active_agent.active_monitor.mon_port.connect(scoreboard.ip_fifo.analysis_export);
    active_agent.active_monitor.mon_port.connect(subscriber.analysis_export);
    
    // Connect passive monitor to scoreboard
    passive_agent.passive_monitor.mon_port.connect(scoreboard.op_fifo.analysis_export);
    
    `uvm_info(get_type_name(), "Connect phase complete", UVM_HIGH)
  endfunction
  
  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    `uvm_info(get_type_name(), "Topology:", UVM_LOW)
    uvm_top.print_topology();
  endfunction

endclass


