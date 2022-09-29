`timescale 1ns/1ps

`include "iob_lib.vh"

module ila_trigger_logic (
    `IOB_INPUT(trigger_in,1),
    `IOB_INPUT(mask,1),
    `IOB_INPUT(negate,1),
    `IOB_INPUT(trigger_type,1),
    `IOB_INPUT(reduce_type,1),

    `IOB_OUTPUT(trigger_out,1),

    `IOB_INPUT(clk,1),
    `IOB_INPUT(rst,1)
    );

wire trigger_neg = (trigger_in ^ negate);

wire trigger = (reduce_type == `ILA_REDUCE_AND ? (trigger_neg | !mask): // When reduce is AND, mask = 0 sets signal to 1 (AND identity)
                                                 (trigger_neg & mask)); // When reduce is  OR, mask = 0 sets signal to 0 (OR  identity)

reg trigger_activated;

always @(posedge clk,posedge rst)
  begin
    if(rst) 
      trigger_activated <= 0;
  else if (trigger_type == `ILA_CONTINUOUS_TYPE)
      trigger_activated <=  trigger_activated | trigger;
  end

`IOB_VAR(trigger_val,1)
`IOB_WIRE2WIRE(trigger_val,trigger_out)

always @*
   begin
    case(trigger_type)
      `ILA_SINGLE_TYPE:     trigger_val = trigger;
      `ILA_CONTINUOUS_TYPE: trigger_val = trigger_activated | trigger;
    endcase
   end

endmodule