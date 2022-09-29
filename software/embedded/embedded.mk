include $(ILA_DIR)/software/software.mk

#embeded sources
SRC+=$(ILA_SW_DIR)/embedded/iob-ila.c iob_ila_swreg_emb.c

iob_ila_swreg_emb.c: iob_ila_swreg.h
