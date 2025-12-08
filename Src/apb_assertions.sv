module apb_assertions (
  input logic                    pclk,
  input logic                    presetn,
  input logic [`ADDR_WIDTH-1:0]  paddr,
  input logic                    psel,
  input logic                    penable,
  input logic                    pwrite,
  input logic [`DATA_WIDTH-1:0]  pwdata,
  input logic [`STRB_WIDTH-1:0]  pstrb,
  input logic [`DATA_WIDTH-1:0]  prdata,
  input logic                    pready,
  input logic                    pslverr
);


  property pclk_valid_check;
    @(posedge pclk) !$isunknown(pclk);
  endproperty
  assert_pclk_valid: assert property (pclk_valid_check)
    else $error("[ASSERTION FAIL] Clock signal is unknown at time %0t", $time);

  property presetn_valid_check;
    @(posedge pclk) !$isunknown(presetn);
  endproperty
  assert_presetn_valid: assert property (presetn_valid_check)
    else $error("[ASSERTION FAIL] Reset signal is unknown at time %0t", $time);
  // PSEL should be followed by PENABLE in next cycle
  property psel_followed_by_penable;
    @(posedge pclk) disable iff (!presetn)
    $rose(psel) |=> penable;
  endproperty
  assert_psel_penable_seq: assert property (psel_followed_by_penable)
    else $error("[ASSERTION FAIL] PSEL not followed by PENABLE at time %0t", $time);

  // Error occurs for out-of-range addresses during transfer
  property error_on_invalid_addr;
    @(posedge pclk) disable iff (!presetn)
    (psel && penable && (paddr >= `MEM_DEPTH)) |-> pslverr;
  endproperty
  assert_error_invalid_addr: assert property (error_on_invalid_addr)
    else $error("[ASSERTION FAIL] Missing error for invalid address 0x%0h at time %0t", paddr, $time);

  // No error for valid addresses
  property no_error_valid_addr;
    @(posedge pclk) disable iff (!presetn)
    (psel && penable && (paddr < `MEM_DEPTH)) |-> !pslverr;
  endproperty
  assert_no_error_valid: assert property (no_error_valid_addr)
    else $error("[ASSERTION FAIL] Unexpected error for valid address 0x%0h at time %0t", paddr, $time);

  // PADDR stable from SETUP to ACCESS phase
  property addr_stable;
    @(posedge pclk) disable iff (!presetn)
    (psel && !penable) |=> $stable(paddr);
  endproperty
  assert_addr_stable: assert property (addr_stable)
    else $error("[ASSERTION FAIL] PADDR changed during transfer at time %0t", $time);

  // PWRITE stable during transfer
  property pwrite_stable;
    @(posedge pclk) disable iff (!presetn)
    (psel && !penable) |=> $stable(pwrite);
  endproperty
  assert_pwrite_stable: assert property (pwrite_stable)
    else $error("[ASSERTION FAIL] PWRITE changed during transfer at time %0t", $time);

  // PWDATA stable during write transfer
  property pwdata_stable_write;
    @(posedge pclk) disable iff (!presetn)
    (psel && !penable && pwrite) |=> $stable(pwdata);
  endproperty
  assert_pwdata_stable: assert property (pwdata_stable_write)
    else $error("[ASSERTION FAIL] PWDATA changed during write transfer at time %0t", $time);

  // PSTRB stable during write transfer
  property pstrb_stable_write;
    @(posedge pclk) disable iff (!presetn)
    (psel && !penable && pwrite) |=> $stable(pstrb);
  endproperty
  assert_pstrb_stable: assert property (pstrb_stable_write)
    else $error("[ASSERTION FAIL] PSTRB changed during write transfer at time %0t", $time);

  // Read data valid when PREADY asserted during read
  property read_data_valid;
    @(posedge pclk) disable iff (!presetn)
    (psel && penable && !pwrite && pready) |-> !$isunknown(prdata);
  endproperty
  assert_read_data_valid: assert property (read_data_valid)
    else $error("[ASSERTION FAIL] PRDATA unknown during valid read at time %0t", $time);

  // PSTRB validity during write
  property pstrb_valid_write;
    @(posedge pclk) disable iff (!presetn)
    (psel && penable && pwrite) |-> !$isunknown(pstrb);
  endproperty
  assert_pstrb_valid: assert property (pstrb_valid_write)
    else $error("[ASSERTION FAIL] PSTRB unknown during write at time %0t", $time);

  // PWDATA validity during write
  property pwdata_valid_write;
    @(posedge pclk) disable iff (!presetn)
    (psel && penable && pwrite) |-> !$isunknown(pwdata);
  endproperty
  assert_pwdata_valid: assert property (pwdata_valid_write)
    else $error("[ASSERTION FAIL] PWDATA unknown during write at time %0t", $time);

  // No back-to-back ACCESS phases
  property no_continuous_access;
    @(posedge pclk) disable iff (!presetn)
    (psel && penable && pready) |=> !penable;
  endproperty
  assert_no_continuous_access: assert property (no_continuous_access)
    else $error("[ASSERTION FAIL] Continuous ACCESS phase without IDLE/SETUP at time %0t", $time);

endmodule
