`timescale 1ns / 1ps

`include "iob_lib.vh"
`include "iob_ila_conf.vh"
`include "iob_ila_lib.vh"
`include "iob_pfsm_swreg_def.vh"

module ila_core #(
   parameter DATA_W    = 0,
   parameter SIGNAL_W  = 0,
   parameter BUFFER_W  = 0,
   parameter TRIGGER_W = 0,
   parameter CLK_COUNTER = 0, // Select if should contain an internal clock counter.
   parameter CLK_COUNTER_W = 0, // Size of clock counter
   parameter MONITOR = 0, // Select if should contain an internal monitor
   parameter MONITOR_STATE_W = 0 // Number of states for monitor PFSM
) (
   // Trigger and signals to sample
   input [ SIGNAL_W-1:0] signal,
   input [TRIGGER_W-1:0] trigger,
   input [        1-1:0] sampling_clk,

   // Trigger and signal configuration
   input [TRIGGER_W-1:0] trigger_type,
   input [TRIGGER_W-1:0] negate_trigger,
   input [TRIGGER_W-1:0] trigger_mask,

   // Miscellaneous items
   input [32-1:0] misc_enabled,

   // Software side access to values sampled
   input  [                                BUFFER_W-1:0] index,
   output [                                BUFFER_W-1:0] samples,
   output [                                  DATA_W-1:0] value,
   input  [`CALCULATE_SIGNAL_SEL_W(DATA_W,SIGNAL_W)-1:0] value_select,

   // Software side access to current values
   output [   DATA_W-1:0] current_value,
   output [TRIGGER_W-1:0] trigger_value,
   output [TRIGGER_W-1:0] active_triggers,

   // Enabled reset and system clk
   input clk_i,
   input cke_i,
   input arst_i,

   // Monitor IOb-Native interface
   input [1-1:0]                      monitor_avalid_i,
   input [`IOB_PFSM_SWREG_ADDR_W-1:0] monitor_addr_i,
   input [DATA_W-1:0]                 monitor_wdata_i,
   input [(DATA_W/8)-1:0]             monitor_wstrb_i,
   output [1-1:0]                     monitor_rvalid_o,
   output [DATA_W-1:0]                monitor_rdata_o,
   output [1-1:0]                     monitor_ready_o
);

   // Internal trigger only has 1 bit if the Monitor is used
   localparam I_TRIGGER_W = MONITOR>0 ? 1 : TRIGGER_W;
   wire [I_TRIGGER_W-1:0] i_trigger;


   // Internal signal width may include width of clock counter if it is used
   localparam I_SIGNAL_W = CLK_COUNTER>0 ? SIGNAL_W+CLK_COUNTER_W : SIGNAL_W;
   wire [I_SIGNAL_W-1:0] i_signal;

   //COMBINED SOFT/HARD RESET
   wire rst_int = arst_i | rst_soft;

   generate
      if (MONITOR>0) begin
         // Create Monitor
         iob_pfsm #(
            .DATA_W(DATA_W),
            .INPUT_W(TRIGGER_W),
            .OUTPUT_W(1),
            .STATE_W(MONITOR_STATE_W)
         ) monitor (
            .clk_i(sampling_clk),
            .arst_i(arst_i),
            .cke_i(cke_i),
            .iob_avalid_i(monitor_avalid_i),
            .iob_addr_i(monitor_addr_i),
            .iob_wdata_i(monitor_wdata_i),
            .iob_wstrb_i(monitor_wstrb_i),
            .iob_rvalid_o(monitor_rvalid_o),
            .iob_rdata_o(monitor_rdata_o),
            .iob_ready_o(monitor_ready_o),
            .input_ports(trigger), // Trigger input ports connect to monitor
            .output_ports(i_trigger) // Monitor output is the internal trigger
         );
      end else
         assign i_trigger = trigger;
   endgenerate

   generate
      if (CLK_COUNTER>0) begin
         // Create clock counter
         wire [CLK_COUNTER_W-1:0] clk_counter;
         iob_reg_r #(
            .DATA_W (CLK_COUNTER_W),
            .RST_VAL(1'b0)
         ) clk_counter_reg (
            .clk_i(sampling_clk),
            .arst_i(arst_i),
            .rst_i(rst_int),
            .cke_i(cke_i),
            .data_i(clk_counter+1'b1),
            .data_o(clk_counter)
         );
         // Connect channel 0 to the output of clk_counter
         assign i_signal = {signal,clk_counter};
      end else
         assign i_signal = signal;
   endgenerate

   reg [I_SIGNAL_W-1:0] registed_signal_1;

   reg [I_TRIGGER_W-1:0] registed_trigger_1;

   always @(posedge clk_i, posedge arst_i) begin
      if (arst_i) begin
         registed_signal_1  <= 0;
         registed_trigger_1 <= 0;
      end else begin
         registed_signal_1  <= i_signal;
         registed_trigger_1 <= i_trigger;
      end
   end

   wire rst_soft = misc_enabled[0]; // Software reset
   wire diff_signal = misc_enabled[1]; // Only enable trigger on signal change
   wire circular_buffer = misc_enabled[2]; // Enable circular (continuous) buffer
   wire delay_trigger = misc_enabled[3]; // Delay trigger by one clock
   wire delay_signal = misc_enabled[4]; // Delay sample signal by one clock
   wire reduce_type = misc_enabled[5]; // Select reduction type, either 'OR' or 'AND'.

   // TRIGGER LOGIC

   // Applies trigger logic to every trigger
   wire                                    [I_TRIGGER_W-1:0] trigger_out_1;
   generate
      genvar i;

      for (i = 0; i < I_TRIGGER_W; i = i + 1) begin: gen_trigger_logic
         ila_trigger_logic trigger_logic (
            .trigger_in  (registed_trigger_1[i]),
            .mask        (trigger_mask[i]),
            .negate      (negate_trigger[i]),
            .trigger_type(trigger_type[i]),
            .reduce_type (reduce_type),

            .trigger_out(trigger_out_1[i]),

            .clk(sampling_clk),
            .rst(rst_int)
         );
      end
   endgenerate

   // Computes the final trigger value
   wire trigger_reduce_or = |trigger_out_1;
   wire trigger_reduce_and = &trigger_out_1;

   wire trigger_reduce_out_1 = (reduce_type == `IOB_ILA_REDUCE_OR ? trigger_reduce_or : trigger_reduce_and);

   // Selects between current trigger or delayed trigger
   wire previous_trigger, trigger_enable_wr_2;
   iob_reg_r #(
      .DATA_W (1),
      .RST_VAL(0)
   ) previous_trigger_reg (
      .clk_i (sampling_clk),
      .arst_i(arst_i),
      .rst_i(rst_int),
      .cke_i(cke_i),
      .data_i(trigger_reduce_out_1),
      .data_o(previous_trigger)
   );

   wire final_trigger_1 = (delay_trigger ? previous_trigger : trigger_reduce_out_1);
   // Add a "pipeline" register to the trigger
   iob_reg_r #(
      .DATA_W (1),
      .RST_VAL(0)
   ) trigger_enable_wr_2_reg (
      .clk_i (sampling_clk),
      .arst_i(arst_i),
      .rst_i(rst_int),
      .cke_i(cke_i),
      .data_i(final_trigger_1),
      .data_o(trigger_enable_wr_2)
   );

   // SIGNAL LOGIC
   wire [I_SIGNAL_W-1:0] previous_signal, signal_data_2;
   iob_reg_r #(
      .DATA_W (I_SIGNAL_W),
      .RST_VAL(0)
   ) previous_signal_reg (
      .clk_i (sampling_clk),
      .arst_i(arst_i),
      .rst_i(rst_int),
      .cke_i(cke_i),
      .data_i(registed_signal_1),
      .data_o(previous_signal)
   );

   wire [I_SIGNAL_W-1:0] final_signal_1 = (delay_signal ? previous_signal : registed_signal_1);
   // Add a "pipeline" register to the signal
   iob_reg_r #(
      .DATA_W (I_SIGNAL_W),
      .RST_VAL(0)
   ) signal_data_2_reg (
      .clk_i (sampling_clk),
      .arst_i(arst_i),
      .rst_i(rst_int),
      .cke_i(cke_i),
      .data_i(final_signal_1),
      .data_o(signal_data_2)
   );

   // Both the trigger and signal have a "pipeline" register that serves to improve time constraints

   // INDEX LOGIC
   wire [BUFFER_W-1:0] n_samples;

   // Memory write index logic
   wire                                                                  different_signal_enable_wr;

   wire write_en_2 = (trigger_enable_wr_2 & different_signal_enable_wr);

   wire full = ((&n_samples) == 1'b1);

   // Write while not full or write always if circular buffer is used
   wire write_en_3 = write_en_2 && (!full || circular_buffer);

   iob_reg_re #(
      .DATA_W (BUFFER_W),
      .RST_VAL(1'b0)
   ) n_samples_reg (
      .clk_i(sampling_clk),
      .arst_i(arst_i),
      .rst_i(rst_int),
      .cke_i(cke_i),
      .en_i(write_en_3),
      .data_i(n_samples+1'b1),
      .data_o(n_samples)
   );

   // Memory instance
   wire [`CEIL_DIV(I_SIGNAL_W,DATA_W)*DATA_W-1:0] data_out; //Create a wire that is multiple of DATA_W
   // Connect extra bits to ground
   generate if (DATA_W%I_SIGNAL_W != 0)
      assign data_out [`CEIL_DIV(I_SIGNAL_W,DATA_W)*DATA_W-1:I_SIGNAL_W] = 'b0;
   endgenerate

   iob_ram_t2p #(
      .DATA_W(I_SIGNAL_W),
      .ADDR_W(BUFFER_W)
   ) buffer (
      .w_clk_i (sampling_clk),
      .w_en_i  (write_en_3),
      .w_data_i(signal_data_2),
      .w_addr_i(n_samples),
      .r_clk_i (clk_i),
      .r_addr_i(index),
      .r_en_i  (1'b1),
      .r_data_o(data_out[I_SIGNAL_W-1:0])
   );

   // Pass n_samples from sampling_clk domain to sys domain
   reg [BUFFER_W-1:0] sys_samples;

   reg [BUFFER_W-1:0] n_samples_sync_0, n_samples_sync_1;
   always @(posedge clk_i, posedge arst_i)
      if (arst_i) begin
         n_samples_sync_0 <= 0;
         n_samples_sync_1 <= 0;
      end else begin
         n_samples_sync_0 <= n_samples;
         n_samples_sync_1 <= n_samples_sync_0;
      end
   always @* sys_samples = n_samples_sync_1;

   assign samples = sys_samples;

   // Special trigger - Different signal logic
   reg [I_SIGNAL_W-1:0] last_written_signal;

   assign different_signal_enable_wr = ((last_written_signal != signal_data_2) | !diff_signal);

   always @(posedge clk_i, posedge rst_int) begin
      if (rst_int) begin
         last_written_signal <= 0;
      end else if (write_en_3) begin
         last_written_signal <= signal_data_2;
      end
   end

   // Partition signal into multiple parts to fit DATA_W
   reg [DATA_W-1:0] value_out;

   integer ii;
   always @(posedge clk_i, posedge arst_i) begin
      if (arst_i) begin
         value_out <= 0;
      end else begin
         if (DATA_W >= I_SIGNAL_W) value_out <= data_out;
         else begin
            for (
                ii = 0;
                ii <
                `CEIL_DIV(I_SIGNAL_W, DATA_W);
                ii = ii + 1
            ) begin
               if (value_select == ii) begin
                  value_out <= data_out[DATA_W*ii+:DATA_W];
               end
            end
         end
      end
   end

   assign value = value_out;

   // CURRENT VALUE LOGIC
   wire [I_TRIGGER_W-1:0] trigger_value_reg;
   iob_reg_r #(
      .DATA_W (I_TRIGGER_W),
      .RST_VAL(0)
   ) trigger_value_reg_reg (
      .clk_i (sampling_clk),
      .arst_i(arst_i),
      .rst_i(rst_int),
      .cke_i(cke_i),
      .data_i(registed_trigger_1),
      .data_o(trigger_value_reg)
   );

   ila_sig_clk #(
      I_TRIGGER_W
   ) trigger_sig_clk (
      .clk_i (sampling_clk),
      .arst_i(arst_i),
      .data_i(trigger_value_reg),
      .data_o(trigger_value)
   );

   wire [I_TRIGGER_W-1:0] active_trigger_reg;
   iob_reg_r #(
      .DATA_W (I_TRIGGER_W),
      .RST_VAL(0)
   ) active_trigger_reg_reg (
      .clk_i (sampling_clk),
      .arst_i(arst_i),
      .rst_i(rst_int),
      .cke_i(cke_i),
      .data_i(trigger_out_1),
      .data_o(active_trigger_reg)
   );

   ila_sig_clk #(
      I_TRIGGER_W
   ) active_trigger_sig_clk (
      .clk_i (sampling_clk),
      .arst_i(arst_i),
      .data_i(active_trigger_reg),
      .data_o(active_triggers)
   );

    //Create a wire that is multiple of DATA_W
   wire [`CEIL_DIV(I_SIGNAL_W,DATA_W)*DATA_W-1:0] registed_signal_aligned = registed_signal_1;
   // Connect extra bits to ground
   generate if (DATA_W%I_SIGNAL_W != 0)
      assign registed_signal_aligned [`CEIL_DIV(I_SIGNAL_W,DATA_W)*DATA_W-1:I_SIGNAL_W] = 'b0;
   endgenerate

   // Partition current signal into various pieces
   integer              iii;
   reg     [DATA_W-1:0] current_signal;
   always @* begin
      current_signal = 32'h0;
      if (DATA_W >= I_SIGNAL_W) current_signal = registed_signal_1;
      else begin
         for (
             iii = 0;
             iii <
             `CEIL_DIV(I_SIGNAL_W, DATA_W);
             iii = iii + 1
         ) begin
            if (value_select == iii) begin
               current_signal = registed_signal_aligned[DATA_W*iii+:DATA_W];
            end
         end
      end
   end

   wire [DATA_W-1:0] signal_value_reg;
   iob_reg_r #(
      .DATA_W (DATA_W),
      .RST_VAL(0)
   ) signal_value_reg_reg (
      .clk_i (sampling_clk),
      .arst_i(arst_i),
      .rst_i(rst_int),
      .cke_i(cke_i),
      .data_i(current_signal),
      .data_o(signal_value_reg)
   );

   ila_sig_clk #(
      DATA_W
   ) value_sig_clk (
      .clk_i (sampling_clk),
      .arst_i(arst_i),
      .data_i(signal_value_reg),
      .data_o(current_value)
   );

endmodule
