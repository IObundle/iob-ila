//instantiate core in system

   //
   // ILA
   //

   iob_ila ila
     (
      //CPU interface
      .clk       (clk),
      .rst       (reset),
      .valid(slaves_req[`valid(`ILA)]),
      .address(slaves_req[`address(`ILA,`ILA_ADDR_W+2)-2]),
      .wdata(slaves_req[`wdata(`ILA)-(`DATA_W-`ILA_WDATA_W)]),
      .wstrb(slaves_req[`wstrb(`ILA)]),
      .rdata(slaves_resp[`rdata(`ILA)]),
      .ready(slaves_resp[`ready(`ILA)])
      );
