class apb_driver extends uvm_driver#(apb_sequence_item);
  `uvm_component_utils(apb_driver)
  
  virtual apb_if vif;
  apb_sequence_item drv_trans;
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", "No virtual interface found")
    end
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    if(!vif.presetn) begin
      `uvm_info(get_type_name(), $sformatf("[%0t] Waiting for reset deassertion", $time), UVM_LOW)
      @(posedge vif.presetn);
    end

    initialize_signals();
    @(vif.drv_cb);
    
    forever begin
      seq_item_port.get_next_item(drv_trans);
      drive_transaction();
      seq_item_port.item_done();
    end
  endtask

  // Initialize all driver signals to idle state
  task initialize_signals();
    vif.paddr   <= '0;
    vif.psel    <= 1'b0;
    vif.penable <= 1'b0;
    vif.pwrite  <= 1'b0;
    vif.pwdata  <= '0;
    vif.pstrb   <= '0;
  endtask

  // Drive APB transaction with proper SETUP and ACCESS phases
  task drive_transaction();
    if (drv_trans.psel) begin
      // SETUP Phase
      @(vif.drv_cb);
      vif.drv_cb.paddr   <= drv_trans.paddr;
      vif.drv_cb.psel    <= 1'b1;
      vif.drv_cb.penable <= 1'b0;
      vif.drv_cb.pwrite  <= drv_trans.pwrite;
      
      if (drv_trans.pwrite) begin
        vif.drv_cb.pwdata <= drv_trans.pwdata;
        vif.drv_cb.pstrb  <= drv_trans.pstrb;
      end else begin
        vif.drv_cb.pwdata <= '0;
        vif.drv_cb.pstrb  <= '0;
      end
      
      `uvm_info(get_type_name(), 
                $sformatf("[%0t] SETUP Phase - %s: ADDR=0x%0h, DATA=0x%0h, STRB=0b%04b", 
                         $time, drv_trans.pwrite ? "WRITE" : "READ", 
                         drv_trans.paddr, drv_trans.pwdata, drv_trans.pstrb), 
                UVM_MEDIUM)
      
      // ACCESS Phase
      @(vif.drv_cb);
      vif.drv_cb.penable <= 1'b1;
      
      // Wait for PREADY (for this slave it's always 1, but good practice)
      wait(vif.pready == 1'b1);
      
      `uvm_info(get_type_name(), 
                $sformatf("[%0t] ACCESS Phase - Transfer Complete", $time), 
                UVM_MEDIUM)
      
      // Return to IDLE
      @(vif.drv_cb);
      vif.drv_cb.psel    <= 1'b0;
      vif.drv_cb.penable <= 1'b0;
      vif.drv_cb.pwrite  <= 1'b0;
      vif.drv_cb.paddr   <= '0;
      vif.drv_cb.pwdata  <= '0;
      vif.drv_cb.pstrb   <= '0;
      
    end else begin
      // IDLE cycle
      @(vif.drv_cb);
      vif.drv_cb.psel    <= 1'b0;
      vif.drv_cb.penable <= 1'b0;
      `uvm_info(get_type_name(), $sformatf("[%0t] IDLE Cycle", $time), UVM_HIGH)
    end
  endtask
  
endclass

