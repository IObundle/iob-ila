`timescale 1ns / 1ps
`include "iob_lib.vh"
`include "iob_ila_conf.vh"
`include "iob_ila_lib.vh"
`include "iob_ila_swreg_def.vh"

module iob_ila #(
   `include "iob_ila_params.vs"
) (
   `include "iob_ila_io.vs"
);

   //BLOCK Register File & Configuration control and status register file.
   `include "iob_ila_swreg_inst.vs"

   wire [32-1:0] ILA_MISCELLANEOUS;
   iob_reg #(
      .DATA_W (32),
      .RST_VAL(0)
   ) ila_misc (
      .clk_i     (clk_i),
      .arst_i    (arst_i),
      .en_i      (ILA_MISCELLANEOUS_en),
      .data_i (ILA_MISCELLANEOUS_wdata),
      .data_o(ILA_MISCELLANEOUS)
   );

   wire [TRIGGER_W-1:0] ILA_TRIGGER_TYPE;
   iob_reg #(
      .DATA_W (TRIGGER_W),
      .RST_VAL(0)
   ) ila_trigger_type (
      .clk_i     (clk_i),
      .arst_i    (arst_i),
      .en_i      (ILA_TRIGGER_TYPE_en),
      .data_i (ILA_TRIGGER_TYPE_wdata),
      .data_o(ILA_TRIGGER_TYPE)
   );

   wire [TRIGGER_W-1:0] ILA_TRIGGER_NEGATE;
   iob_reg #(
      .DATA_W (TRIGGER_W),
      .RST_VAL(0)
   ) ila_trigger_negate (
      .clk_i     (clk_i),
      .arst_i    (arst_i),
      .en_i      (ILA_TRIGGER_NEGATE_en),
      .data_i (ILA_TRIGGER_NEGATE_wdata),
      .data_o(ILA_TRIGGER_NEGATE)
   );

   wire [TRIGGER_W-1:0] ILA_TRIGGER_MASK;
   iob_reg #(
      .DATA_W (TRIGGER_W),
      .RST_VAL(0)
   ) ila_trigger_mask (
      .clk_i     (clk_i),
      .arst_i    (arst_i),
      .en_i      (ILA_TRIGGER_MASK_en),
      .data_i (ILA_TRIGGER_MASK_wdata),
      .data_o(ILA_TRIGGER_MASK)
   );

   wire [BUFFER_W-1:0] ILA_INDEX;
   iob_reg #(
      .DATA_W (BUFFER_W),
      .RST_VAL(0)
   ) ila_index (
      .clk_i     (clk_i),
      .arst_i    (arst_i),
      .en_i      (ILA_INDEX_en),
      .data_i (ILA_INDEX_wdata),
      .data_o(ILA_INDEX)
   );

   wire [(DATA_W >= SIGNAL_W ? 1 : $clog2(`CEIL_DIV(SIGNAL_W,DATA_W)))-1:0] ILA_SIGNAL_SELECT;
   iob_reg #(
      .DATA_W ((DATA_W >= SIGNAL_W ? 1 : $clog2(`CEIL_DIV(SIGNAL_W,DATA_W)))),
      .RST_VAL(0)
   ) ila_signal_select (
      .clk_i     (clk_i),
      .arst_i    (arst_i),
      .en_i      (ILA_SIGNAL_SELECT_en),
      .data_i (ILA_SIGNAL_SELECT_wdata),
      .data_o(ILA_SIGNAL_SELECT)
   );

   ila_core #(
      .DATA_W   (DATA_W),
      .SIGNAL_W (SIGNAL_W),
      .BUFFER_W (BUFFER_W),
      .TRIGGER_W(TRIGGER_W)
   ) ila_core0 (
      // Trigger and signals to sample
      .signal      (signal),
      .trigger     (trigger),
      .sampling_clk(sampling_clk),

      // Trigger and signal configuration
      .trigger_type  (ILA_TRIGGER_TYPE),
      .negate_trigger(ILA_TRIGGER_NEGATE),
      .trigger_mask  (ILA_TRIGGER_MASK),

      // Mask for special triggers
      .misc_enabled(ILA_MISCELLANEOUS),

      // Software side access to values sampled
      .index       (ILA_INDEX),
      .samples     (ILA_SAMPLES_rdata),
      .value       (ILA_DATA_rdata),
      .value_select(ILA_SIGNAL_SELECT),

      .current_value  (ILA_CURRENT_DATA_rdata),
      .trigger_value  (ILA_CURRENT_TRIGGERS_rdata),
      .active_triggers(ILA_CURRENT_ACTIVE_TRIGGERS_rdata),

      // Enabled reset and system clk
      .clk_i(clk_i),
      .arst_i(arst_i)
   );

endmodule


