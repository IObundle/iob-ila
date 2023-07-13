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

   //Dummy iob_ready_nxt_o and iob_rvalid_nxt_o to be used in swreg (unused ports)
   wire iob_ready_nxt_o;
   wire iob_rvalid_nxt_o;

   //BLOCK Register File & Configuration control and status register file.
   `include "iob_ila_swreg_inst.vs"

   ila_core #(
      .DATA_W       (DATA_W),
      .SIGNAL_W     (SIGNAL_W),
      .BUFFER_W     (BUFFER_W),
      .TRIGGER_W    (TRIGGER_W),
      .CLK_COUNTER  (CLK_COUNTER),
      .CLK_COUNTER_W(CLK_COUNTER_W)
   ) ila_core0 (
      // Trigger and signals to sample
      .signal      (signal),
      .trigger     (trigger),
      .sampling_clk(sampling_clk),

      // Trigger and signal configuration
      .trigger_type  (TRIGGER_TYPE[0+:TRIGGER_W]),
      .negate_trigger(TRIGGER_NEGATE[0+:TRIGGER_W]),
      .trigger_mask  (TRIGGER_MASK[0+:TRIGGER_W]),

      // Mask for special triggers
      .misc_enabled(MISCELLANEOUS),

      // Software side access to values sampled
      .index       (INDEX[0+:BUFFER_W]),
      .samples     (N_SAMPLES[0+:BUFFER_W]),
      .value       (SAMPLE_DATA),
      .value_select(SIGNAL_SELECT[0+:`CALCULATE_SIGNAL_SEL_W(DATA_W,SIGNAL_W)]),

      .current_value  (CURRENT_DATA),
      .trigger_value  (CURRENT_TRIGGERS[0+:TRIGGER_W]),
      .active_triggers(CURRENT_ACTIVE_TRIGGERS[0+:TRIGGER_W]),

      // Enabled reset and system clk
      .clk_i(clk_i),
      .cke_i(cke_i),
      .arst_i(arst_i)
   );

endmodule


