include $(ILA_DIR)/config.mk

MODULES+=ILA

#include
INCLUDE+=-I$(ILA_SW_DIR)

#headers
HDR+=$(ILA_SW_DIR)/ILAsw_reg.h

ILAsw_reg.h: $(ILA_HW_DIR)/include/ILAsw_reg.v
	$(LIB_DIR)/software/mkregs.py $< SW
