//START_TABLE sw_reg
`SWREG_W(ILA_SOFTRESET, 1, 0)                              // Software reset
`SWREG_W(ILA_TRIGGER_TYPE, `ILA_MAX_TRIGGERS, 0)           // Single or continuous
`SWREG_W(ILA_TRIGGER_NEGATE, `ILA_MAX_TRIGGERS, 0)         // Software negate the trigger value
`SWREG_W(ILA_TRIGGER_MASK, `ILA_MAX_TRIGGERS, 0)           // Bitmask used to enable or disable individual triggers (1 enables the trigger, 0 disables)
`SWREG_W(ILA_DELAY_TRIGGER, 1, 0)                          // Delays the trigger by one cycle if asserted (allows sampling values one cycle after the triggers are asserted)
`SWREG_W(ILA_DELAY_SIGNAL, 1, 0)                           // Delays the signal by one cycle if asserted (allows sampling values one cycle before the triggers are asserted)
`SWREG_W(ILA_REDUCE_TYPE, 1, 0)                            // Reduces all the triggers into the final trigger using either a AND or OR condition
`SWREG_W(ILA_INDEX, `ILA_MAX_SAMPLES_W, 0)                 // Since it is a debug core and performance is not a priority, samples are accessed by first setting the index to read and then reading the value of ILA_DATA
`SWREG_W(ILA_SIGNAL_SELECT, `ILA_MAX_SIGNAL_SELECT_W,0)    // Signals bigger than DATA_W bits are partition into DATA_W parts, this selects which part to read 
`SWREG_W(ILA_SPECIAL_TRIGGER_MASK, 1, 0)                   // Special trigger mask
`SWREG_R(ILA_DATA, `ILA_RDATA_W, 0)                        // Value of the samples for the index set in ILA_INDEX and part set in ILA_SIGNAL_SELECT
`SWREG_R(ILA_SAMPLES, `ILA_MAX_SAMPLES_W, 0)               // Number of samples collected so far
`SWREG_R(ILA_CURRENT_DATA, `ILA_RDATA_W, 0)                // The current value of signal (not necessarily stored in the buffer) for the specific ILA_SIGNAL_SELECT (not affected by delay)
`SWREG_R(ILA_CURRENT_TRIGGERS, `ILA_MAX_TRIGGERS, 0)       // The current value of trigger (the value directly from the trigger signal, not affected by trigger type, negation or delay)
`SWREG_R(ILA_CURRENT_ACTIVE_TRIGGERS, `ILA_MAX_TRIGGERS,0) // This value is affected by negation and trigger type. For continuous triggers, returns if the trigger has been activated. For single triggers, returns whether the signal is currently asserted.