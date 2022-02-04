ILA_DIR:=.
include config.mk

.PHONY: corename \
	sim sim-test sim-clean \
	vcd genVerilog genSource \
	fpga-build fpga-build-all fpga-test fpga-clean fpga-clean-all \
	doc-build doc-build-all doc-test doc-clean doc-clean-all \
	clean-all

corename:
	@echo "ILA"

#
# SIMULATE
#

sim:
	make -C $(SIM_DIR) run

sim-test:
	make -C $(SIM_DIR) test

sim-clean:
	make -C $(SIM_DIR) clean-all

#
# VCD GENERATION
#

vcd: dataOut.vcd
	gtkwave dataOut.vcd

dataOut.vcd: format.txt dataIn.txt
	python $(ILA_PYTHON_DIR)/ilaDataToVCD.py format.txt dataIn.txt dataOut.vcd

genVerilog: format.txt
	python $(ILA_PYTHON_DIR)/ilaGenerateVerilog.py format.txt ./

genSource: format.txt
	python $(ILA_PYTHON_DIR)/ilaGenerateSource.py format.txt ./source.c

#
# FPGA COMPILE
#

fpga-build:
	make -C $(FPGA_DIR) build

fpga-build-all:
	$(foreach s, $(FPGA_FAMILY_LIST), make fpga-build FPGA_FAMILY=$s;)

fpga-test:
	make -C $(FPGA_DIR) test

fpga-clean:
	make -C $(FPGA_DIR) clean-all

fpga-clean-all:
	$(foreach s, $(FPGA_FAMILY_LIST), make fpga-clean FPGA_FAMILY=$s;)

#
# DOCUMENT
#

doc-build: fpga-build-all
	make -C $(DOC_DIR) all

doc-build-all:
	$(foreach s, $(DOC_LIST), make doc-build DOC=$s;)

doc-test:
	make -C $(DOC_DIR) test

doc-clean:
	make -C $(DOC_DIR) clean

doc-clean-all:
	$(foreach s, $(DOC_LIST), make doc-clean DOC=$s;)

#
# CLEAN ALL
# 

clean-all: sim-clean fpga-clean-all doc-clean-all