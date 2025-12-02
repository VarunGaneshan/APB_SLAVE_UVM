class apb_passive_agent extends uvm_agent;
  `uvm_component_utils(apb_passive_agent)
  
  apb_passive_monitor passive_monitor;

  function new(string name = "apb_passive_agent", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    passive_monitor = apb_passive_monitor::type_id::create("passive_monitor", this);
  endfunction

endclass
