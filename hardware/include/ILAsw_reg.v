//START_TABLE sw_reg
`SWREG_W(ILA_SOFTRESET, 1, 0)
`SWREG_W(ILA_ENABLED, 1, `ILA_START_ENABLED)
`SWREG_W(ILA_INDEX, `ILA_MAX_SAMPLES_W, 0) // Since it is a debug core, samples are accessed by first setting the index and then reading the value of ILA_DATA
`SWREG_R(ILA_SAMPLES, `ILA_MAX_SAMPLES_W, 0)
`SWREG_R(ILA_DATA, `ILA_RDATA_W, 0)