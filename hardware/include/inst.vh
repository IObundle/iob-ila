//instantiate core in system

   //
   // ILA
   //

`include "signal_inst.vh"

`ifdef USE_ILA

iob_ila #(
   .DATA_W(32),
   .SIGNAL_W(`IOB_ILA_SIGNAL_W),
   .BUFFER_W(`IOB_ILA_BUFFER_W),
   .TRIGGER_W(`IOB_ILA_TRIGGER_W)
   )
  ila
  (
   //CPU interface
   .clk       (clk),
   .rst       (reset),
   .valid(slaves_req[`valid(`ILA)]),
   .address(slaves_req[`address(`ILA,`IOB_ILA_ADDR_W+2)-2]),
   .wdata(slaves_req[`wdata(`ILA)]),
   .wstrb(slaves_req[`wstrb(`ILA)]),
   .rdata(slaves_resp[`rdata(`ILA)]),
   .ready(slaves_resp[`ready(`ILA)]),

   .signal(ila_signal),
   .trigger(ila_trigger),
   .sampling_clk(clk)
   );
`else

assign slaves_resp[`ready(`ILA)] = 1'b1; // Always ready everything

`endif
