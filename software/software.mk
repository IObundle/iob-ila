include $(ILA_DIR)/core.mk

#include
INCLUDE+=-I$(ILA_SW_DIR)

#headers
HDR+=$(ILA_SW_DIR)/iob-ila.h $(ILA_SW_DIR)/ILAsw_reg.h

$(ILA_SW_DIR)/ILAsw_reg.h: $(ILA_HW_DIR)/include/ILAsw_reg.v
	$(LIB_DIR)/software/mkregs.py $< SW
	mv $(CORE_NAME)sw_reg.h $@