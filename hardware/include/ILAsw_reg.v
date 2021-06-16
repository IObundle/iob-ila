//START_TABLE sw_reg
`SWREG_W(ILA_SOFTRESET, 1, 0)                           // Software reset
`SWREG_W(ILA_TRIGGER_TYPE, `ILA_MAX_TRIGGERS, 0)        // Single or continuous
`SWREG_W(ILA_TRIGGER_NEGATE, `ILA_MAX_TRIGGERS, 0)      // Trigger on 1 or on 0
`SWREG_W(ILA_TRIGGER_MASK, `ILA_MAX_TRIGGERS, 0)        // Mask used to enable or disable individual triggers (1 enables the trigger, 0 disables)
`SWREG_W(ILA_DELAY_TRIGGER, 1, 0)                       // Delays the trigger by one cycle if asserted
`SWREG_W(ILA_DELAY_SIGNAL, 1, 0)                        // Delays the signal by one cycle if asserted
`SWREG_W(ILA_REDUCE_TYPE, 1, 0)                         // Reduces all the triggers into the final trigger using either AND or OR
`SWREG_W(ILA_INDEX, `ILA_MAX_SAMPLES_W, 0)              // Since it is a debug core, samples are accessed by first setting the index and then reading the value of ILA_DATA
`SWREG_W(ILA_SIGNAL_SELECT, `ILA_MAX_SIGNAL_SELECT_W,0) // Signals bigger than DATA_W bits are partition into DATA_W parts, this selects which part to read 
`SWREG_R(ILA_DATA, `ILA_RDATA_W, 0)                     // Value of the samples for the index set in ILA_INDEX
`SWREG_R(ILA_SAMPLES, `ILA_MAX_SAMPLES_W, 0)            // Number of samples collected so far