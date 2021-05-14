`timescale 1ns/1ps
`include "iob_lib.vh"
`include "iob_ila.vh"
`include "ILAsw_reg.vh"

module iob_ila 
  # (
     parameter ADDR_W = `ILA_ADDR_W, //NODOC Address width
     parameter DATA_W = `ILA_RDATA_W, //NODOC CPU data width
     parameter WDATA_W = `ILA_WDATA_W, //NODOC CPU data width
     parameter BUFFER_W = `ILA_MAX_SAMPLES_W
     )
  (
  `INPUT(signal,DATA_W),
  `INPUT(trigger, 1),
  `INPUT(sampling_clk,1),

   //CPU interface
`ifndef USE_AXI4LITE
 `include "cpu_nat_s_if.v"
`else
 `include "cpu_axi4lite_s_if.v"
`endif
   //additional inputs and outputs
`include "gen_if.v"
   );

//BLOCK Register File & Holds the current configuration of the ILA as well as internal parameters. Data to be sent or that has been received is stored here temporarily.
`include "ILAsw_reg.v"
`include "ILAsw_reg_gen.v"

   ila_core #(
      .DATA_W(DATA_W),
      .BUFFER_W(BUFFER_W)
    )
   ila_core0 
     (
      .signal(signal),
      .trigger(trigger),
      .sampling_clk(sampling_clk),

      .index(ILA_INDEX),
      .samples(ILA_SAMPLES),
      .value(ILA_DATA),

      .enabled(ILA_ENABLED),
      .rst_soft(ILA_SOFTRESET),
      .clk(clk),
      .rst(rst)
     );

endmodule


