ILA_DIR:=../..
incdir:=-I
defmacro:=-D
include $(ILA_DIR)/hardware/hardware.mk

DEFINE+=$(defmacro)VCD

VSRC+=$(ILA_DIR)/hardware/testbench/ila_tb.v

#icarus verilog simulator
VLOG:=iverilog -W all -g2005-sv

run: a.out
	./$<

a.out: $(VSRC) $(VHDR)
	$(VLOG) $(INCLUDE) $(DEFINE) $(VSRC)

clean: ila_clean_hw
	@rm -f a.out *~ *.vcd

.PHONY: all clean

