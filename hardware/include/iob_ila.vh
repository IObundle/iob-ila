//data and address widths
`define ILA_RDATA_W 32
`define ILA_WDATA_W 16
`define ILA_ADDR_W 3

`define ILA_MAX_SAMPLES_W 12

`define ILA_START_ENABLED 1'b1 // For the cases where we need to sample a signal before the CPU has time to init the module
