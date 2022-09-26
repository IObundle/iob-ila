include $(ILA_DIR)/config.mk

MODULES+=ILA

#include
INCLUDE+=-I$(ILA_SW_DIR)

#headers
HDR+=$(ILA_SW_DIR)/*.h iob_ila_swreg.h

iob_ila_swreg.h: $(ILA_DIR)/mkregs.conf
	$(LIB_DIR)/software/python/mkregs.py iob_ila $(ILA_DIR) SW $(ILA_INC_DIR)/iob_ila.vh