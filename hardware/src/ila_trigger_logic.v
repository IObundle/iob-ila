`timescale 1ns/1ps

`include "iob_ila_conf.vh"

module ila_trigger_logic (
    input [1-1:0] trigger_in,
    input [1-1:0] mask,
    input [1-1:0] negate,
    input [1-1:0] trigger_type,
    input [1-1:0] reduce_type,

    output [1-1:0] trigger_out,

    input [1-1:0] clk,
    input [1-1:0] rst
    );

wire trigger_neg = (trigger_in ^ negate);

wire trigger = (reduce_type == `IOB_ILA_REDUCE_OR ? (trigger_neg & mask): // When reduce is  OR, mask = 0 sets signal to 0 (OR  identity)
                                                 (trigger_neg | !mask)); // When reduce is AND, mask = 0 sets signal to 1 (AND identity)

reg trigger_activated;

always @(posedge clk,posedge rst)
  begin
  if(rst) 
      trigger_activated <= 0;
  else if (trigger_type == `IOB_ILA_CONTINUOUS_TYPE)
      trigger_activated <=  trigger_activated | trigger;
  end

reg [1-1:0] trigger_val;
assign trigger_out = trigger_val;

always @*
   begin
    case(trigger_type)
      `IOB_ILA_SINGLE_TYPE:     trigger_val = trigger;
      `IOB_ILA_CONTINUOUS_TYPE: trigger_val = trigger_activated | trigger;
       default: ; // Do nothing
    endcase
   end

endmodule
