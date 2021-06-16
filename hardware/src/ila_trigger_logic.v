`timescale 1ns/1ps

`include "iob_lib.vh"

module ila_trigger_logic (
    `INPUT(trigger_in,1),
    `INPUT(mask,1),
    `INPUT(negate,1),
    `INPUT(trigger_type,1),
    `INPUT(reduce_type,1),

    `OUTPUT(trigger_out,1),

    `INPUT(clk,1),
    `INPUT(rst,1)
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

`SIGNAL(trigger_val,1)
`SIGNAL2OUT(trigger_out,trigger_val)

always @*
   begin
    case(trigger_type)
      `ILA_SINGLE_TYPE:     trigger_val = trigger;
      `ILA_CONTINUOUS_TYPE: trigger_val = trigger_activated | trigger;
    endcase
   end

endmodule