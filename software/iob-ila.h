#define ILA_TRIGGER_TYPE_SINGLE     0
#define ILA_TRIGGER_TYPE_CONTINUOUS 1

#define ILA_REDUCE_TYPE_OR  0
#define ILA_REDUCE_TYPE_AND 1

// Init the ila module, all triggers are disabled initially
void ila_init(int base,int numberTriggers);

// Reset the ILA buffer, and any active continuous trigger 
void ila_reset();

// Set the trigger type
void ila_trigger_type(int trigger,int type);

// Enable or disable a particular trigger
void ila_set_enabled_trigger(int trigger,int enabled_bool);

// Set whether the trigger is to be negated
void ila_set_negate_trigger(int trigger,int negate_bool);

// Enables every trigger
void ila_enable_all_triggers();

// Disable every trigger (equivalent to disabling ila)
void ila_disable_all_triggers();

// Set whether the trigger is delayed by one cycle
void ila_set_delay_trigger(int delay_bool);

// Set whether the signal is delayed by one cycle
void ila_set_delay_signal(int delay_bool);

// Set the reduce type for multiple triggers 
void ila_set_reduce_type(int reduceType);

// Returns the number of samples currently stored in the ila buffer
int ila_number_samples();

// Returns the value sampled
int ila_get_value(int index); 

// Returns the value as a 32 bit of the sample at position index
int ila_get_large_value(int index,int partSelect); // For signals bigger than 32 bits, they are partition into 32 bit parts which are selected by partSelect (0 -> first 32 bits, 1 -> second 32 bits and so on)

void ila_print_current_configuration();