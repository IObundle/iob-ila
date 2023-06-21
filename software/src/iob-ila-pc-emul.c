#include "iob-ila.h"

static int ila_base;

void ila_init(int base){
  ila_base = base;
}

void ila_reset(){}

void ila_set_trigger_type(int trigger,int type){}

void ila_set_trigger_enabled(int trigger,int enabled_bool){}

void ila_set_trigger_negated(int trigger,int negate_bool){}

void ila_enable_all_triggers(){}

void ila_disable_all_triggers(){}

void ila_set_time_offset(int amount){}

void ila_set_reduce_type(int reduceType){}

int ila_number_samples(){return 0;}

int ila_get_value(int index){return 0;}

int ila_get_large_value(int index,int partSelect){return 0;}

int ila_get_current_value(){return 0;}

int ila_get_current_large_value(int partSelect){return 0;}

int ila_get_current_triggers(){return 0;}

int ila_get_current_active_triggers(){return 0;}

void ila_set_different_signal_storing(int enabled_bool){}

void ila_print_current_configuration(){}