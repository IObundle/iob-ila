include $(ILA_DIR)/config.mk

USE_NETLIST ?=0

#add itself to MODULES list
MODULES+=$(shell make -C $(ILA_DIR) corename | grep -v make)

#include submodule's hardware
$(foreach p, $(SUBMODULES), $(if $(filter $p, $(MODULES)),,$(eval include $($p_DIR)/hardware/hardware.mk)))

#ILA HARDWARE

#hardware include dirs
INCLUDE+=$(incdir)$(ILA_INC_DIR)

#included files
VHDR+=$(wildcard $(ILA_HW_DIR)/include/*.vh)
VHDR+=ILAsw_reg_gen.v ILAsw_reg.vh
VHDR+=$(ILA_INC_DIR)/ILAsw_reg.v 

#sources
VSRC+=$(ILA_HW_DIR)/src/ila_core.v $(ILA_HW_DIR)/src/iob_ila.v $(ILA_HW_DIR)/src/ila_trigger_logic.v

#mem
#VSRC+=$(MEM_DIR)/hardware/ram/t2p_ram/iob_t2p_ram.v

#cpu accessible registers
ILAsw_reg_gen.v ILAsw_reg.vh: $(ILA_INC_DIR)/ILAsw_reg.v
	$(LIB_DIR)/software/mkregs.py $< HW

ila_clean_hw:
	@rm -rf $(ILA_INC_DIR)/ILAsw_reg_gen.v \
	$(ILA_INC_DIR)/ILAsw_reg.vh tmp

.PHONY: ila_clean_hw

