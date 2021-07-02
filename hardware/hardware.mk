include $(ILA_DIR)/core.mk

#SUBMODULE HARDWARE
#intercon
ifneq (INTERCON,$(filter INTERCON, $(SUBMODULES)))
SUBMODULES+=INTERCON
include $(INTERCON_DIR)/hardware/hardware.mk
endif

#lib
ifneq (LIB,$(filter LIB, $(SUBMODULES)))
SUBMODULES+=LIB
INCLUDE+=$(incdir) $(LIB_DIR)/hardware/include
VHDR+=$(wildcard $(LIB_DIR)/hardware/include/*.vh)
endif

#hardware include dirs
INCLUDE+=$(incdir) $(ILA_HW_DIR)/include

#ILA HARDWARE
#included files
VHDR+=$(wildcard $(ILA_HW_DIR)/include/*.vh)
VHDR+=$(ILA_HW_DIR)/include/ILAsw_reg_gen.v

#sources
VSRC+=$(ILA_HW_DIR)/src/ila_core.v $(ILA_HW_DIR)/src/iob_ila.v $(ILA_HW_DIR)/src/ila_trigger_logic.v

#mem
VSRC+=$(MEM_DIR)/2p_assim_async_mem/iob_2p_async_mem.v

#cpu accessible registers
$(ILA_HW_DIR)/include/ILAsw_reg_gen.v $(ILA_HW_DIR)/include/ILAsw_reg.vh: $(ILA_HW_DIR)/include/ILAsw_reg.v
	$(LIB_DIR)/software/mkregs.py $< HW
	mv ILAsw_reg_gen.v $(ILA_HW_DIR)/include
	mv ILAsw_reg.vh $(ILA_HW_DIR)/include

ila_clean_hw:
	@rm -rf $(ILA_HW_DIR)/include/ILAsw_reg_gen.v $(ILA_HW_DIR)/include/ILAsw_reg.vh tmp $(ILA_HW_DIR)/fpga/vivado/XCKU $(ILA_HW_DIR)/fpga/quartus/CYCLONEV-GT

.PHONY: ila_clean_hw

