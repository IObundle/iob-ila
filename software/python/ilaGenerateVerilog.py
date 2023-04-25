#!/usr/bin/env python3

from ilaBase import Tokenize,ParseSignal,IsWire,IsTrigger,IsBuffer
import sys
import os

if(len(sys.argv) != 3):
	print("Need two arguments, format file and output folder path")
	sys.exit(0)

if not os.path.isdir(sys.argv[2]):
	print("Second argument must be filepath to a directory")
	sys.exit(0)

formatFile = open(sys.argv[1],"r")
formatData = ParseSignal(Tokenize(formatFile.read()))

verilogFile = open(os.path.join(sys.argv[2],"signal_inst.vh"),"w")

sizeList = []
signal_w = 0
trigger_w = 0
buffer_w = 12
for name,size in formatData:
	if IsWire(name):
		signal_w += size
		sizeList.append(size)
	if IsTrigger(name):
		trigger_w += 1
	if IsBuffer(name):
		buffer_w = size

if(signal_w == 0 or buffer_w == 0):
	verilogFile.write("// Auto generated file\n")
	verilogFile.write("`define ILA_SIGNAL_W 1\n")
	verilogFile.write("`define ILA_TRIGGER_W 1\n")
	verilogFile.write("`define ILA_BUFFER_W 1\n\n")
	verilogFile.write("wire ila_signal = 1'b0;\n")
	verilogFile.write("wire ila_trigger = 1'b0;")
else:
	sizeList = list(set(sizeList))

	functionDef = ""

	for size in sizeList:
		functionDef += "function [%d:0] ila_trunc_%d(input [%d:0] val);\n" % (size-1,size,size-1)
		functionDef += "    ila_trunc_%d = (%d'h0 | val);\n" % (size,size)
		functionDef += "endfunction\n"

	if signal_w == 0:
		signal = "wire ila_signal;"
	else:
		signal = "wire [%d:0] ila_signal = {" % (signal_w - 1)
		signal += ",".join(reversed(list(map(lambda x : "ila_trunc_%d" % int(x[1]) + "(" + x[0] + ")",filter(lambda x : IsWire(x[0]),formatData))))) # Extracts names 
		signal += "};\n"

	if trigger_w == 0:
		trigger = "wire ila_trigger;"
	else:
		trigger = "wire [%d:0] ila_trigger = {" % (trigger_w - 1)
		trigger += ",".join(reversed([y for x,y in filter(lambda x : IsTrigger(x[0]),formatData)])) # Extracts the expression for each $trigger
		trigger += "};\n"

	verilogFile.write("// Auto generated file\n")
	verilogFile.write("`define ILA_SIGNAL_W %d\n" % signal_w)
	verilogFile.write("`define ILA_TRIGGER_W %d\n" % trigger_w)
	verilogFile.write("`define ILA_BUFFER_W %d\n" % buffer_w)
	verilogFile.write("`define USE_ILA 1\n")
	verilogFile.write("\n")
	verilogFile.write(functionDef)
	verilogFile.write("\n")
	verilogFile.write(signal)
	verilogFile.write(trigger)
