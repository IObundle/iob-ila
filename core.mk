#
# CORE DEFINITIONS FILE
#

CORE_NAME:=ILA
IS_CORE:=1
USE_NETLIST ?=0

#ILA PATHS
ILA_HW_DIR:=$(ILA_DIR)/hardware
ILA_SW_DIR:=$(ILA_DIR)/software
ILA_DOC_DIR:=$(ILA_DIR)/document
ILA_SUBMODULES_DIR:=$(ILA_DIR)/submodules

#SUBMODULES
ILA_SUBMODULES:=INTERCON LIB TEX
$(foreach p, $(ILA_SUBMODULES), $(eval $p_DIR ?=$(ILA_SUBMODULES_DIR)/$p))

#host where this is running
HOSTNAME=$(shell hostname)

#
#SIMULATION
#
SIM_DIR ?=$(ILA_HW_DIR)/simulation

#
#FPGA
#
FPGA_HOST=$(shell echo $(FPGA_SERVER) | cut -d"." -f1)
FPGA_FAMILY ?=CYCLONEV-GT
#FPGA_FAMILY ?=XCKU

#FPGA_SERVER :=localhost
REMOTE_ROOT_DIR ?= sandbox/iob-soc/submodules/ILA
FPGA_SERVER ?=pudim-flan.iobundle.com
FPGA_USER ?= $(USER)

ifeq ($(FPGA_FAMILY),XCKU)
	FPGA_COMP:=vivado
	FPGA_PART:=xcku040-fbva676-1-c
else
	FPGA_COMP:=quartus
	FPGA_PART:=5CGTFD9E5F35C7
endif
FPGA_DIR ?=$(ILA_HW_DIR)/fpga/$(FPGA_COMP)

ifeq ($(FPGA_COMP),vivado)
FPGA_LOG:=vivado.log
else ifeq ($(FPGA_COMP),quartus)
FPGA_LOG:=quartus.log
endif

#
#DOCUMENT
#
DOC_TYPE:=pb
#DOC_TYPE:=ug
INTEL ?=1
INT_FAMILY ?=CYCLONEV-GT
XILINX ?=1
XIL_FAMILY ?=XCKU
VERSION= 0.1
VLINE:="V$(VERSION)"
$(CORE_NAME)_version.txt:
ifeq ($(VERSION),)
	$(error "variable VERSION is not set")
endif
	echo $(VLINE) > version.txt
