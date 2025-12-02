//==============================================================================
// Bind APB Assertions to Interface
//==============================================================================

bind apb_if apb_assertions apb_if_assert_inst (
  .pclk    (pclk),
  .presetn (presetn),
  .paddr   (paddr),
  .psel    (psel),
  .penable (penable),
  .pwrite  (pwrite),
  .pwdata  (pwdata),
  .pstrb   (pstrb),
  .prdata  (prdata),
  .pready  (pready),
  .pslverr (pslverr)
);
