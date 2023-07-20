`timescale 1ns / 1ps
`include "iob_utils.vh"
`include "iob_ila_conf.vh"
`include "iob_ila_lib.vh"
`include "iob_ila_swreg_def.vh"
`include "iob_pfsm_swreg_def.vh"

module iob_ila #(
   `include "iob_ila_params.vs"
) (
   `include "iob_ila_io.vs"
);

   //Dummy iob_ready_nxt_o and iob_rvalid_nxt_o to be used in swreg (unused ports)
   wire iob_ready_nxt_o;
   wire iob_rvalid_nxt_o;

   //
   // SPLIT ILA REGS AND MONITOR REGS
   //

   //master bus (includes internal memory + periphrals)
   wire [`REQ_W-1:0] m_req;
   wire [`RESP_W-1:0] m_resp;

   assign m_req[`AVALID(0)] = iob_avalid_i;
   assign m_req[`ADDRESS(0,`IOB_ILA_SWREG_ADDR_W)] = iob_addr_i;
   assign m_req[`WDATA(0)] = iob_wdata_i;
   assign m_req[`WSTRB(0)] = iob_wstrb_i;
   assign iob_rvalid_o = m_resp[`RVALID(0)];
   assign iob_rdata_o = m_resp[`RDATA(0)];
   assign iob_ready_o = m_resp[`READY(0)];

   //slaves bus (includes ila swreg + monitor swreg)
   wire [2*`REQ_W-1:0] slaves_req;
   wire [2*`RESP_W-1:0] slaves_resp;

   iob_split #(
      .ADDR_W  (ADDR_W),
      .DATA_W  (DATA_W),
      .N_SLAVES(2),
      .P_SLAVES(`REQ_W-1)
   ) swreg_split (
      .clk_i   (clk_i),
      .arst_i  (cpu_reset),
      // master interface
      .m_req_i (m_req),
      .m_resp_o(m_resp),
      // slaves interface
      .s_req_o (slaves_req),
      .s_resp_i(slaves_resp)
   );

   //BLOCK Register File & Configuration control and status register file.
   // Did not use `iob_ila_swreg_inst.vs` because of the IOb-Native interface mapping
  wire [32-1:0] MISCELLANEOUS;
  wire [32-1:0] TRIGGER_TYPE;
  wire [32-1:0] TRIGGER_NEGATE;
  wire [32-1:0] TRIGGER_MASK;
  wire [16-1:0] INDEX;
  wire [8-1:0] SIGNAL_SELECT;
  wire [32-1:0] SAMPLE_DATA;
  wire [16-1:0] N_SAMPLES;
  wire [32-1:0] CURRENT_DATA;
  wire [32-1:0] CURRENT_TRIGGERS;
  wire [32-1:0] CURRENT_ACTIVE_TRIGGERS;
  wire DUMMY_MONITOR_REG_RANGE_wen;
  wire DUMMY_MONITOR_REG_RANGE_ready = 1'b1;
  wire [16-1:0] VERSION;
  wire iob_ready_nxt;
  wire iob_rvalid_nxt;

  iob_ila_swreg_gen #(

    .ADDR_W(ADDR_W),
    .DATA_W(DATA_W),
    .SIGNAL_W(SIGNAL_W),
    .BUFFER_W(BUFFER_W),
    .TRIGGER_W(TRIGGER_W),
    .CLK_COUNTER(CLK_COUNTER),
    .CLK_COUNTER_W(CLK_COUNTER_W),
    .MONITOR(MONITOR),
    .MONITOR_STATE_W(MONITOR_STATE_W)

  ) swreg_0 (
    .MISCELLANEOUS_o(MISCELLANEOUS),
    .TRIGGER_TYPE_o(TRIGGER_TYPE),
    .TRIGGER_NEGATE_o(TRIGGER_NEGATE),
    .TRIGGER_MASK_o(TRIGGER_MASK),
    .INDEX_o(INDEX),
    .SIGNAL_SELECT_o(SIGNAL_SELECT),
    .SAMPLE_DATA_i(SAMPLE_DATA),
    .N_SAMPLES_i(N_SAMPLES),
    .CURRENT_DATA_i(CURRENT_DATA),
    .CURRENT_TRIGGERS_i(CURRENT_TRIGGERS),
    .CURRENT_ACTIVE_TRIGGERS_i(CURRENT_ACTIVE_TRIGGERS),
    .DUMMY_MONITOR_REG_RANGE_wen_o(DUMMY_MONITOR_REG_RANGE_wen),
    .DUMMY_MONITOR_REG_RANGE_ready_i(DUMMY_MONITOR_REG_RANGE_ready),
    .VERSION_i(VERSION),
    .iob_ready_nxt_o(iob_ready_nxt_o),
    .iob_rvalid_nxt_o(iob_rvalid_nxt_o),
     .iob_avalid_i(slaves_req[`AVALID(0)]),
     .iob_addr_i(slaves_req[`ADDRESS(0,`IOB_ILA_SWREG_ADDR_W)]),
     .iob_wdata_i(slaves_req[`WDATA(0)]),
     .iob_wstrb_i(slaves_req[`WSTRB(0)]),
     .iob_rvalid_o(slaves_resp[`RVALID(0)]),
     .iob_rdata_o(slaves_resp[`RDATA(0)]),
     .iob_ready_o(slaves_resp[`READY(0)]),
     .clk_i(clk_i),
     .cke_i(cke_i),
     .arst_i(arst_i)

   );

   ila_core #(
      .DATA_W       (DATA_W),
      .SIGNAL_W     (SIGNAL_W),
      .BUFFER_W     (BUFFER_W),
      .TRIGGER_W    (TRIGGER_W),
      .CLK_COUNTER  (CLK_COUNTER),
      .CLK_COUNTER_W(CLK_COUNTER_W),
      .MONITOR      (MONITOR),
      .MONITOR_STATE_W(MONITOR_STATE_W)
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
      .arst_i(arst_i),

      // Monitor IOb-Native interface
      .monitor_avalid_i(slaves_req[`AVALID(1)]),
      .monitor_addr_i(slaves_req[`ADDRESS(1,`IOB_PFSM_SWREG_ADDR_W)]),
      .monitor_wdata_i(slaves_req[`WDATA(1)]),
      .monitor_wstrb_i(slaves_req[`WSTRB(1)]),
      .monitor_rvalid_o(slaves_resp[`RVALID(1)]),
      .monitor_rdata_o(slaves_resp[`RDATA(1)]),
      .monitor_ready_o(slaves_resp[`READY(1)])
   );

endmodule


