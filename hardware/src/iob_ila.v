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

   wire [         1-1:0] iob_avalid = iob_avalid_i;  //Request valid.
   wire [    ADDR_W-1:0] iob_addr = iob_addr_i;  //Address.
   wire [    DATA_W-1:0] iob_wdata = iob_wdata_i;  //Write data.
   wire [(DATA_W/8)-1:0] iob_wstrb = iob_wstrb_i;  //Write strobe.
   wire [         1-1:0]                                              iob_rvalid;
   assign iob_rvalid_o = iob_rvalid;  //Read data valid.
   wire [DATA_W-1:0] iob_rdata;
   assign iob_rdata_o = iob_rdata;  //Read data.
   wire [1-1:0] iob_ready;
   assign iob_ready_o = iob_ready;  //Interface ready.

   //BLOCK Register File & Configuration control and status register file.
   `include "iob_ila_swreg_inst.vs"

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
      .trigger_type  (TRIGGER_TYPE),
      .negate_trigger(TRIGGER_NEGATE),
      .trigger_mask  (TRIGGER_MASK),

      // Mask for special triggers
      .misc_enabled(MISCELLANEOUS),

      // Software side access to values sampled
      .index       (INDEX),
      .samples     (N_SAMPLES),
      .value       (SAMPLE_DATA),
      .value_select(SIGNAL_SELECT),

      .current_value  (CURRENT_DATA),
      .trigger_value  (CURRENT_TRIGGERS),
      .active_triggers(CURRENT_ACTIVE_TRIGGERS),

      // Enabled reset and system clk
      .clk_i(clk_i),
      .cke_i(cke_i),
      .arst_i(arst_i)
   );

endmodule


