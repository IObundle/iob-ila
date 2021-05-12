`timescale 1ns/1ps
`include "iob_ila.vh"

module ila_tb;

   parameter clk_frequency = 100e6; //100 MHz
   parameter clk_per = 1e9/clk_frequency;

   //iterator
   integer               i;

   // CORE SIGNALS
   reg 			 rst;
   reg 			 clk;

   reg       rst_soft;

   reg       ila_trigger,ila_enabled;
   reg[7:0]  ila_signal,ila_index;

   wire[7:0] ila_samples,ila_value;

   initial begin

`ifdef VCD
      $dumpfile("ila.vcd");
      $dumpvars;
`endif
      
      clk = 1;
      rst = 1;
      rst_soft = 0;
      ila_trigger = 0;
      ila_enabled = 0;
      ila_signal = 0;
      ila_index = 0;

      // deassert hard reset
      #100 @(posedge clk) #1 rst = 0;
      #100 @(posedge clk);

      ila_signal = 8'hfe;

      @(posedge clk) #1;

      ila_signal = 8'h12;
      ila_enabled = 1'b1;
      ila_trigger = 1'b1;

      @(posedge clk) #1;

      ila_enabled = 1'b0;
      ila_signal = 8'hfe;

      @(posedge clk) #1;

      ila_enabled = 1'b1;
      ila_trigger = 1'b0;

      @(posedge clk) #1;

      ila_trigger = 1'b1;
      ila_signal  = 8'h21;

      @(posedge clk) #1;

      ila_trigger = 1'b0;

      @(posedge clk) #1;
      
      ila_index = 0;

      @(posedge clk) #1;

      if(ila_value != 8'h12)
        $display("Different value for index 0");
      ila_index = 1;

      @(posedge clk) #1;

      if(ila_value != 8'h21)
        $display("Different value for index 1");

      @(posedge clk) #1;

      $display("Test completed successfully");
      $finish;
   end 

   //
   // CLOCK
   //

   //system clock
   always #(clk_per/2) clk = ~clk;

   // Instantiate the Unit Under Test (UUT)
   ila_core #(
     .DATA_W(8),
     .BUFFER_W(8)
     ) 
     uut
     (
      .signal(ila_signal),
      .trigger(ila_trigger),
      .sampling_clk(clk),

      .index(ila_index),
      .samples(ila_samples),
      .value(ila_value),

      .enabled(ila_enabled),
      .rst_soft(rst_soft),
      .clk(clk),
      .rst(rst)
     );

endmodule

