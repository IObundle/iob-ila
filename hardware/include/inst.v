//instantiate core in system

   //
   // ILA
   //

`include "signal_inst.vh"

iob_ila #(
   .SIGNAL_W(`ILA_SIGNAL_W),
   .BUFFER_W(`ILA_BUFFER_W),
   .TRIGGER_W(`ILA_TRIGGER_W)
   )
  ila
  (
   //CPU interface
   .clk       (clk),
   .rst       (reset),
   .valid(slaves_req[`valid(`ILA)]),
   .address(slaves_req[`address(`ILA,`ILA_ADDR_W+2)-2]),
   .wdata(slaves_req[`wdata(`ILA)]),
   .wstrb(slaves_req[`wstrb(`ILA)]),
   .rdata(slaves_resp[`rdata(`ILA)]),
   .ready(slaves_resp[`ready(`ILA)]),

   .signal(ila_signal),
   .trigger(ila_trigger),
   .sampling_clk(clk)
   );


