`timescale 1ns/1ps
`include "iob_ila.vh"

module ila_tb;

   parameter clk_frequency = 100e6; //100 MHz
   parameter clk_per = 1e9/clk_frequency;

   //iterator
   integer               i;

   // CORE SIGNALS
   reg 			rst;
   reg 			clk;

   initial begin

`ifdef VCD
      $dumpfile("ila.vcd");
      $dumpvars;
`endif
      
      clk = 1;
      rst = 1;

      $display("Test completed successfully");
      $finish;

   end 

   //
   // CLOCK
   //

   //system clock
   always #(clk_per/2) clk = ~clk;


  // Instantiate the Unit Under Test (UUT)
   ila_core uut
     (
      .clk(clk),
      .rst(rst)
     );

endmodule

