class apb_active_agent extends uvm_agent;
  	`uvm_component_utils(apb_active_agent)
	apb_driver driver;
	apb_sequencer sequencer;
	apb_active_monitor active_monitor;

  	function new(string name = "apb_active_agent", uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(get_is_active() == UVM_ACTIVE)begin
			driver = apb_driver::type_id::create("driver",this);
			sequencer = apb_sequencer::type_id::create("sequencer",this);
		end
		active_monitor = apb_active_monitor::type_id::create("active_monitor",this);
	endfunction

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		if(get_is_active() == UVM_ACTIVE)
			driver.seq_item_port.connect(sequencer.seq_item_export);
	endfunction
endclass
