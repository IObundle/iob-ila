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

// Init the ila module
void ila_init(int base_address,int numberTriggers){
    base = base_address;
    numberTriggers = numberTriggers;

    triggerType =   0x00000000;
    triggerNegate = 0x00000000;
    triggerMask =   0x00000000;

    setTriggerType(triggerType);
    setTriggerNegate(triggerNegate);
    setTriggerMask(triggerMask);

    ila_reset();
}

// Reset the ILA buffer
void ila_reset(){
    IO_SET(base,ILA_SOFTRESET,1);
    IO_SET(base,ILA_SOFTRESET,0); 
}

// Set the trigger type
void ila_trigger_type(int trigger,int type){
    type = (type ? 0x1 : 0x0);
    
    triggerType &= ~(1 << trigger);   // Clear
    triggerType |= (type << trigger); // Set type

    setTriggerType(triggerType);
}

// Enable or disable a particular trigger
void ila_set_enabled_trigger(int trigger,int enabled_bool){
    int enabledInt = (enabled_bool ? 0x1 : 0x0);

    triggerMask &= ~(1 << trigger);         // Clear
    triggerMask |= (enabledInt << trigger); // Set enabled

    setTriggerMask(triggerMask);
}

// Set whether the trigger is to be negated
void ila_set_negate_trigger(int trigger,int negate_bool){
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

// Set whether the trigger is delayed by one cycle
void ila_set_delay_trigger(int delay_bool){
    IO_SET(base,ILA_DELAY_TRIGGER,(delay_bool ? 0x1 : 0x0));
}

// Set whether the signal is delayed by one cycle
void ila_set_delay_signal(int delay_bool){
    IO_SET(base,ILA_DELAY_SIGNAL,(delay_bool ? 0x1 : 0x0));
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

void ila_print_current_configuration(){
    printf("Number Triggers:%d\n\n",numberTriggers);
    printf("Trigger Type:   %08x\n",triggerType);
    printf("Trigger Negate: %08x\n",triggerNegate);
    printf("Trigger Mask:   %08x\n\n",triggerMask);
}