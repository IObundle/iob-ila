#include "interconnect.h"
#include "iob-ila.h"
#include "../ILAsw_reg.h"
#include "iob-uart.h"
#include "printf.h"

//base address
static int base;

// The software module keeps track of the register values
static int triggerType;
static int triggerNegate;
static int triggerMask;

static int specialTriggerMask;

static int numberTriggers;

static void setTriggerType(int val){
    IO_SET(base,ILA_TRIGGER_TYPE,val);
}

static void setTriggerNegate(int val){
    IO_SET(base,ILA_TRIGGER_NEGATE,val);
}

static void setTriggerMask(int val){
    IO_SET(base,ILA_TRIGGER_MASK,val);
}

static void setSpecialTriggerMask(int val){
    IO_SET(base,ILA_SPECIAL_TRIGGER_MASK,val);
}

// Init the ila module
void ila_init(int base_address,int nTriggers){
    base = base_address;
    numberTriggers = nTriggers;

    ila_reset();

    triggerType = 0;
    triggerNegate = 0;
    triggerMask = 0;
    specialTriggerMask = 0;

    setTriggerType(triggerType);
    setTriggerNegate(triggerNegate);
    setTriggerMask(triggerMask);
    setSpecialTriggerMask(specialTriggerMask);

    ila_set_time_offset(0);
    ila_set_reduce_type(ILA_REDUCE_TYPE_OR);
}

// Reset the ILA buffer
void ila_reset(){
    IO_SET(base,ILA_SOFTRESET,1);
    IO_SET(base,ILA_SOFTRESET,0); 
}

// Set the trigger type
void ila_set_trigger_type(int trigger,int type){
    type = (type ? 0x1 : 0x0);
    
    triggerType &= ~(1 << trigger);   // Clear
    triggerType |= (type << trigger); // Set type

    setTriggerType(triggerType);
}

// Enable or disable a particular trigger
void ila_set_trigger_enabled(int trigger,int enabled_bool){
    int enabledInt = (enabled_bool ? 0x1 : 0x0);

    triggerMask &= ~(1 << trigger);         // Clear
    triggerMask |= (enabledInt << trigger); // Set enabled

    setTriggerMask(triggerMask);
}

// Set whether the trigger is to be negated
void ila_set_trigger_negated(int trigger,int negate_bool){
    int negateInt = (negate_bool ? 0x1 : 0x0);

    triggerNegate &= ~(1 << trigger);        // Clear
    triggerNegate |= (negateInt << trigger); // Set negate

    setTriggerNegate(triggerNegate);
}

// Enables every trigger
void ila_enable_all_triggers(){
    triggerMask = 0xffffffff;
    setTriggerMask(triggerMask);
}

// Disable every trigger (equivalent to disabling ila)
void ila_disable_all_triggers(){
    triggerMask = 0x00000000;
    setTriggerMask(triggerMask);
}


void ila_set_time_offset(int amount){
    if(amount == 0){
        IO_SET(base, ILA_DELAY_TRIGGER, 0);
        IO_SET(base, ILA_DELAY_SIGNAL,  0);
    } else if(amount >= 1){
        IO_SET(base, ILA_DELAY_TRIGGER, 1);
        IO_SET(base, ILA_DELAY_SIGNAL,  0);
    } else {
        IO_SET(base, ILA_DELAY_TRIGGER, 0);
        IO_SET(base, ILA_DELAY_SIGNAL,  1);
    }
}

// Set the reduce type for multiple triggers 
void ila_set_reduce_type(int reduceType){
    reduceType &= 0x1;
    IO_SET(base,ILA_REDUCE_TYPE,reduceType);
}

// Returns the number of samples currently stored in the ila buffer
int ila_number_samples(){
    return IO_GET(base,ILA_SAMPLES);
}

// Returns the value as a 32 bit of the sample at position index
int ila_get_value(int index){
    IO_SET(base,ILA_SIGNAL_SELECT,0);
    IO_SET(base,ILA_INDEX,index);
    return IO_GET(base,ILA_DATA);
}

int ila_get_large_value(int index,int partSelect){
    IO_SET(base,ILA_SIGNAL_SELECT,partSelect);
    IO_SET(base,ILA_INDEX,index);
    return IO_GET(base,ILA_DATA);
}


// Returns the value of the signal right now (does not mean it is stored in the buffer)
int ila_get_current_value(){
    IO_SET(base,ILA_SIGNAL_SELECT,0);
    return IO_GET(base,ILA_CURRENT_DATA);
}

// Returns 32 bits of the value of the signal right now
int ila_get_current_large_value(int partSelect){
    IO_SET(base,ILA_SIGNAL_SELECT,partSelect);
    return IO_GET(base,ILA_CURRENT_DATA);
}

// Returns the value of the trigger signal, directly (does not take into account negation or type)
int ila_get_current_triggers(){
    return IO_GET(base,ILA_CURRENT_TRIGGERS);
}

// Returns the value of the triggers taking into account negation and type (For continuous triggers, the bit is asserted if the trigger has been activated)
int ila_get_current_active_triggers(){
    return IO_GET(base,ILA_CURRENT_ACTIVE_TRIGGERS);
}

void ila_set_different_signal_storing(int enabled_bool){
    int enabledInt = (enabled_bool ? 0x1 : 0x0);

    specialTriggerMask &= ~(1 << 0);         // Clear
    specialTriggerMask |= (enabledInt << 0); // Set

    setSpecialTriggerMask(specialTriggerMask);
}

void ila_print_current_configuration(){
    printf("Number Triggers:%d\n\n",numberTriggers);
    printf("Trigger Type:   %08x\n",triggerType);
    printf("Trigger Negate: %08x\n",triggerNegate);
    printf("Trigger Mask:   %08x\n",triggerMask);
    printf("Special Trigger Mask: %08x\n\n",specialTriggerMask);
}