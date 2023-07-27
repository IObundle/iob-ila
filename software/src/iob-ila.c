#define IO_SET(base, location, value) (*((volatile int*) (base + (sizeof(int)) * location)) = value)
#define IO_GET(base, location)        (*((volatile int*) (base + (sizeof(int)) * location)))

#include "iob-ila.h"
#include "iob_ila_swreg.h"
#include "iob-uart.h"
#include "printf.h"

// The values of the defines can be found in the beginning of ila_core.v
#define RST_SOFT_BIT        0
#define DIFF_SIGNAL_BIT     1
#define CIRCULAR_BUFFER_BIT 2
#define DELAY_TRIGGER_BIT   3
#define DELAY_SIGNAL_BIT    4
#define REDUCE_TYPE_BIT     5

// The software module keeps track of the register values
static uint32_t triggerType;
static uint32_t triggerNegate;
static uint32_t triggerMask;
static uint32_t miscValue;

static inline int setBit(int bitfield,int bit,int value){
    value = (value ? 1 : 0);

    bitfield &= ~(1 << bit);    // Clear
    bitfield |= (value << bit); // Set to value

    return bitfield;
}

// Init the ila module
void ila_init(int base_address){
    IOB_ILA_INIT_BASEADDR(base_address);

    triggerType = 0;
    triggerNegate = 0;
    triggerMask = 0;
    miscValue = 0;

    IOB_ILA_SET_TRIGGER_TYPE(triggerType);
    IOB_ILA_SET_TRIGGER_NEGATE(triggerNegate);
    IOB_ILA_SET_TRIGGER_MASK(triggerMask);
    IOB_ILA_SET_MISCELLANEOUS(miscValue);

    ila_set_time_offset(0);
    ila_set_reduce_type(ILA_REDUCE_TYPE_OR);

    ila_reset();
}

// Reset the ILA buffer
void ila_reset(){
    miscValue = setBit(miscValue,RST_SOFT_BIT,1);
    IOB_ILA_SET_MISCELLANEOUS(miscValue);
    miscValue = setBit(miscValue,RST_SOFT_BIT,0);
    IOB_ILA_SET_MISCELLANEOUS(miscValue);
    IOB_ILA_SET_TRIGGER_TYPE(triggerType);
    IOB_ILA_SET_TRIGGER_MASK(triggerMask);
    IOB_ILA_SET_TRIGGER_NEGATE(triggerNegate);
}

// Set the trigger type
void ila_set_trigger_type(int trigger,int type){
    triggerType = setBit(triggerType,trigger,type);
    IOB_ILA_SET_TRIGGER_TYPE(triggerType);
}

// Enable or disable a particular trigger
void ila_set_trigger_enabled(int trigger,int enabled_bool){
    triggerMask = setBit(triggerMask,trigger,enabled_bool);
    IOB_ILA_SET_TRIGGER_MASK(triggerMask);
}

// Set whether the trigger is to be negated
void ila_set_trigger_negated(int trigger,int negate_bool){
    triggerNegate = setBit(triggerNegate,trigger,negate_bool);
    IOB_ILA_SET_TRIGGER_NEGATE(triggerNegate);
}

// Enables every trigger
void ila_enable_all_triggers(){
    triggerMask = 0xffffffff;
    IOB_ILA_SET_TRIGGER_MASK(triggerMask);
}

// Disable every trigger (equivalent to disabling ila)
void ila_disable_all_triggers(){
    triggerMask = 0x00000000;
    IOB_ILA_SET_TRIGGER_MASK(triggerMask);
}

void ila_set_time_offset(int amount){
    if(amount == 0){
        miscValue = setBit(miscValue,DELAY_TRIGGER_BIT,0);
        miscValue = setBit(miscValue,DELAY_SIGNAL_BIT,0);
    } else if(amount >= 1){
        miscValue = setBit(miscValue,DELAY_TRIGGER_BIT,1);
        miscValue = setBit(miscValue,DELAY_SIGNAL_BIT,0);
    } else {
        miscValue = setBit(miscValue,DELAY_TRIGGER_BIT,0);
        miscValue = setBit(miscValue,DELAY_SIGNAL_BIT,1);
    }
    IOB_ILA_SET_MISCELLANEOUS(miscValue);
}

// Set the reduce type for multiple triggers 
void ila_set_reduce_type(int reduceType){
    miscValue = setBit(miscValue,REDUCE_TYPE_BIT,reduceType);
    IOB_ILA_SET_MISCELLANEOUS(miscValue);
}

// If CIRCULAR_BUFFER=0: Returns the number of samples currently stored in the ila buffer
// If CIRCULAR_BUFFER=1: Returns the index of the last sample stored in the ila buffer
int ila_number_samples(){
    return IOB_ILA_GET_N_SAMPLES();
}

// Returns the value as a 32 bit of the sample at position index
int ila_get_value(int index){
    IOB_ILA_SET_SIGNAL_SELECT(0);
    IOB_ILA_SET_INDEX(index);
    return IOB_ILA_GET_SAMPLE_DATA();
}

uint32_t ila_get_large_value(int index,int partSelect){
    IOB_ILA_SET_SIGNAL_SELECT(partSelect);
    IOB_ILA_SET_INDEX(index);
    return IOB_ILA_GET_SAMPLE_DATA();
}


// Returns the value of the signal right now (does not mean it is stored in the buffer)
int ila_get_current_value(){
    IOB_ILA_SET_SIGNAL_SELECT(0);
    return IOB_ILA_GET_CURRENT_DATA();
}

// Returns 32 bits of the value of the signal right now
uint32_t ila_get_current_large_value(int partSelect){
    IOB_ILA_SET_SIGNAL_SELECT(partSelect);
    return IOB_ILA_GET_CURRENT_DATA();
}

// Returns the value of the trigger signal, directly (does not take into account negation or type)
int ila_get_current_triggers(){
    return IOB_ILA_GET_CURRENT_TRIGGERS();
}

// Returns the value of the triggers taking into account negation and type (For continuous triggers, the bit is asserted if the trigger has been activated)
int ila_get_current_active_triggers(){
    return IOB_ILA_GET_CURRENT_ACTIVE_TRIGGERS();
}

void ila_set_different_signal_storing(int enabled_bool){
    miscValue = setBit(miscValue,DIFF_SIGNAL_BIT,enabled_bool);
    IOB_ILA_SET_MISCELLANEOUS(miscValue);
}

void ila_print_current_configuration(){
    printf("Trigger Type:   %08x\n",triggerType);
    printf("Trigger Negate: %08x\n",triggerNegate);
    printf("Trigger Mask:   %08x\n",triggerMask);
    printf("Misc Value:     %08x\n\n",miscValue);
}

// Returns Monitor base address based on ILA base address.
// ila_init() must be called first.
// You can use the iob-pfsm drivers to control the ILA Monitor using its base address.
uint32_t ila_get_monitor_base_addr(int base_address){
    return base_address | 1<<(IOB_ILA_SWREG_ADDR_W-1);
}

// Enable/Disable circular buffer
void ila_set_circular_buffer(int value){
    miscValue = setBit(miscValue,CIRCULAR_BUFFER_BIT,value);
    IOB_ILA_SET_MISCELLANEOUS(miscValue);
}
