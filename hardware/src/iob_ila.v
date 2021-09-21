`timescale 1ns/1ps

`include "iob_lib.vh"
`include "iob_ila.vh"
`include "ILAsw_reg.vh"

module iob_ila 
  # (
     parameter ADDR_W = `ILA_ADDR_W, //NODOC Address width
     parameter DATA_W = `ILA_RDATA_W, //NODOC CPU data width
     parameter WDATA_W = `ILA_WDATA_W, //NODOC CPU data width
     parameter SIGNAL_W = `ILA_SIGNAL_W,
     parameter BUFFER_W = `ILA_MAX_SAMPLES_W,
     parameter TRIGGER_W = `ILA_MAX_TRIGGERS
     )
  (
  `INPUT(signal,SIGNAL_W),
  `INPUT(trigger,TRIGGER_W),
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
      .SIGNAL_W(SIGNAL_W),
      .BUFFER_W(BUFFER_W),
      .TRIGGER_W(TRIGGER_W)
    )
   ila_core0 
     (
      // Trigger and signals to sample
      .signal(signal),
      .trigger(trigger),
      .sampling_clk(sampling_clk),

      // Trigger and signal configuration
      .trigger_type(ILA_TRIGGER_TYPE),
      .negate_trigger(ILA_TRIGGER_NEGATE),
      .trigger_mask(ILA_TRIGGER_MASK),

      // Mask for special triggers
      .misc_enabled(ILA_MISCELLANEOUS),

      // Software side access to values sampled
      .index(ILA_INDEX),
      .samples(ILA_SAMPLES),
      .value(ILA_DATA),
      .value_select(ILA_SIGNAL_SELECT),

      .current_value(ILA_CURRENT_DATA),
      .trigger_value(ILA_CURRENT_TRIGGERS),
      .active_triggers(ILA_CURRENT_ACTIVE_TRIGGERS),

      // Enabled reset and system clk
      .clk(clk),
      .rst(rst)
     );

endmodule


