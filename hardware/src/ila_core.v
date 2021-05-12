`timescale 1ns/1ps
`include "iob_lib.vh"
`include "iob_ila.vh"

module ila_core 
  #(
    parameter DATA_W = `ILA_RDATA_W,
    parameter BUFFER_W = `ILA_MAX_SAMPLES_W
  )
  (
    `INPUT(signal,DATA_W),
    `INPUT(trigger,1),
    `INPUT(sampling_clk,1),

    `INPUT(index,BUFFER_W),
    `OUTPUT(samples,BUFFER_W),
    `OUTPUT(value, DATA_W),
    `INPUT(enabled, 1),

    `INPUT(rst_soft,1),
   `include "gen_if.v"
   );
   
   //COMBINED SOFT/HARD RESET
   wire     rst_int = rst | rst_soft;

   `SIGNAL(n_samples,BUFFER_W)
   `SIGNAL2OUT(samples,n_samples)

   wire     full = (&n_samples == 1'b1);

   `ACC_ARE(sampling_clk,rst_int,0,trigger && enabled && !full,n_samples,1)

   iob_2p_async_mem #(
        .DATA_W(DATA_W),
        .ADDR_W(BUFFER_W))
    buffer (
        .wclk(sampling_clk),
        .w_en(1'b1),
        .data_in(signal),
        .w_addr(n_samples),
        .rclk(clk),
        .r_addr(index),
        .r_en(1'b1),
        .data_out(value)
    );

endmodule
