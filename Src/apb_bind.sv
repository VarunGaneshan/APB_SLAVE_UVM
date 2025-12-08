bind apb_slave apb_assertions apb_assert_inst (
  .pclk    (PCLK),
  .presetn (PRESETn),
  .paddr   (PADDR),
  .psel    (PSEL),
  .penable (PENABLE),
  .pwrite  (PWRITE),
  .pwdata  (PWDATA),
  .pstrb   (PSTRB),
  .prdata  (PRDATA),
  .pready  (PREADY),
  .pslverr (PSLVERR)
);
