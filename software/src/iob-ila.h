#include <stdint.h>

#define ILA_TRIGGER_TYPE_SINGLE     0
#define ILA_TRIGGER_TYPE_CONTINUOUS 1

#define ILA_REDUCE_TYPE_OR  0
#define ILA_REDUCE_TYPE_AND 1

// Init the ila module, all triggers are disabled initially
void ila_init(int base);

// Reset the ILA buffer, and any active continuous trigger 
void ila_reset();

// Set the trigger type
void ila_set_trigger_type(int trigger,int type);

// Enable or disable a particular trigger
void ila_set_trigger_enabled(int trigger,int enabled_bool);

// Set whether the trigger is to be negated
void ila_set_trigger_negated(int trigger,int negate_bool);

// Enables every trigger
void ila_enable_all_triggers();

// Disable every trigger (equivalent to disabling ila)
void ila_disable_all_triggers();

// Time offset between the moment the trigger is asserted and the moment the signal is sampled
// Valid values are: -1 (the signal is sampled one cycle before the trigger is asserted)
//                    0 (the signal is sampled in the cycle where the trigger is asserted)
//                    1 (the signal is sampled one cycle after the trigger is asserted)
// Any other value is clamped into {-1,0,1}  
void ila_set_time_offset(int amount);

// Set the reduce type for multiple triggers 
void ila_set_reduce_type(int reduceType);

// Returns the number of samples currently stored in the ila buffer
int ila_number_samples();

// Returns the value sampled
int ila_get_value(int index); 

// Returns 32 bits of the signal (each partSelect selects one 32 bit part)
uint32_t ila_get_large_value(int index,int partSelect); // For signals bigger than 32 bits, they are partition into 32 bit parts which are selected by partSelect (0 -> first 32 bits, 1 -> second 32 bits and so on)

// Returns the value of the signal right now (does not mean it is stored in the buffer)
int ila_get_current_value();

// Returns 32 bits of the value of the signal right now
uint32_t ila_get_current_large_value(int partSelect);

// Returns the value of the trigger signal, directly from input (does not take into account negation or type)
int ila_get_current_triggers();

// Returns the value of the triggers taking into account negation and type (For continuous triggers, the bit is asserted if the trigger has been activated)
int ila_get_current_active_triggers();

// If set to true, the ila does not store the signal unless it is different than the one previously stored
void ila_set_different_signal_storing(int enabled_bool);

// Prints current values for trigger types, negation, reduce type 
void ila_print_current_configuration();

// Get size needed for buffer argument for ila_output_data (need to generate source from format file, otherwise linker error)
int ila_output_data_size(int number_samples, int ila_dword_size);

// Output ila data to later be transformed into a vcd file (need to generate source from format file, otherwise linker error)
// buffer: Pointer to the buffer
// start, end: Start and end sample number, respectively.
// ila_dword_size: Number of words per sample. Value is auto generated for each instance, in file <instance_name>.h (for example ILA0.h)
int ila_output_data(char* buffer,int start, int end, int ila_dword_size); // Returns number of samples outputted, doesn't check buffer size (need to make sure that buffer can store everyting [see ila_output_data_size])

// Output everything to output (need to generate source from format file, otherwise linker error)
void ila_output_everything(int ila_dword_size);

// Returns Monitor base address based on ILA base address.
uint32_t ila_get_monitor_base_addr(int base_address);
