class apb_active_monitor extends uvm_monitor;
  `uvm_component_utils(apb_active_monitor)
  
  virtual apb_if vif;
  uvm_analysis_port#(apb_sequence_item) mon_port;
  apb_sequence_item mon_trans;
    
  function new(string name="apb_active_monitor", uvm_component parent=null);
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
    if(!vif.presetn) begin
      @(posedge vif.presetn);
    end
    
    forever begin
      // Wait for valid APB transfer at clock edge
      @(posedge vif.pclk);
      
      if (vif.psel && vif.penable) begin
        mon_trans = apb_sequence_item::type_id::create("mon_trans");
        capture_inputs();
        mon_port.write(mon_trans);
        
        `uvm_info(get_type_name(), 
                  $sformatf("[%0t] Captured APB %s: ADDR=0x%0h, WDATA=0x%0h, STRB=0b%04b", 
                           $time, 
                           mon_trans.pwrite ? "WRITE" : "READ",
                           mon_trans.paddr, 
                           mon_trans.pwdata,
                           mon_trans.pstrb), 
                          UVM_MEDIUM)
      end
    end
  endtask

  // Capture input signals during ACCESS phase
  task capture_inputs();
    mon_trans.paddr  = vif.paddr;
    mon_trans.psel   = vif.psel;
    mon_trans.pwrite = vif.pwrite;
    mon_trans.pwdata = vif.pwdata;
    mon_trans.pstrb  = vif.pstrb;
  endtask

endclass    