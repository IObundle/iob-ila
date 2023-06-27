`timescale 1ns / 1ps
`include "iob_ila_conf.vh"

module ila_tb;

   parameter clk_frequency = 100e6;  //100 MHz
   parameter clk_per = 1e9 / clk_frequency;

   //iterator
   integer i;

   // CORE SIGNALS
   reg     rst;
   reg     clk;

   reg     rst_soft;

   reg     ila_special_trigger_mask;

   reg ila_trigger, ila_trigger2;
   reg [7:0] ila_signal, ila_index;

   reg       ila_value_select;
   reg [1:0] ila_value_select2;

   initial begin

`ifdef VCD
      $dumpfile("ila.vcd");
      $dumpvars;
`endif

      clk                      = 1;
      rst                      = 1;
      rst_soft                 = 0;
      ila_trigger              = 0;
      ila_trigger2             = 0;
      ila_signal               = 0;
      ila_index                = 0;
      ila_value_select         = 0;
      ila_value_select2        = 0;
      ila_special_trigger_mask = 0;

      // deassert hard reset
      #100 @(posedge clk) #1 rst = 0;
      #100 @(posedge clk);

      ila_signal = 8'h1;

      @(posedge clk) #1;

      ila_signal  = 8'h2;
      ila_trigger = 1'b1;

      @(posedge clk) #1;

      ila_signal  = 8'h3;
      ila_trigger = 1'b0;

      @(posedge clk) #1;

      ila_signal   = 8'h4;
      ila_trigger2 = 1'b1;

      @(posedge clk) #1;

      ila_signal   = 8'h5;
      ila_trigger2 = 1'b0;

      @(posedge clk) #1;

      ila_signal   = 8'h6;
      ila_trigger2 = 1'b1;

      @(posedge clk) #1;

      ila_signal  = 8'h7;
      ila_trigger = 1'b1;

      @(posedge clk) #1;

      ila_signal        = 8'h8;
      ila_trigger2      = 1'b0;
      ila_value_select2 = 2'h1;

      @(posedge clk) #1;

      ila_signal        = 8'h9;
      ila_trigger       = 1'b0;
      ila_value_select2 = 2'h2;

      @(posedge clk) #1;

      ila_signal        = 8'h10;
      ila_value_select  = 1'b1;
      ila_value_select2 = 2'h3;

      @(posedge clk) #1;

      ila_value_select  = 1'b0;
      ila_value_select2 = 2'h0;

      for (i = 0; i < 5; i = i + 1) @(posedge clk) #1;

      rst                      = 1;
      ila_signal               = 0;
      ila_trigger              = 0;
      ila_trigger2             = 0;
      ila_signal               = 0;
      ila_index                = 0;
      ila_value_select         = 0;
      ila_value_select2        = 0;
      ila_special_trigger_mask = 1'b1;

      for (i = 0; i < 5; i = i + 1) @(posedge clk) #1;

      rst = 0;

      for (i = 0; i < 5; i = i + 1) @(posedge clk) #1;

      ila_signal = 1;

      @(posedge clk) #1;

      ila_trigger  = 1'b1;
      ila_trigger2 = 1'b1;

      @(posedge clk) #1;

      ila_signal = 2;

      @(posedge clk) #1;

      @(posedge clk) #1;

      ila_trigger  = 1'b0;
      ila_trigger2 = 1'b0;

      @(posedge clk) #1;

      ila_signal = 3;

      @(posedge clk) #1;

      ila_signal = 2;

      @(posedge clk) #1;

      ila_trigger  = 1'b1;
      ila_trigger2 = 1'b1;

      @(posedge clk) #1;

      ila_trigger  = 1'b0;
      ila_trigger2 = 1'b0;

      for (i = 0; i < 20; i = i + 1) @(posedge clk) #1;
      $finish;
   end

   //
   // CLOCK
   //

   //system clock
   always #(clk_per / 2) clk = ~clk;

`define UUT_INSTANCE(TYPE,NEGATE,DELAY_TRIGGER,DELAY_SIGNAL,NAME)  \
   ila_core #(  \
     .DATA_W(32), /*Interface expects 32 bits*/ \
     .BUFFER_W(8), \
     .SIGNAL_W(8), /* Signal only takes 8 bits*/ \
     .TRIGGER_W(1) /* Only one trigger*/ \
     ) \
     uut_``NAME \
     ( \
       /* Trigger and signals to sample*/\
      .signal(ila_signal), \
      .trigger(ila_trigger), \
      .sampling_clk(clk), \
       /* Trigger and signal configuration*/\
      .trigger_type(TYPE), \
      .negate_trigger(NEGATE), \
      .trigger_mask(1'b1), \
      .delay_trigger(DELAY_TRIGGER), \
      .delay_signal(DELAY_SIGNAL), \
      .reduce_type(`IOB_ILA_REDUCE_OR), \
      /* Mask for special triggers*/\
      .special_trigger_mask(ila_special_trigger_mask), \
       /* Software side access to values sampled*/\
      .index(ila_index), \
      .samples(), \
      .value(), \
      .value_select(1'b0),\
       /* Enabled reset and system clk*/\
      .rst_soft(rst_soft), \
      .clk_i(clk), \
      .rst_i(rst) \
     );

`UUT_INSTANCE(`IOB_ILA_SINGLE_TYPE,1'b0,1'b0,1'b0,SINGLE_NO_DELAY)
`UUT_INSTANCE(`IOB_ILA_SINGLE_TYPE,1'b1,1'b0,1'b0,SINGLE_NEGATE_NO_DELAY)
`UUT_INSTANCE(`IOB_ILA_SINGLE_TYPE,1'b0,1'b1,1'b0,SINGLE_TRIGGER_DELAY)
`UUT_INSTANCE(`IOB_ILA_SINGLE_TYPE,1'b0,1'b0,1'b1,SINGLE_SIGNAL_DELAY)

`UUT_INSTANCE(`IOB_ILA_CONTINUOUS_TYPE,1'b0,1'b0,1'b0,CONTINUOUS_NO_DELAY)
`UUT_INSTANCE(`IOB_ILA_CONTINUOUS_TYPE,1'b1,1'b0,1'b0,CONTINUOUS_NEGATE_NO_DELAY)
`UUT_INSTANCE(`IOB_ILA_CONTINUOUS_TYPE,1'b0,1'b1,1'b0,CONTINUOUS_TRIGGER_DELAY)
`UUT_INSTANCE(`IOB_ILA_CONTINUOUS_TYPE,1'b0,1'b0,1'b1,CONTINUOUS_SIGNAL_DELAY)

   wire and_reduce_type = ~1'b`IOB_ILA_REDUCE_OR;

   ila_core #(
      .DATA_W   (32),  // Interface expects 32 bits
      .BUFFER_W (8),
      .SIGNAL_W (8),   // Signal only takes 8 bits
      .TRIGGER_W(2)    // Only one trigger
   ) uut_SINGLE_2_TRIGGERS_AND (
      // Trigger and signals to sample
      .signal              (ila_signal),
      .trigger             ({ila_trigger2, ila_trigger}),
      .sampling_clk        (clk),
      // Trigger and signal configuration
      .trigger_type        ({`IOB_ILA_SINGLE_TYPE, `IOB_ILA_SINGLE_TYPE}),
      .negate_trigger      (2'b00),
      .trigger_mask        (2'b11),
      .delay_trigger       (1'b0),
      .delay_signal        (1'b0),
      .reduce_type         (and_reduce_type),
      // Mask for special triggers
      .special_trigger_mask(ila_special_trigger_mask),
      // Software side access to values sampled
      .index               (ila_index),
      .samples             (),
      .value               (),
      .value_select        (1'b0),
      // Enabled reset and system clk
      .rst_soft            (rst_soft),
      .clk_i                 (clk),
      .rst_i                 (rst)
   );

   ila_core #(
      .DATA_W   (32),  // Interface expects 32 bits
      .BUFFER_W (8),
      .SIGNAL_W (8),   // Signal only takes 8 bits
      .TRIGGER_W(2)    // Only one trigger
   ) uut_SINGLE_2_TRIGGERS_OR (
      // Trigger and signals to sample
      .signal              (ila_signal),
      .trigger             ({ila_trigger2, ila_trigger}),
      .sampling_clk        (clk),
      // Trigger and signal configuration
      .trigger_type        ({`IOB_ILA_SINGLE_TYPE, `IOB_ILA_SINGLE_TYPE}),
      .negate_trigger      (2'b00),
      .trigger_mask        (2'b11),
      .delay_trigger       (1'b0),
      .delay_signal        (1'b0),
      .reduce_type         (`IOB_ILA_REDUCE_OR),
      // Mask for special triggers
      .special_trigger_mask(ila_special_trigger_mask),
      // Software side access to values sampled
      .index               (ila_index),
      .samples             (),
      .value               (),
      .value_select        (1'b0),
      // Enabled reset and system clk
      .rst_soft            (rst_soft),
      .clk_i                 (clk),
      .rst_i                 (rst)
   );

   ila_core #(
      .DATA_W   (32),  // Interface expects 32 bits
      .BUFFER_W (8),
      .SIGNAL_W (8),   // Signal only takes 8 bits
      .TRIGGER_W(2)    // Only one trigger
   ) uut_SINGLE_2_TRIGGERS_FIRST_SINGLE_SECOND_CONTINUOUS_AND (
      // Trigger and signals to sample
      .signal              (ila_signal),
      .trigger             ({ila_trigger2, ila_trigger}),
      .sampling_clk        (clk),
      // Trigger and signal configuration
      .trigger_type        ({`IOB_ILA_CONTINUOUS_TYPE, `IOB_ILA_SINGLE_TYPE}),
      .negate_trigger      (2'b00),
      .trigger_mask        (2'b11),
      .delay_trigger       (1'b0),
      .delay_signal        (1'b0),
      .reduce_type         (and_reduce_type),
      // Mask for special triggers
      .special_trigger_mask(ila_special_trigger_mask),
      // Software side access to values sampled
      .index               (ila_index),
      .samples             (),
      .value               (),
      .value_select        (1'b0),
      // Enabled reset and system clk
      .rst_soft            (rst_soft),
      .clk_i                 (clk),
      .rst_i                 (rst)
   );

   ila_core #(
      .DATA_W   (32),  // Interface expects 32 bits
      .BUFFER_W (8),
      .SIGNAL_W (8),   // Signal only takes 8 bits
      .TRIGGER_W(2)    // Only one trigger
   ) uut_CONTINUOUS_2_TRIGGERS_AND (
      // Trigger and signals to sample
      .signal              (ila_signal),
      .trigger             ({ila_trigger2, ila_trigger}),
      .sampling_clk        (clk),
      // Trigger and signal configuration
      .trigger_type        ({`IOB_ILA_CONTINUOUS_TYPE, `IOB_ILA_CONTINUOUS_TYPE}),
      .negate_trigger      (2'b00),
      .trigger_mask        (2'b11),
      .delay_trigger       (1'b0),
      .delay_signal        (1'b0),
      .reduce_type         (and_reduce_type),
      // Mask for special triggers
      .special_trigger_mask(ila_special_trigger_mask),
      // Software side access to values sampled
      .index               (ila_index),
      .samples             (),
      .value               (),
      .value_select        (1'b0),
      // Enabled reset and system clk
      .rst_soft            (rst_soft),
      .clk_i                 (clk),
      .rst_i                 (rst)
   );

   ila_core #(
      .DATA_W   (32),  // Interface expects 32 bits
      .BUFFER_W (8),
      .SIGNAL_W (8),   // Signal only takes 8 bits
      .TRIGGER_W(2)    // Only one trigger
   ) uut_CONTINUOUS_2_TRIGGERS_OR (
      // Trigger and signals to sample
      .signal              (ila_signal),
      .trigger             ({ila_trigger2, ila_trigger}),
      .sampling_clk        (clk),
      // Trigger and signal configuration
      .trigger_type        ({`IOB_ILA_CONTINUOUS_TYPE, `IOB_ILA_CONTINUOUS_TYPE}),
      .negate_trigger      (2'b00),
      .trigger_mask        (2'b11),
      .delay_trigger       (1'b0),
      .delay_signal        (1'b0),
      .reduce_type         (`IOB_ILA_REDUCE_OR),
      // Mask for special triggers
      .special_trigger_mask(ila_special_trigger_mask),
      // Software side access to values sampled
      .index               (ila_index),
      .samples             (),
      .value               (),
      .value_select        (1'b0),
      // Enabled reset and system clk
      .rst_soft            (rst_soft),
      .clk_i                 (clk),
      .rst_i                 (rst)
   );

   ila_core #(
      .DATA_W   (32),  // Interface expects 32 bits
      .BUFFER_W (8),
      .SIGNAL_W (8),   // Signal only takes 8 bits
      .TRIGGER_W(2)    // Only one trigger
   ) uut_SINGLE_2_TRIGGERS_AND_FIRST_TRIGGER_DISABLED (
      // Trigger and signals to sample
      .signal              (ila_signal),
      .trigger             ({ila_trigger2, ila_trigger}),
      .sampling_clk        (clk),
      // Trigger and signal configuration
      .trigger_type        ({`IOB_ILA_SINGLE_TYPE, `IOB_ILA_SINGLE_TYPE}),
      .negate_trigger      (2'b00),
      .trigger_mask        (2'b10),
      .delay_trigger       (1'b0),
      .delay_signal        (1'b0),
      .reduce_type         (and_reduce_type),
      // Mask for special triggers
      .special_trigger_mask(ila_special_trigger_mask),
      // Software side access to values sampled
      .index               (ila_index),
      .samples             (),
      .value               (),
      .value_select        (1'b0),
      // Enabled reset and system clk
      .rst_soft            (rst_soft),
      .clk_i                 (clk),
      .rst_i                 (rst)
   );

   ila_core #(
      .DATA_W   (32),  // Interface expects 32 bits
      .BUFFER_W (8),
      .SIGNAL_W (64),  // Signal takes 64 bytes
      .TRIGGER_W(1)    // Only one trigger
   ) uut_64_BITS_SIGNAL_SINGLE_NO_DELAY (
      // Trigger and signals to sample
      .signal({32'h0 | (ila_signal + 32'h1), 32'h0 | ila_signal}),
      .trigger(ila_trigger),
      .sampling_clk(clk),
      // Trigger and signal configuration
      .trigger_type(`IOB_ILA_SINGLE_TYPE),
      .negate_trigger(1'b0),
      .trigger_mask(1'b1),
      .delay_trigger(1'b0),
      .delay_signal(1'b0),
      .reduce_type(`IOB_ILA_REDUCE_OR),
      // Mask for special triggers
      .special_trigger_mask(ila_special_trigger_mask),
      // Software side access to values sampled
      .index(ila_index),
      .samples(),
      .value(),
      .value_select(ila_value_select),  // Selects value to output
      // Enabled reset and system clk
      .rst_soft(rst_soft),
      .clk_i(clk),
      .rst_i(rst)
   );

   ila_core #(
      .DATA_W   (32),   // Interface expects 32 bits
      .BUFFER_W (8),
      .SIGNAL_W (128),  // Signal takes 128 bytes
      .TRIGGER_W(1)     // Only one trigger
   ) uut_128_BITS_SIGNAL_SINGLE_NO_DELAY (
      // Trigger and signals to sample
      .signal({
         32'h0 | (ila_signal + 32'h3),
         32'h0 | (ila_signal + 32'h2),
         32'h0 | (ila_signal + 32'h1),
         32'h0 | ila_signal
      }),
      .trigger(ila_trigger),
      .sampling_clk(clk),
      // Trigger and signal configuration
      .trigger_type(`IOB_ILA_SINGLE_TYPE),
      .negate_trigger(1'b0),
      .trigger_mask(1'b1),
      .delay_trigger(1'b0),
      .delay_signal(1'b0),
      .reduce_type(`IOB_ILA_REDUCE_OR),
      // Mask for special triggers
      .special_trigger_mask(ila_special_trigger_mask),
      // Software side access to values sampled
      .index(ila_index),
      .samples(),
      .value(),
      .value_select(ila_value_select2),  // Selects value to output
      // Enabled reset and system clk
      .rst_soft(rst_soft),
      .clk_i(clk),
      .rst_i(rst)
   );
endmodule

