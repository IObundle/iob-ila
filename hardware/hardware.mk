include $(ILA_DIR)/config.mk

USE_NETLIST ?=0

#ILA HARDWARE

#hardware include dirs
INCLUDE+=$(incdir)$(ILA_INC_DIR)

#included files
VHDR+=$(wildcard $(ILA_HW_DIR)/include/*.vh)
VHDR+=iob_ila_swreg_gen.vh iob_ila_swreg_def.vh

#sources
VSRC+=$(ILA_HW_DIR)/src/ila_core.v $(ILA_HW_DIR)/src/iob_ila.v $(ILA_HW_DIR)/src/ila_trigger_logic.v

#mem
VSRC+=$(MEM_DIR)/hardware/ram/iob_ram_t2p/iob_ram_t2p.v

#cpu accessible registers
iob_ila_swreg_gen.vh iob_ila_swreg_def.vh: $(ILA_DIR)/mkregs.conf
	$(LIB_DIR)/software/python/mkregs.py iob_ila $(ILA_DIR) HW

ila_clean_hw:
	@rm -rf iob_ila_swreg_gen.vh iob_ila_swreg_def.vh

.PHONY: ila_clean_hw

