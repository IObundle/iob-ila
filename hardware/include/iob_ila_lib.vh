`define CEIL_DIV(A,B) (A % B == 0 ? (A / B) : ((A/B) + 1))
`define CALCULATE_SIGNAL_SEL_W(DATA_W,SIGNAL_W) (DATA_W >= SIGNAL_W ? 1 : $clog2(`CEIL_DIV(SIGNAL_W,DATA_W)))

