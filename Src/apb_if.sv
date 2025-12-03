interface apb_if(input bit pclk, presetn);
  logic [`ADDR_WIDTH-1:0]   paddr;     
  logic                     psel;    
  logic                     penable;  
  logic                     pwrite;    
  logic [`DATA_WIDTH-1:0]   pwdata;    
  logic [`STRB_WIDTH-1:0]   pstrb;    
  logic [`DATA_WIDTH-1:0]   prdata;    
  logic                     pready;   
  logic                     pslverr; 

  clocking drv_cb @(posedge pclk);
    input  presetn;
    input   pready;
    output paddr;
    output psel;
    output penable;
    output pwrite;
    output pwdata;
    output pstrb;
  endclocking 
  
  clocking act_mon_cb @(posedge pclk);
    input presetn;
    input paddr;
    input psel;
    input penable;
    input pwrite;
    input pwdata;
    input pstrb;
  endclocking

  clocking pas_mon_cb @(posedge pclk);
    input presetn;
    input prdata;
    input pready;
    input pslverr;
  endclocking
endinterface
