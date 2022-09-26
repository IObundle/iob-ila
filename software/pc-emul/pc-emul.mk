#ila common parameters
include $(ILA_DIR)/software/software.mk

#pc sources
SRC+=$(ILA_SW_DIR)/pc-emul/iob-ila.c iob_ila_swreg_emb.c

iob_ila_swreg_emb.c: iob_ila_swreg.h
