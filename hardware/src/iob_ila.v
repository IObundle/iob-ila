`timescale 1ns/1ps
`include "iob_lib.vh"
`include "iob_ila.vh"
`include "ILAsw_reg.vh"

module iob_ila 
  # (
     parameter ADDR_W = `ILA_ADDR_W, //NODOC Address width
     parameter DATA_W = `ILA_RDATA_W, //NODOC CPU data width
     parameter WDATA_W = `ILA_WDATA_W //NODOC CPU data width
     )

  (
   //CPU interface
`ifndef USE_AXI4LITE
 `include "cpu_nat_s_if.v"
`else
 `include "cpu_axi4lite_s_if.v"
`endif
   //additional inputs and outputs
`include "gen_if.v"
   );

//BLOCK Register File & Holds the current configuration of the ILA as well as internal parameters. Data to be sent or that has been received is stored here temporarily.
`include "ILAsw_reg.v"
`include "ILAsw_reg_gen.v"
   
`SIGNAL2OUT(ILA_DATA,8'd12);

   ila_core ila_core0 
     (
      .clk(clk),
      .rst(rst)
     );
   
endmodule


