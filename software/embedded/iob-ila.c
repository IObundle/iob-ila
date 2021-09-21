#include "interconnect.h"
#include "iob-ila.h"
#include "../ILAsw_reg.h"
#include "iob-uart.h"
#include "printf.h"

// The values of the defines can be found in the beginning of ila_core.v
#define RST_SOFT_BIT        0
#define DIFF_SIGNAL_BIT     1
#define CIRCULAR_BUFFER_BIT 2
#define DELAY_TRIGGER_BIT   3
#define DELAY_SIGNAL_BIT    4
#define REDUCE_TYPE_BIT     5

//base address
static int base;

// The software module keeps track of the register values
static int triggerType;
static int triggerNegate;
static int triggerMask;
static int miscValue;

static void setTriggerType(int val){
    IO_SET(base,ILA_TRIGGER_TYPE,val);
}

static void setTriggerNegate(int val){
    IO_SET(base,ILA_TRIGGER_NEGATE,val);
}

static void setTriggerMask(int val){
    IO_SET(base,ILA_TRIGGER_MASK,val);
}

static void setMisc(int val){
    IO_SET(base,ILA_MISCELLANEOUS,val);
}

static inline int setBit(int bitfield,int bit,int value){
    value = (value ? 1 : 0);

    bitfield &= ~(1 << bit);    // Clear
    bitfield |= (value << bit); // Set to value

    return bitfield;
}

// Init the ila module
void ila_init(int base_address){
    base = base_address;

    triggerType = 0;
    triggerNegate = 0;
    triggerMask = 0;
    miscValue = 0;

    setTriggerType(triggerType);
    setTriggerNegate(triggerNegate);
    setTriggerMask(triggerMask);
    setMisc(miscValue);

    ila_set_time_offset(0);
    ila_set_reduce_type(ILA_REDUCE_TYPE_OR);

    ila_reset();
}

// Reset the ILA buffer
void ila_reset(){
    miscValue = setBit(miscValue,RST_SOFT_BIT,1);
    setMisc(miscValue);
    miscValue = setBit(miscValue,RST_SOFT_BIT,0);
    setMisc(miscValue);
    setTriggerType(triggerType);
    setTriggerMask(triggerMask);
    setTriggerNegate(triggerNegate);
}

// Set the trigger type
void ila_set_trigger_type(int trigger,int type){
    triggerType = setBit(triggerType,trigger,type);
    setTriggerType(triggerType);
}

// Enable or disable a particular trigger
void ila_set_trigger_enabled(int trigger,int enabled_bool){
    triggerMask = setBit(triggerMask,trigger,enabled_bool);
    setTriggerMask(triggerMask);
}

// Set whether the trigger is to be negated
void ila_set_trigger_negated(int trigger,int negate_bool){
    triggerNegate = setBit(triggerNegate,trigger,negate_bool);
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
        miscValue = setBit(miscValue,DELAY_TRIGGER_BIT,0);
        miscValue = setBit(miscValue,DELAY_SIGNAL_BIT,0);
    } else if(amount >= 1){
        miscValue = setBit(miscValue,DELAY_TRIGGER_BIT,1);
        miscValue = setBit(miscValue,DELAY_SIGNAL_BIT,0);
    } else {
        miscValue = setBit(miscValue,DELAY_TRIGGER_BIT,0);
        miscValue = setBit(miscValue,DELAY_SIGNAL_BIT,1);
    }
    setMisc(miscValue);
}

// Set the reduce type for multiple triggers 
void ila_set_reduce_type(int reduceType){
    miscValue = setBit(miscValue,REDUCE_TYPE_BIT,reduceType);
    setMisc(miscValue);
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
    miscValue = setBit(miscValue,DIFF_SIGNAL_BIT,enabled_bool);
    setMisc(miscValue);
}

void ila_print_current_configuration(){
    printf("Trigger Type:   %08x\n",triggerType);
    printf("Trigger Negate: %08x\n",triggerNegate);
    printf("Trigger Mask:   %08x\n",triggerMask);
    printf("Misc Value:     %08x\n\n",miscValue);
}