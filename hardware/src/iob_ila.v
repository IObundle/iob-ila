`timescale 1ns/1ps

`include "iob_lib.vh"
`include "iob_ila.vh"
`include "iob_ila_lib.vh"
`include "iob_ila_swreg_def.vh"

module iob_ila 
  # (
     parameter ADDR_W = `ILA_ADDR_W, //NODOC Address width
     parameter DATA_W = `ILA_RDATA_W, //NODOC CPU data width
     parameter WDATA_W = `ILA_WDATA_W, //NODOC CPU data width
     parameter SIGNAL_W = 0,
     parameter BUFFER_W = 0,
     parameter TRIGGER_W = 0
     )
  (
  `IOB_INPUT(signal,SIGNAL_W),
  `IOB_INPUT(trigger,TRIGGER_W),
  `IOB_INPUT(sampling_clk,1),

   //CPU interface
`include "iob_s_if.vh"

   //additional inputs and outputs
   input clk,
   input rst
   );

//BLOCK Register File & Holds the current configuration of the ILA as well as internal parameters. Data to be sent or that has been received is stored here temporarily.
`include "iob_ila_swreg_gen.vh"

    `IOB_WIRE(ILA_MISCELLANEOUS, 32)
    iob_reg #(.DATA_W(32),.RST_VAL(0))
    ila_misc (
        .clk        (clk),
        .arst       (rst),
        .rst        (rst),
        .en         (ILA_MISCELLANEOUS_en),
        .data_in    (ILA_MISCELLANEOUS_wdata),
        .data_out   (ILA_MISCELLANEOUS)
    );

    `IOB_WIRE(ILA_TRIGGER_TYPE, TRIGGER_W)
    iob_reg #(.DATA_W(TRIGGER_W),.RST_VAL(0))
    ila_trigger_type (
        .clk        (clk),
        .arst       (rst),
        .rst        (rst),
        .en         (ILA_TRIGGER_TYPE_en),
        .data_in    (ILA_TRIGGER_TYPE_wdata),
        .data_out   (ILA_TRIGGER_TYPE)
    );

    `IOB_WIRE(ILA_TRIGGER_NEGATE, TRIGGER_W)
    iob_reg #(.DATA_W(TRIGGER_W),.RST_VAL(0))
    ila_trigger_negate (
        .clk        (clk),
        .arst       (rst),
        .rst        (rst),
        .en         (ILA_TRIGGER_NEGATE_en),
        .data_in    (ILA_TRIGGER_NEGATE_wdata),
        .data_out   (ILA_TRIGGER_NEGATE)
    );

    `IOB_WIRE(ILA_TRIGGER_MASK, TRIGGER_W)
    iob_reg #(.DATA_W(TRIGGER_W),.RST_VAL(0))
    ila_trigger_mask (
        .clk        (clk),
        .arst       (rst),
        .rst        (rst),
        .en         (ILA_TRIGGER_MASK_en),
        .data_in    (ILA_TRIGGER_MASK_wdata),
        .data_out   (ILA_TRIGGER_MASK)
    );

    `IOB_WIRE(ILA_INDEX, BUFFER_W)
    iob_reg #(.DATA_W(BUFFER_W),.RST_VAL(0))
    ila_index (
        .clk        (clk),
        .arst       (rst),
        .rst        (rst),
        .en         (ILA_INDEX_en),
        .data_in    (ILA_INDEX_wdata),
        .data_out   (ILA_INDEX)
    );

    `IOB_WIRE(ILA_SIGNAL_SELECT, `CALCULATE_SIGNAL_SEL_W(DATA_W,SIGNAL_W))
    iob_reg #(.DATA_W(`CALCULATE_SIGNAL_SEL_W(DATA_W,SIGNAL_W)),.RST_VAL(0))
    ila_signal_select (
        .clk        (clk),
        .arst       (rst),
        .rst        (rst),
        .en         (ILA_SIGNAL_SELECT_en),
        .data_in    (ILA_SIGNAL_SELECT_wdata),
        .data_out   (ILA_SIGNAL_SELECT)
    );

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
      .samples(ILA_SAMPLES_rdata),
      .value(ILA_DATA_rdata),
      .value_select(ILA_SIGNAL_SELECT),

      .current_value(ILA_CURRENT_DATA_rdata),
      .trigger_value(ILA_CURRENT_TRIGGERS_rdata),
      .active_triggers(ILA_CURRENT_ACTIVE_TRIGGERS_rdata),

      // Enabled reset and system clk
      .clk(clk),
      .rst(rst)
     );

endmodule


