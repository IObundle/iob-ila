#include "interconnect.h"
#include "iob-ila.h"
#include "../ILAsw_reg.h"

//base address
static int base;

void ila_init(int base_address,int enabled){
  base = base_address;

  ila_set_enabled(enabled);
}

// Reset
void ila_reset(){
  IO_SET(base,ILA_SOFTRESET,1);
  IO_SET(base,ILA_SOFTRESET,0);	
}

// Enable or disable the sampling of values
void ila_set_enabled(int enabled){
  IO_SET(base,ILA_ENABLED,enabled ? 1 : 0);
}

// Returns the number of samples currently stored in the ila buffer
 int ila_number_samples(){
 	return IO_GET(base,ILA_SAMPLES);
 }

// Returns the value as a 32 bit of the sample at position index
 int ila_get_value(int index){
 	IO_SET(base,ILA_INDEX,index);
 	return IO_GET(base,ILA_DATA);
 }
