#include "iob-uart.h"
#include "printf.h"

// Init the ila module, by default the module 
void ila_init(int base,int enabled);

// Reset the ILA buffer
void ila_reset();

// Enable or disable the sampling of values
void ila_set_enabled(int enabled);

// Returns the number of samples currently stored in the ila buffer
 int ila_number_samples();

// Returns the value as a 32 bit of the sample at position index
 int ila_get_value(int index);
