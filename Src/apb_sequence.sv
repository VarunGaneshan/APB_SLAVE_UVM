//==============================================================================
// Base Sequence
//==============================================================================
class apb_base_sequence extends uvm_sequence #(apb_sequence_item);
  `uvm_object_utils(apb_base_sequence)
  int no_of_trans;
  
  function new(string name="apb_base_sequence");
    super.new(name);
  endfunction
endclass

//==============================================================================
// Write Sequence - Sequential writes with full byte strobes
//==============================================================================
class apb_write_sequence extends uvm_sequence #(apb_sequence_item);
  `uvm_object_utils(apb_write_sequence)
  int no_of_trans;
  
  function new(string name="apb_write_sequence");
    super.new(name);
  endfunction
 
  virtual task body();
    apb_sequence_item item;
    
    if (!$value$plusargs("no_of_trans=%d", no_of_trans)) begin
      no_of_trans = 10;
    end
    
    repeat (no_of_trans) begin
      item = apb_sequence_item::type_id::create("write_item");
      start_item(item);
      assert(item.randomize() with {
        psel == 1'b1;
        pwrite == 1'b1;
        pstrb == 4'b1111;  // All bytes enabled
        paddr inside {[0:`MEM_DEPTH-1]};
      });
      `uvm_info(get_type_name(), 
                $sformatf("Write: ADDR=0x%0h, DATA=0x%0h, STRB=0b%04b", 
                         item.paddr, item.pwdata, item.pstrb), 
                UVM_MEDIUM);
      finish_item(item);
    end
  endtask
endclass

//==============================================================================
// Read Sequence - Sequential reads
//==============================================================================
class apb_read_sequence extends uvm_sequence #(apb_sequence_item);
  `uvm_object_utils(apb_read_sequence)
  int no_of_trans;
  
  function new(string name="apb_read_sequence");
    super.new(name);
  endfunction
 
  virtual task body();
    apb_sequence_item item;
    
    if (!$value$plusargs("no_of_trans=%d", no_of_trans)) begin
      no_of_trans = 10;
    end
    
    repeat (no_of_trans) begin
      item = apb_sequence_item::type_id::create("read_item");
      start_item(item);
      assert(item.randomize() with {
        psel == 1'b1;
        pwrite == 1'b0;
        paddr inside {[0:`MEM_DEPTH-1]};
      });
      `uvm_info(get_type_name(), 
                $sformatf("Read: ADDR=0x%0h", item.paddr), 
                UVM_MEDIUM);
      finish_item(item);
    end
  endtask
endclass

//==============================================================================
// Write-Read Sequence - Write followed by read from same address
//==============================================================================
class apb_write_read_sequence extends uvm_sequence #(apb_sequence_item);
  `uvm_object_utils(apb_write_read_sequence)
  int no_of_trans;
  
  function new(string name="apb_write_read_sequence");
    super.new(name);
  endfunction
 
  virtual task body();
    apb_sequence_item item;
    logic [`ADDR_WIDTH-1:0] addr;
    logic [`DATA_WIDTH-1:0] data;
    
    if (!$value$plusargs("no_of_trans=%d", no_of_trans)) begin
      no_of_trans = 10;
    end
    
    repeat (no_of_trans) begin
      // Write
      item = apb_sequence_item::type_id::create("write_item");
      start_item(item);
      assert(item.randomize() with {
        psel == 1'b1;
        pwrite == 1'b1;
        pstrb == 4'b1111;
        paddr inside {[0:`MEM_DEPTH-1]};
      });
      addr = item.paddr;
      data = item.pwdata;
      `uvm_info(get_type_name(), 
                $sformatf("Write: ADDR=0x%0h, DATA=0x%0h", addr, data), 
                UVM_MEDIUM);
      finish_item(item);
      
      // Read back
      item = apb_sequence_item::type_id::create("read_item");
      start_item(item);
      assert(item.randomize() with {
        psel == 1'b1;
        pwrite == 1'b0;
        paddr == addr;
      });
      `uvm_info(get_type_name(), 
                $sformatf("Read: ADDR=0x%0h (expect DATA=0x%0h)", addr, data), 
                UVM_MEDIUM);
      finish_item(item);
    end
  endtask
endclass

//==============================================================================
// Byte Strobe Sequence - Test partial byte writes
//==============================================================================
class apb_byte_strobe_sequence extends uvm_sequence #(apb_sequence_item);
  `uvm_object_utils(apb_byte_strobe_sequence)
  
  function new(string name="apb_byte_strobe_sequence");
    super.new(name);
  endfunction
 
  virtual task body();
    apb_sequence_item item;
    logic [`ADDR_WIDTH-1:0] test_addr;
    
    test_addr = $urandom_range(0, `MEM_DEPTH-1);
    
    // Test all byte strobe combinations
    foreach ({4'b0001, 4'b0010, 4'b0100, 4'b1000, 
              4'b0011, 4'b1100, 4'b0101, 4'b1010,
              4'b0111, 4'b1110, 4'b1011, 4'b1101,
              4'b1111}[i]) begin
      item = apb_sequence_item::type_id::create("strb_item");
      start_item(item);
      assert(item.randomize() with {
        psel == 1'b1;
        pwrite == 1'b1;
        paddr == test_addr;
        pstrb == {4'b0001, 4'b0010, 4'b0100, 4'b1000, 
                  4'b0011, 4'b1100, 4'b0101, 4'b1010,
                  4'b0111, 4'b1110, 4'b1011, 4'b1101,
                  4'b1111}[i];
      });
      `uvm_info(get_type_name(), 
                $sformatf("STRB Test: ADDR=0x%0h, DATA=0x%0h, STRB=0b%04b", 
                         item.paddr, item.pwdata, item.pstrb), 
                UVM_MEDIUM);
      finish_item(item);
    end
  endtask
endclass

//==============================================================================
// Error Sequence - Out-of-range address accesses
//==============================================================================
class apb_error_sequence extends uvm_sequence #(apb_sequence_item);
  `uvm_object_utils(apb_error_sequence)
  
  function new(string name="apb_error_sequence");
    super.new(name);
  endfunction
 
  virtual task body();
    apb_sequence_item item;
    
    // Out-of-range write
    item = apb_sequence_item::type_id::create("error_write_item");
    start_item(item);
    item.paddr = `MEM_DEPTH + $urandom_range(0, 255);
    item.psel = 1'b1;
    item.pwrite = 1'b1;
    item.pwdata = $urandom();
    item.pstrb = 4'b1111;
    `uvm_info(get_type_name(), 
              $sformatf("Error Write: Out-of-range ADDR=0x%0h (>= %0d)", 
                       item.paddr, `MEM_DEPTH), 
              UVM_MEDIUM);
    finish_item(item);
    
    // Out-of-range read
    item = apb_sequence_item::type_id::create("error_read_item");
    start_item(item);
    item.paddr = `MEM_DEPTH + $urandom_range(0, 255);
    item.psel = 1'b1;
    item.pwrite = 1'b0;
    `uvm_info(get_type_name(), 
              $sformatf("Error Read: Out-of-range ADDR=0x%0h (expect PSLVERR=1, DATA=0xFFFFFFFF)", 
                       item.paddr), 
              UVM_MEDIUM);
    finish_item(item);
  endtask
endclass

//==============================================================================
// Random Sequence - Mixed random operations
//==============================================================================
class apb_random_sequence extends uvm_sequence #(apb_sequence_item);
  `uvm_object_utils(apb_random_sequence)
  int no_of_trans;
  
  function new(string name="apb_random_sequence");
    super.new(name);
  endfunction
 
  virtual task body();
    apb_sequence_item item;
    
    if (!$value$plusargs("no_of_trans=%d", no_of_trans)) begin
      no_of_trans = 100;
    end
    
    repeat (no_of_trans) begin
      item = apb_sequence_item::type_id::create("random_item");
      start_item(item);
      assert(item.randomize());
      `uvm_info(get_type_name(), 
                $sformatf("Random %s: ADDR=0x%0h, DATA=0x%0h, STRB=0b%04b", 
                         item.pwrite ? "WRITE" : "READ",
                         item.paddr, item.pwdata, item.pstrb), 
                UVM_HIGH);
      finish_item(item);
      
      // Add some idle cycles randomly
      if ($urandom_range(0, 9) < 2) begin
        item = apb_sequence_item::type_id::create("idle_item");
        start_item(item);
        item.psel = 1'b0;
        finish_item(item);
      end
    end
  endtask
endclass

//==============================================================================
// Burst Write Sequence - Sequential address writes
//==============================================================================
class apb_burst_write_sequence extends uvm_sequence #(apb_sequence_item);
  `uvm_object_utils(apb_burst_write_sequence)
  int burst_length;
  
  function new(string name="apb_burst_write_sequence");
    super.new(name);
  endfunction
 
  virtual task body();
    apb_sequence_item item;
    logic [`ADDR_WIDTH-1:0] start_addr;
    
    if (!$value$plusargs("burst_length=%d", burst_length)) begin
      burst_length = 16;
    end
    
    start_addr = $urandom_range(0, `MEM_DEPTH - burst_length);
    
    for (int i = 0; i < burst_length; i++) begin
      item = apb_sequence_item::type_id::create("burst_write_item");
      start_item(item);
      assert(item.randomize() with {
        psel == 1'b1;
        pwrite == 1'b1;
        paddr == start_addr + i;
        pstrb == 4'b1111;
      });
      `uvm_info(get_type_name(), 
                $sformatf("Burst Write [%0d/%0d]: ADDR=0x%0h, DATA=0x%0h", 
                         i+1, burst_length, item.paddr, item.pwdata), 
                UVM_MEDIUM);
      finish_item(item);
    end
  endtask
endclass

//==============================================================================
// Burst Read Sequence - Sequential address reads
//==============================================================================
class apb_burst_read_sequence extends uvm_sequence #(apb_sequence_item);
  `uvm_object_utils(apb_burst_read_sequence)
  int burst_length;
  
  function new(string name="apb_burst_read_sequence");
    super.new(name);
  endfunction
 
  virtual task body();
    apb_sequence_item item;
    logic [`ADDR_WIDTH-1:0] start_addr;
    
    if (!$value$plusargs("burst_length=%d", burst_length)) begin
      burst_length = 16;
    end
    
    start_addr = $urandom_range(0, `MEM_DEPTH - burst_length);
    
    for (int i = 0; i < burst_length; i++) begin
      item = apb_sequence_item::type_id::create("burst_read_item");
      start_item(item);
      assert(item.randomize() with {
        psel == 1'b1;
        pwrite == 1'b0;
        paddr == start_addr + i;
      });
      `uvm_info(get_type_name(), 
                $sformatf("Burst Read [%0d/%0d]: ADDR=0x%0h", 
                         i+1, burst_length, item.paddr), 
                UVM_MEDIUM);
      finish_item(item);
    end
  endtask
endclass

//==============================================================================
// Idle Sequence - Generate idle cycles
//==============================================================================
class apb_idle_sequence extends uvm_sequence #(apb_sequence_item);
  `uvm_object_utils(apb_idle_sequence)
  int idle_cycles;
  
  function new(string name="apb_idle_sequence");
    super.new(name);
  endfunction
 
  virtual task body();
    apb_sequence_item item;
    
    if (!$value$plusargs("idle_cycles=%d", idle_cycles)) begin
      idle_cycles = 5;
    end
    
    repeat (idle_cycles) begin
      item = apb_sequence_item::type_id::create("idle_item");
      start_item(item);
      item.psel = 1'b0;
      item.penable = 1'b0;
      item.pwrite = 1'b0;
      item.paddr = '0;
      item.pwdata = '0;
      item.pstrb = '0;
      finish_item(item);
    end
  endtask
endclass
