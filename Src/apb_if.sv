interface apb_if(input bit pclk, presetn);
  logic [`ADDR_WIDTH-1:0]   paddr;      // Address bus
  logic                     psel;       // Slave select
  logic                     penable;    // Enable signal
  logic                     pwrite;     // Write control (1=Write, 0=Read)
  logic [`DATA_WIDTH-1:0]   pwdata;     // Write data
  logic [`STRB_WIDTH-1:0]   pstrb;      // Write strobe (byte enables)
  logic [`DATA_WIDTH-1:0]   prdata;     // Read data
  logic                     pready;     // Ready signal
  logic                     pslverr;    // Error signal

  // Driver clocking block - drives inputs to DUT
  clocking drv_cb @(posedge pclk);
    default input #1step output #1ns;
    input  presetn;
    output paddr;
    output psel;
    output penable;
    output pwrite;
    output pwdata;
    output pstrb;
  endclocking 
  
  // Active monitor clocking block - monitors inputs to DUT
  clocking act_mon_cb @(posedge pclk);
    default input #1step;
    input presetn;
    input paddr;
    input psel;
    input penable;
    input pwrite;
    input pwdata;
    input pstrb;
  endclocking

  // Passive monitor clocking block - monitors outputs from DUT
  clocking pas_mon_cb @(posedge pclk);
    default input #1step;
    input presetn;
    input prdata;
    input pready;
    input pslverr;
  endclocking

  // Scoreboard clocking block
  clocking sb_cb @(posedge pclk);
    default input #1step;
    input presetn;
    input paddr;
    input psel;
    input penable;
    input pwrite;
  endclocking 

  // Modports for structured connections
  modport DRV(clocking drv_cb);
  modport ACT_MON(clocking act_mon_cb);
  modport PAS_MON(clocking pas_mon_cb);
  modport SB(clocking sb_cb);

endinterface
