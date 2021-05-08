#include "interconnect.h"
#include "iob-ila.h"
#include "ILAsw_reg.h"

//base address
static int base;

void ila_init(int base_address){
  base = base_address;

  printf("%d\n",IO_GET(base,ILA_DATA));
}
