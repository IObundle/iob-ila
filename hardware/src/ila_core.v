`timescale 1ns/1ps
`include "iob_lib.vh"
`include "iob_ila.vh"

module ila_core 
  (
   `include "gen_if.v"
   );
   
                  
   //COMBINED SOFT/HARD RESET
   wire       rst_int = rst;
   
endmodule
