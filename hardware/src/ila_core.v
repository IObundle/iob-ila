`timescale 1ns/1ps

`include "iob_lib.vh"
`include "iob_ila.vh"
`include "iob_ila_lib.vh"

`define SIG_CLK(W,IN,OUT,CLK,RST) \
  reg [W-1:0] OUT``_sync_0,OUT``_sync_1; \
always @(posedge CLK, posedge RST) \
  if(RST) begin \
    OUT``_sync_0 <= 0; \
    OUT``_sync_1 <= 0; \
  end else begin \
    OUT``_sync_0 <= IN; \
    OUT``_sync_1 <= OUT``_sync_0; \
  end \
  `IOB_COMB OUT = OUT``_sync_1;

module ila_core 
  #(
    parameter DATA_W = 0,
    parameter SIGNAL_W = 0,
    parameter BUFFER_W = 0,
    parameter TRIGGER_W = 0
  )
  (
    // Trigger and signals to sample
    `IOB_INPUT(signal,SIGNAL_W),
    `IOB_INPUT(trigger,TRIGGER_W),
    `IOB_INPUT(sampling_clk,1),

    // Trigger and signal configuration
    `IOB_INPUT(trigger_type,TRIGGER_W),
    `IOB_INPUT(negate_trigger,TRIGGER_W),
    `IOB_INPUT(trigger_mask,TRIGGER_W),

     // Miscellaneous items
    `IOB_INPUT(misc_enabled, 32),

      // Software side access to values sampled
    `IOB_INPUT(index,BUFFER_W),
    `IOB_OUTPUT(samples,BUFFER_W),
    `IOB_OUTPUT(value,DATA_W),
    `IOB_INPUT(value_select,`CALCULATE_SIGNAL_SEL_W(DATA_W,SIGNAL_W)),

    // Software side access to current values
    output reg [DATA_W-1:0] current_value,
    output reg [TRIGGER_W-1:0] trigger_value,
    output reg [TRIGGER_W-1:0] active_triggers,

    // Enabled reset and system clk
   input clk,
   input rst
   );
   
  function [31:0] fix_sim(input [31:0] in);
    `ifdef SIM
      integer i;
      for(i = 0; i < 32; i = i + 1)
        fix_sim[i] = (in[i] === 1'bx ? 1'b0 : in[i]);
    `else
        fix_sim = in;
    `endif
  endfunction
   
   reg [2**$clog2(SIGNAL_W)-1:0] registed_signal_1;
   reg [TRIGGER_W-1:0] registed_trigger_1;

   always @(posedge clk, posedge rst)
   begin
     if(rst)begin
        registed_signal_1 <= 0;
        registed_trigger_1 <= 0;
     end else begin
        registed_signal_1 <= signal;
        registed_trigger_1 <= trigger;
     end
   end

   wire rst_soft        = misc_enabled[0];
   wire diff_signal     = misc_enabled[1];
   wire circular_buffer = misc_enabled[2];
   wire delay_trigger   = misc_enabled[3];
   wire delay_signal    = misc_enabled[4];
   wire reduce_type     = misc_enabled[5];

   //COMBINED SOFT/HARD RESET
   wire     rst_int = rst | rst_soft;

  // TRIGGER LOGIC

  // Applies trigger logic to every trigger
  wire [TRIGGER_W-1:0] trigger_out_1;
  generate
    genvar i;
    
    for(i = 0; i < TRIGGER_W; i = i + 1)
    begin
      ila_trigger_logic trigger_logic(
          .trigger_in(registed_trigger_1[i]),
          .mask(trigger_mask[i]),
          .negate(negate_trigger[i]),
          .trigger_type(trigger_type[i]),
          .reduce_type(reduce_type),

          .trigger_out(trigger_out_1[i]),

          .clk(sampling_clk),
          .rst(rst_int)
        );
    end
  endgenerate

  // Computes the final trigger value
  wire trigger_reduce_or =  |trigger_out_1;
  wire trigger_reduce_and = &trigger_out_1;

  wire trigger_reduce_out_1 = (reduce_type == `ILA_REDUCE_OR ? trigger_reduce_or : trigger_reduce_and);

  // Selects between current trigger or delayed trigger
  reg previous_trigger,trigger_enable_wr_2;
  `IOB_REG_AR(sampling_clk,rst_int,0,previous_trigger,trigger_reduce_out_1)

  wire final_trigger_1 = (delay_trigger ? previous_trigger : trigger_reduce_out_1);
  `IOB_REG_AR(sampling_clk,rst_int,0,trigger_enable_wr_2,final_trigger_1) // Add a "pipeline" register to the trigger

  // SIGNAL LOGIC
  reg [2**$clog2(SIGNAL_W)-1:0] previous_signal,signal_data_2;
  `IOB_REG_AR(sampling_clk,rst_int,0,previous_signal,registed_signal_1)

  wire [2**$clog2(SIGNAL_W)-1:0] final_signal_1 = (delay_signal ? previous_signal : registed_signal_1);
  `IOB_REG_AR(sampling_clk,rst_int,0,signal_data_2,final_signal_1) //  Add a "pipeline" register to the signal

  // Both the trigger and signal have a "pipeline" register that serves to improve time constraints

  // INDEX LOGIC
  `IOB_VAR(n_samples,BUFFER_W)
  
  // Memory write index logic
  wire different_signal_enable_wr;

  wire write_en_2 = (trigger_enable_wr_2 & different_signal_enable_wr);

  wire full = ((&n_samples) == 1'b1);
  `IOB_ACC_ARE(sampling_clk,rst_int,0,write_en_2 && !full,n_samples,1)

  // Memory instance
  wire [2**$clog2(SIGNAL_W)-1:0] data_out;
   iob_ram_t2p #(
        .DATA_W(SIGNAL_W),
        .ADDR_W(BUFFER_W))
    buffer (
        .w_clk(sampling_clk),
        .w_en(write_en_2),
        .w_data(signal_data_2[SIGNAL_W-1:0]),
        .w_addr(n_samples),
        .r_clk(clk),
        .r_addr(index),
        .r_en(1'b1),
        .r_data(data_out[SIGNAL_W-1:0])
    );

  // Pass n_samples from sampling_clk domain to sys domain
  `IOB_VAR(sys_samples,BUFFER_W)

   reg [BUFFER_W-1:0] n_samples_sync_0,n_samples_sync_1;
   always @(posedge clk, posedge rst)
   if(rst) begin
      n_samples_sync_0 <= 0;
      n_samples_sync_1 <= 0;
   end else begin
      n_samples_sync_0 <= n_samples;
      n_samples_sync_1 <= n_samples_sync_0;
   end
   `IOB_COMB sys_samples = n_samples_sync_1;

  `IOB_WIRE2WIRE(sys_samples,samples)

  // Special trigger - Different signal logic
  reg [2**$clog2(SIGNAL_W)-1:0] last_written_signal;

  assign different_signal_enable_wr = ((last_written_signal != signal_data_2) | !diff_signal);

  always @(posedge clk,posedge rst_int)
  begin
    if(rst_int)
    begin
      last_written_signal <= 0;
    end
    else if(write_en_2)
    begin
        last_written_signal <= signal_data_2;
    end
  end

  // Partition signal into multiple parts to fit DATA_W
  `IOB_VAR(value_out,DATA_W)

  integer ii;
  always @(posedge clk,posedge rst)
  begin
    if(rst) begin
      value_out <= 0;
    end else begin
      if(DATA_W >= SIGNAL_W)
        value_out <= data_out;
      else begin
        for(ii = 0; ii < `CEIL_DIV(SIGNAL_W,DATA_W); ii = ii + 1)
        begin
          if(value_select == ii)
          begin
            value_out <= fix_sim(32'h0 | data_out[32*ii +: 32]);
          end
        end
      end      
    end
  end

  `IOB_WIRE2WIRE(value_out,value)

  // CURRENT VALUE LOGIC
  reg [TRIGGER_W-1:0] trigger_value_reg;
  `IOB_REG_AR(sampling_clk,rst_int,0,trigger_value_reg,registed_trigger_1)

  `SIG_CLK(TRIGGER_W,trigger_value_reg,trigger_value,sampling_clk,rst)

  reg [TRIGGER_W-1:0] active_trigger_reg;
  `IOB_REG_AR(sampling_clk,rst_int,0,active_trigger_reg,trigger_out_1)

  `SIG_CLK(TRIGGER_W,active_trigger_reg,active_triggers,sampling_clk,rst)

  // Partition current signal into various pieces
  integer iii;
  reg [DATA_W-1:0] current_signal;
  always @*
  begin
    current_signal = 32'h0;
    if(DATA_W >= SIGNAL_W)
      current_signal = registed_signal_1;
    else begin
      for(iii = 0; iii < `CEIL_DIV(SIGNAL_W,DATA_W); iii = iii + 1)
      begin
        if(value_select == iii)
        begin
          current_signal = fix_sim(32'h0 | registed_signal_1[32*iii +: 32]);
        end
      end
    end
  end

  reg [DATA_W-1:0] signal_value_reg;
  `IOB_REG_AR(sampling_clk,rst_int,0,signal_value_reg,current_signal)

  `SIG_CLK(TRIGGER_W,signal_value_reg,current_value,sampling_clk,rst)

endmodule
