`timescale 1ns / 1ps

`include "iob_lib.vh"
`include "iob_ila_conf.vh"
`include "iob_ila_lib.vh"

module sig_clk #(
   parameter W = 0
) (
   input [W-1:0] clk_i,
   input [W-1:0] arst_i,
   input [W-1:0] data_i,
   output reg [W-1:0] data_o
);
   reg [W-1:0] data_sync_0, data_sync_1;
   always @(posedge clk_i, posedge arst_i)
     if(arst_i) begin
       data_sync_0 <= 0;
       data_sync_1 <= 0;
     end else begin
       data_sync_0 <= data_i;
       data_sync_1 <= data_sync_0;
     end
     always @* data_o = data_sync_1;
endmodule

module ila_core #(
   parameter DATA_W    = 0,
   parameter SIGNAL_W  = 0,
   parameter BUFFER_W  = 0,
   parameter TRIGGER_W = 0
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
   input  [(DATA_W >= SIGNAL_W ? 1 : $clog2(`CEIL_DIV(SIGNAL_W,DATA_W)))-1:0] value_select,

   // Software side access to current values
   output [   DATA_W-1:0] current_value,
   output [TRIGGER_W-1:0] trigger_value,
   output [TRIGGER_W-1:0] active_triggers,

   // Enabled reset and system clk
   input clk_i,
   input arst_i
);

   function static [31:0] fix_sim(input vector [31:0] in);
`ifdef SIM
      integer i;
      for (i = 0; i < 32; i = i + 1) fix_sim[i] = (in[i] === 1'bx ? 1'b0 : in[i]);
`else
      fix_sim = in;
`endif
   endfunction

   reg [2**$clog2(SIGNAL_W)-1:0] registed_signal_1;
   reg [          TRIGGER_W-1:0] registed_trigger_1;

   always @(posedge clk_i, posedge arst_i) begin
      if (arst_i) begin
         registed_signal_1  <= 0;
         registed_trigger_1 <= 0;
      end else begin
         registed_signal_1  <= signal;
         registed_trigger_1 <= trigger;
      end
   end

   wire rst_soft = misc_enabled[0];
   wire diff_signal = misc_enabled[1];
   wire circular_buffer = misc_enabled[2];
   wire delay_trigger = misc_enabled[3];
   wire delay_signal = misc_enabled[4];
   wire reduce_type = misc_enabled[5];

   //COMBINED SOFT/HARD RESET
   wire rst_int = arst_i | rst_soft;

   // TRIGGER LOGIC

   // Applies trigger logic to every trigger
   wire                                    [TRIGGER_W-1:0] trigger_out_1;
   generate
      genvar i;

      for (i = 0; i < TRIGGER_W; i = i + 1) begin: gen_trigger_logic
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
      .RST_VAL(0),
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
      .RST_VAL(0),
   ) trigger_enable_wr_2_reg (
      .clk_i (sampling_clk),
      .arst_i(arst_i),
      .rst_i(rst_int),
      .cke_i(cke_i),
      .data_i(final_trigger_1),
      .data_o(trigger_enable_wr_2)
   );

   // SIGNAL LOGIC
   wire [2**$clog2(SIGNAL_W)-1:0] previous_signal, signal_data_2;
   iob_reg_r #(
      .DATA_W (2**$clog2(SIGNAL_W)),
      .RST_VAL(0),
   ) previous_signal_reg (
      .clk_i (sampling_clk),
      .arst_i(arst_i),
      .rst_i(rst_int),
      .cke_i(cke_i),
      .data_i(registed_signal_1),
      .data_o(previous_signal)
   );

   wire [2**$clog2(
SIGNAL_W
)-1:0] final_signal_1 = (delay_signal ? previous_signal : registed_signal_1);
   // Add a "pipeline" register to the signal
   iob_reg_r #(
      .DATA_W (1),
      .RST_VAL( 0),
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
   iob_reg_re #(
      .RST_VAL(1'b0),
      .DATA_W (BUFFER_W)
   ) n_samples_reg (
      .clk_i(sampling_clk),
      .arst_i(arst_i),
      .rst_i(rst_int),
      .cke_i(cke_i),
      .en_i(write_en_2 && !full),
      .data_i(n_samples+1),
      .data_o(n_samples)
   );

   // Memory instance
   wire [2**$clog2(SIGNAL_W)-1:0] data_out;
   iob_ram_t2p #(
      .DATA_W(SIGNAL_W),
      .ADDR_W(BUFFER_W)
   ) buffer (
      .w_clk (sampling_clk),
      .w_en  (write_en_2),
      .w_data(signal_data_2[SIGNAL_W-1:0]),
      .w_addr(n_samples),
      .r_clk (clk_i),
      .r_addr(index),
      .r_en  (1'b1),
      .r_data(data_out[SIGNAL_W-1:0])
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
   reg [2**$clog2(SIGNAL_W)-1:0] last_written_signal;

   assign different_signal_enable_wr = ((last_written_signal != signal_data_2) | !diff_signal);

   always @(posedge clk_i, posedge rst_int) begin
      if (rst_int) begin
         last_written_signal <= 0;
      end else if (write_en_2) begin
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
         if (DATA_W >= SIGNAL_W) value_out <= data_out;
         else begin
            for (
                ii = 0;
                ii <
                `CEIL_DIV(SIGNAL_W, DATA_W);
                ii = ii + 1
            ) begin
               if (value_select == ii) begin
                  value_out <= fix_sim(32'h0 | data_out[32*ii+:32]);
               end
            end
         end
      end
   end

   assign value = value_out;

   // CURRENT VALUE LOGIC
   wire [TRIGGER_W-1:0] trigger_value_reg;
   iob_reg_r #(
      .DATA_W (TRIGGER_W),
      .RST_VAL(0),
   ) trigger_value_reg_reg (
      .clk_i (sampling_clk),
      .arst_i(arst_i),
      .rst_i(rst_int),
      .cke_i(cke_i),
      .data_i(registed_trigger_1),
      .data_o(trigger_value_reg)
   );

   sig_clk #(
      TRIGGER_W
   ) trigger_sig_clk (
      .clk_i (sampling_clk),
      .arst_i(arst_i),
      .data_i(trigger_value_reg),
      .data_o(trigger_value)
   );

   wire [TRIGGER_W-1:0] active_trigger_reg;
   iob_reg_r #(
      .DATA_W (TRIGGER_W),
      .RST_VAL(0),
   ) active_trigger_reg_reg (
      .clk_i (sampling_clk),
      .arst_i(arst_i),
      .rst_i(rst_int),
      .cke_i(cke_i),
      .data_i(trigger_out_1),
      .data_o(active_trigger_reg)
   );

   sig_clk #(
      TRIGGER_W
   ) trigger_sig_clk (
      .clk_i (sampling_clk),
      .arst_i(arst_i),
      .data_i(active_trigger_reg),
      .data_o(active_triggers)
   );

   // Partition current signal into various pieces
   integer              iii;
   reg     [DATA_W-1:0] current_signal;
   always @* begin
      current_signal = 32'h0;
      if (DATA_W >= SIGNAL_W) current_signal = registed_signal_1;
      else begin
         for (
             iii = 0;
             iii <
             `CEIL_DIV(SIGNAL_W, DATA_W);
             iii = iii + 1
         ) begin
            if (value_select == iii) begin
               current_signal = fix_sim(32'h0 | registed_signal_1[32*iii+:32]);
            end
         end
      end
   end

   wire [DATA_W-1:0] signal_value_reg;
   iob_reg_r #(
      .DATA_W (DATA_W),
      .RST_VAL(0),
   ) signal_value_reg_reg (
      .clk_i (sampling_clk),
      .arst_i(arst_i),
      .rst_i(rst_int),
      .cke_i(cke_i),
      .data_i(current_signal),
      .data_o(signal_value_reg)
   );

   sig_clk #(
      TRIGGER_W
   ) trigger_sig_clk (
      .clk_i (sampling_clk),
      .arst_i(arst_i),
      .data_i(signal_value_reg),
      .data_o(current_value)
   );

endmodule
