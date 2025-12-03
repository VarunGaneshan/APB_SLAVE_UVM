class apb_sequence_item extends uvm_sequence_item;
  rand logic [`ADDR_WIDTH-1:0]   paddr;      
  rand logic                     psel;       
  rand logic                     pwrite;     
  rand logic [`DATA_WIDTH-1:0]   pwdata;   
  rand logic [`STRB_WIDTH-1:0]   pstrb;     
  
  logic [`DATA_WIDTH-1:0]        prdata;     
  logic                          pready;   
  logic                          pslverr;    

  constraint valid_addr_c {
    soft paddr inside {[0:`MEM_DEPTH-1]};  // Valid address range
  }
  
  constraint valid_strb_c {
    soft pstrb != 4'b0000;  // At least one byte should be enabled during write
  }

  constraint psel {
    soft psel == 1'b1; //PSEL mostly high for valid transfers
  }
  
  function new(string name="apb_sequence_item");
    super.new(name);
  endfunction
  
  `uvm_object_utils_begin(apb_sequence_item)
    `uvm_field_int(paddr,   UVM_ALL_ON)
    `uvm_field_int(psel,    UVM_ALL_ON)
    `uvm_field_int(pwrite,  UVM_ALL_ON)
    `uvm_field_int(pwdata,  UVM_ALL_ON)
    `uvm_field_int(pstrb,   UVM_ALL_ON)
    `uvm_field_int(prdata,  UVM_ALL_ON)
    `uvm_field_int(pready,  UVM_ALL_ON)
    `uvm_field_int(pslverr, UVM_ALL_ON)
  `uvm_object_utils_end 
  
  virtual function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_string("operation", pwrite ? "WRITE" : "READ");
    printer.print_field("paddr", paddr, $bits(paddr), UVM_HEX);
    if (pwrite) begin
      printer.print_field("pwdata", pwdata, $bits(pwdata), UVM_HEX);
      printer.print_field("pstrb", pstrb, $bits(pstrb), UVM_BIN);
    end else begin
      printer.print_field("prdata", prdata, $bits(prdata), UVM_HEX);
    end
    printer.print_field("pslverr", pslverr, 1, UVM_BIN);
  endfunction

endclass
