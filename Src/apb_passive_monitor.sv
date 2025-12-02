class apb_passive_monitor extends uvm_monitor;
  `uvm_component_utils(apb_passive_monitor)
  
  virtual apb_if vif;
  uvm_analysis_port#(apb_sequence_item) mon_port;
  apb_sequence_item mon_trans;
    
  function new(string name="apb_passive_monitor", uvm_component parent=null);
    super.new(name, parent);
    mon_port = new("mon_port", this);
  endfunction
    
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", "No virtual interface found");
    end
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    // Wait for reset deassertion
    @(posedge vif.presetn);
    `uvm_info(get_type_name(), $sformatf("[%0t] Reset De-asserted", $time), UVM_LOW)
    
    @(vif.pas_mon_cb);
    
    forever begin
      @(vif.pas_mon_cb);
      // Capture outputs when there's a valid transfer
      // We check the interface directly for PSEL and PENABLE
      if (vif.psel && vif.penable) begin
        mon_trans = apb_sequence_item::type_id::create("mon_trans");
        capture_outputs();
        mon_port.write(mon_trans);
        
        `uvm_info(get_type_name(), 
                  $sformatf("[%0t] Captured Outputs: PRDATA=0x%0h, PREADY=%0b, PSLVERR=%0b", 
                           $time, 
                           mon_trans.prdata, 
                           mon_trans.pready,
                           mon_trans.pslverr), 
                  UVM_MEDIUM)
      end
    end
  endtask             
         
  // Capture output signals
  virtual task capture_outputs();
    mon_trans.prdata  = vif.pas_mon_cb.prdata;
    mon_trans.pready  = vif.pas_mon_cb.pready;
    mon_trans.pslverr = vif.pas_mon_cb.pslverr;
  endtask
  
endclass
