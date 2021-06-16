`timescale 1ns/1ps

`include "iob_lib.vh"
`include "iob_ila.vh"

`define CALCULATE_SIGNAL_SEL_W(DATA_W,SIGNAL_W) (DATA_W >= SIGNAL_W ? 1 : $clog2(SIGNAL_W / DATA_W))

module ila_core 
  #(
    parameter DATA_W = `ILA_RDATA_W,
    parameter SIGNAL_W = `ILA_SIGNAL_W,
    parameter BUFFER_W = `ILA_MAX_SAMPLES_W,
    parameter TRIGGER_W = 1
  )
  (
      // Trigger and signals to sample
    `INPUT(signal,SIGNAL_W),
    `INPUT(trigger,TRIGGER_W),
    `INPUT(sampling_clk,1),

      // Trigger and signal configuration
    `INPUT(trigger_type,TRIGGER_W),
    `INPUT(negate_trigger,TRIGGER_W),
    `INPUT(trigger_mask,TRIGGER_W),
    `INPUT(delay_trigger,1),
    `INPUT(delay_signal,1),
    `INPUT(reduce_type,1),

      // Software side access to values sampled
    `INPUT(index,BUFFER_W),
    `OUTPUT(samples,BUFFER_W),
    `OUTPUT(value,DATA_W),
    `INPUT(value_select,`CALCULATE_SIGNAL_SEL_W(DATA_W,SIGNAL_W)),

    // Enabled reset and system clk
    `INPUT(rst_soft,1),
   `include "gen_if.v"
   );
   
   //COMBINED SOFT/HARD RESET
   wire     rst_int = rst | rst_soft;

  // TRIGGER LOGIC

  // Applies trigger logic to every trigger
  wire [TRIGGER_W-1:0] trigger_out;
  generate
    genvar i;
    
    for(i = 0; i < TRIGGER_W; i = i + 1)
    begin
      ila_trigger_logic trigger_logic(
          .trigger_in(trigger[i]),
          .mask(trigger_mask[i]),
          .negate(negate_trigger[i]),
          .trigger_type(trigger_type[i]),
          .reduce_type(reduce_type),

          .trigger_out(trigger_out[i]),

          .clk(sampling_clk),
          .rst(rst_int)
        );
    end
  endgenerate

  // Computes the final trigger value
  wire trigger_reduce_or =  |trigger_out;
  wire trigger_reduce_and = &trigger_out;

  wire trigger_reduce_out = (reduce_type == `ILA_REDUCE_OR ? trigger_reduce_or : trigger_reduce_and);

  // Selects between current trigger or delayed trigger
  reg previous_trigger,write_en;
  `REG_AR(sampling_clk,rst_int,0,previous_trigger,trigger_reduce_out)

  wire final_trigger = (delay_trigger ? previous_trigger : trigger_reduce_out);
  `REG_AR(sampling_clk,rst_int,0,write_en,final_trigger) // Add a "pipeline" register to the trigger

  // SIGNAL LOGIC
  reg [SIGNAL_W-1:0] previous_signal,signal_data;
  `REG_AR(sampling_clk,rst_int,0,previous_signal,signal)

  wire [SIGNAL_W-1:0] final_signal = (delay_signal ? previous_signal : signal);
  `REG_AR(sampling_clk,rst_int,0,signal_data,final_signal) //  Add a "pipeline" register to the signal

  // Both the trigger and signal have a "pipeline" register that serves to improve both the time constraints, as well as speed up
  // compilation (the compiler has to spend less time moving logic around to accomodate the ILA)

  // INDEX LOGIC
  `SIGNAL(n_samples,BUFFER_W)
  
  // Memory write index logic 
  wire full = ((&n_samples) == 1'b1);
  `ACC_ARE(sampling_clk,rst_int,0,write_en && !full,n_samples,1)

  // Memory instance
  wire [SIGNAL_W-1:0] data_out;
   iob_2p_async_mem #(
        .DATA_W(SIGNAL_W),
        .ADDR_W(BUFFER_W))
    buffer (
        .wclk(sampling_clk),
        .w_en(write_en),
        .data_in(signal_data),
        .w_addr(n_samples),
        .rclk(clk),
        .r_addr(index),
        .r_en(1'b1),
        .data_out(data_out)
    );

  // Pass n_samples from sampling_clk domain to sys domain
  `SIGNAL(sys_samples,BUFFER_W)

   reg [BUFFER_W-1:0] n_samples_sync_0,n_samples_sync_1;
   always @(posedge clk, posedge rst)
   if(rst) begin
      n_samples_sync_0 <= 0;
      n_samples_sync_1 <= 0;
   end else begin
      n_samples_sync_0 <= n_samples;
      n_samples_sync_1 <= n_samples_sync_0;
   end
   `COMB sys_samples = n_samples_sync_1;

  `SIGNAL2OUT(samples,sys_samples)

  // Partition signal into multiple parts to fit DATA_W
  `SIGNAL(value_out,DATA_W)
  `SIGNAL2OUT(value,value_out)

  integer ii;
  always @*
  begin
    value_out = 32'h0;
    if(DATA_W >= SIGNAL_W)
      value_out = data_out;
    else begin
      for(ii = 0; ii < (SIGNAL_W / DATA_W); ii = ii + 1)
      begin
        if(value_select == ii)
        begin
          value_out = data_out[32*ii +: 32];
        end
      end
    end
  end

endmodule
