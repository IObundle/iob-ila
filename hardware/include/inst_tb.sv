//add core test module in testbench

   iob_ila ila_tb
     (
      .clk       (clk),
      .rst       (reset),
      
      .valid     (ila_valid),
      .address   (ila_addr),
      .wdata     (ila_wdata[`ILA_WDATA_W-1:0]),
      .wstrb     (ila_wstrb),
      .rdata     (ila_rdata),
      .ready     (ila_ready),

      .signal(ila_signal),
      .trigger(ila_trigger),
      .sampling_clk(ila_sampling_clk)
      );

