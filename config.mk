TOP_MODULE=iob_ila

#ILA PATHS
REMOTE_ROOT_DIR ?= sandbox/iob-soc/submodules/ILA
ILA_HW_DIR:=$(ILA_DIR)/hardware
ILA_INC_DIR:=$(ILA_HW_DIR)/include
ILA_SW_DIR:=$(ILA_DIR)/software
ILA_PYTHON_DIR:=$(ILA_SW_DIR)/python
ILA_DOC_DIR:=$(ILA_DIR)/document
ILA_SUBMODULES_DIR:=$(ILA_DIR)/submodules
ILA_SIM_DIR ?=$(ILA_HW_DIR)/simulation
SIM_DIR ?=$(ILA_SIM_DIR)
FPGA_DIR ?=$(shell find $(ILA_DIR)/hardware -name $(FPGA_FAMILY))
DOC_DIR ?=$(ILA_DIR)/document/$(DOC)
SUBMODULES_DIR:=$(ILA_DIR)/submodules

# SUBMODULE PATHS
SUBMODULES=
SUBMODULE_DIRS=$(shell ls $(SUBMODULES_DIR))
#$(foreach d, $(SUBMODULE_DIRS), $(eval TMP=$(shell make -C $(SUBMODULES_DIR)/$d corename | grep -v make)) $(eval SUBMODULES+=$(TMP)) $(eval $(TMP)_DIR ?=$(SUBMODULES_DIR)/$d))

#DEFAULT FPGA FAMILY
FPGA_FAMILY ?=CYCLONEV-GT
FPGA_FAMILY_LIST ?=CYCLONEV-GT XCKU

#DEFAULT DOC
DOC ?=pb
DOC_LIST ?=pb ug

# VERSION
VERSION ?=0.1
VLINE ?="V$(VERSION)"
ILA_version.txt:
ifeq ($(VERSION),)
	$(error "variable VERSION is not set")
endif
	echo $(VLINE) > version.txt