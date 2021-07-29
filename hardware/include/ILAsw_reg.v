//START_TABLE sw_reg
`SWREG_W(ILA_MISCELLANEOUS, 32, 0)                         // Set of bits to enable different features. Includes softreset and others 
// Trigger configuration
`SWREG_W(ILA_TRIGGER_TYPE, `ILA_MAX_TRIGGERS, 0)           // Single or continuous
`SWREG_W(ILA_TRIGGER_NEGATE, `ILA_MAX_TRIGGERS, 0)         // Software negate the trigger value
`SWREG_W(ILA_TRIGGER_MASK, `ILA_MAX_TRIGGERS, 0)           // Bitmask used to enable or disable individual triggers (1 enables the trigger, 0 disables)
// Data selection (for reading)
`SWREG_W(ILA_INDEX, `ILA_MAX_SAMPLES_W, 0)                 // Since it is a debug core and performance is not a priority, samples are accessed by first setting the index to read and then reading the value of ILA_DATA
`SWREG_W(ILA_SIGNAL_SELECT, `ILA_MAX_SIGNAL_SELECT_W,0)    // Signals bigger than DATA_W bits are partition into DATA_W parts, this selects which part to read 
// Data reading
`SWREG_R(ILA_DATA, `ILA_RDATA_W, 0)                        // Value of the samples for the index set in ILA_INDEX and part set in ILA_SIGNAL_SELECT
`SWREG_R(ILA_SAMPLES, `ILA_MAX_SAMPLES_W, 0)               // Number of samples collected so far
`SWREG_R(ILA_CURRENT_DATA, `ILA_RDATA_W, 0)                // The current value of signal (not necessarily stored in the buffer) for the specific ILA_SIGNAL_SELECT (not affected by delay)
`SWREG_R(ILA_CURRENT_TRIGGERS, `ILA_MAX_TRIGGERS, 0)       // The current value of trigger (the value directly from the trigger signal, not affected by trigger type, negation or delay)
`SWREG_R(ILA_CURRENT_ACTIVE_TRIGGERS, `ILA_MAX_TRIGGERS,0) // This value is affected by negation and trigger type. For continuous triggers, returns if the trigger has been activated. For single triggers, returns whether the signal is currently asserted.
`SWREG_R(ILA_STATUS, 32, 0)                                // Contains information regarding the current state of the ILA