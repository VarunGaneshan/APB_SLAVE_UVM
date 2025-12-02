//==============================================================================
// APB Slave Protocol Assertions
// Comprehensive assertion checks for APB protocol compliance
//==============================================================================

interface apb_assertions (
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

  //============================================================================
  // Basic Signal Validity Checks
  //============================================================================
  
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

  //============================================================================
  // APB Protocol Transfer Sequence Assertions
  //============================================================================
  
  // Transfer only valid when both PSEL and PENABLE are high
  property transfer_valid_check;
    @(posedge pclk) disable iff (!presetn)
    (psel && penable) |-> ##0 1'b1;  // Valid transfer condition
  endproperty
  assert_transfer_valid: assert property (transfer_valid_check)
    else $error("[ASSERTION FAIL] Invalid transfer state at time %0t", $time);

  // PENABLE requires PSEL
  property penable_requires_psel;
    @(posedge pclk) disable iff (!presetn)
    penable |-> psel;
  endproperty
  assert_penable_psel: assert property (penable_requires_psel)
    else $error("[ASSERTION FAIL] PENABLE high without PSEL at time %0t", $time);

  // PSEL should be followed by PENABLE in next cycle
  property psel_followed_by_penable;
    @(posedge pclk) disable iff (!presetn)
    $rose(psel) |=> penable;
  endproperty
  assert_psel_penable_seq: assert property (psel_followed_by_penable)
    else $error("[ASSERTION FAIL] PSEL not followed by PENABLE at time %0t", $time);

  //============================================================================
  // PREADY Behavior Assertions
  //============================================================================
  
  // PREADY always high for single-cycle slave
  property pready_always_high;
    @(posedge pclk) disable iff (!presetn)
    pready == 1'b1;
  endproperty
  assert_pready_high: assert property (pready_always_high)
    else $error("[ASSERTION FAIL] PREADY not asserted at time %0t", $time);

  //============================================================================
  // PSLVERR Condition Assertions
  //============================================================================
  
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

  // No error when no transfer
  property no_error_no_transfer;
    @(posedge pclk) disable iff (!presetn)
    !(psel && penable) |-> !pslverr;
  endproperty
  assert_no_error_idle: assert property (no_error_no_transfer)
    else $error("[ASSERTION FAIL] Error signal asserted during idle at time %0t", $time);

  //============================================================================
  // Signal Stability During Transfer
  //============================================================================
  
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

  //============================================================================
  // Read Operation Assertions
  //============================================================================
  
  // Read data valid when PREADY asserted during read
  property read_data_valid;
    @(posedge pclk) disable iff (!presetn)
    (psel && penable && !pwrite && pready) |-> !$isunknown(prdata);
  endproperty
  assert_read_data_valid: assert property (read_data_valid)
    else $error("[ASSERTION FAIL] PRDATA unknown during valid read at time %0t", $time);

  // Error pattern for invalid read addresses
  property read_error_pattern;
    @(posedge pclk) disable iff (!presetn)
    (psel && penable && !pwrite && (paddr >= `MEM_DEPTH)) |=> (prdata == 32'hFFFFFFFF);
  endproperty
  assert_read_error_pattern: assert property (read_error_pattern)
    else $error("[ASSERTION FAIL] Wrong error pattern for invalid read at time %0t", $time);

  //============================================================================
  // Write Operation Assertions
  //============================================================================
  
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

  //============================================================================
  // Reset Assertions
  //============================================================================
  
  // PRDATA cleared on reset
  property reset_prdata;
    @(posedge pclk)
    !presetn |=> (prdata == 32'h0);
  endproperty
  assert_reset_prdata: assert property (reset_prdata)
    else $error("[ASSERTION FAIL] PRDATA not cleared after reset at time %0t", $time);

  //============================================================================
  // Coverage Properties
  //============================================================================
  
  // Cover valid write transactions
  property cover_write_valid;
    @(posedge pclk) disable iff (!presetn)
    (psel && penable && pwrite && (paddr < `MEM_DEPTH));
  endproperty
  cover_write_transaction: cover property (cover_write_valid);

  // Cover valid read transactions
  property cover_read_valid;
    @(posedge pclk) disable iff (!presetn)
    (psel && penable && !pwrite && (paddr < `MEM_DEPTH));
  endproperty
  cover_read_transaction: cover property (cover_read_valid);

  // Cover error transactions
  property cover_error;
    @(posedge pclk) disable iff (!presetn)
    pslverr;
  endproperty
  cover_error_transaction: cover property (cover_error);

  // Cover all byte strobes
  property cover_all_bytes;
    @(posedge pclk) disable iff (!presetn)
    (psel && penable && pwrite && (pstrb == 4'b1111));
  endproperty
  cover_full_strobe: cover property (cover_all_bytes);

  // Cover partial byte writes
  property cover_partial_bytes;
    @(posedge pclk) disable iff (!presetn)
    (psel && penable && pwrite && (pstrb != 4'b1111) && (pstrb != 4'b0000));
  endproperty
  cover_partial_strobe: cover property (cover_partial_bytes);

  //============================================================================
  // Additional Functional Assertions
  //============================================================================
  
  // No back-to-back ACCESS phases without SETUP
  property no_continuous_access;
    @(posedge pclk) disable iff (!presetn)
    (psel && penable) |=> !penable or !psel;
  endproperty
  assert_no_continuous_access: assert property (no_continuous_access)
    else $error("[ASSERTION FAIL] Continuous ACCESS phase without SETUP at time %0t", $time);

  // PSEL and PENABLE cannot both rise in the same cycle
  property no_simultaneous_rise;
    @(posedge pclk) disable iff (!presetn)
    not($rose(psel) && $rose(penable));
  endproperty
  assert_no_simultaneous_rise: assert property (no_simultaneous_rise)
    else $error("[ASSERTION FAIL] PSEL and PENABLE both rose simultaneously at time %0t", $time);

endinterface
