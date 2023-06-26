#!/usr/bin/env python3

from ilaBase import Tokenize,ParseSignal,IsWire,IsTrigger
import sys
import os


def generate_verilog_snippet(formatData, out_dir):
	verilogFile = open(os.path.join(out_dir,"signal_inst.vs"),"w")
	verilog_source_code = generate_verilog_source("ila",formatData)
	verilogFile.write(verilog_source_code)
	verilogFile.close()


def generate_verilog_source(ila_instance_name,formatData):
	verilog_code = ""
	sizeList = []
	signal_w = 0
	trigger_w = 0
	for name,size in formatData:
		if IsWire(name):
			signal_w += size
			sizeList.append(size)
		if IsTrigger(name):
			trigger_w += 1

	sizeList = list(set(sizeList))

	functionDef = ""

	for size in sizeList:
		functionDef += f"function [{size-1}:0] {ila_instance_name}_trunc_{size}(input [{size-1}:0] val);\n"
		functionDef += f"    {ila_instance_name}_trunc_{size} = ({size}'h0 | val);\n"
		functionDef += "endfunction\n"

	if signal_w == 0:
		signal = f"assign {ila_instance_name}_signal = 1'b0;"
	else:
		signal = f"assign {ila_instance_name}_signal = {{"
		signal += ",".join(reversed(list(map(lambda x : f"{ila_instance_name}_trunc_{str(x[1]) + '(' + x[0] + ')'}",filter(lambda x : IsWire(x[0]),formatData))))) # Extracts names 
		signal += "};\n"

	if trigger_w == 0:
		trigger = f"assign {ila_instance_name}_trigger = 1'b0;"
	else:
		trigger = f"assign {ila_instance_name}_trigger = {{"
		trigger += ",".join(reversed([y for x,y in filter(lambda x : IsTrigger(x[0]),formatData)])) # Extracts the expression for each $trigger
		trigger += "};\n"

	verilog_code += functionDef
	verilog_code += "\n"
	verilog_code += signal
	verilog_code += trigger

	return verilog_code

if __name__ == "__main__":
	if(len(sys.argv) != 3):
		print("Need two arguments, format file and output folder path")
		sys.exit(0)

	if not os.path.isdir(sys.argv[2]):
		print("Second argument must be filepath to a directory")
		sys.exit(0)

	formatFile = open(sys.argv[1],"r")
	formatData = ParseSignal(Tokenize(formatFile.read()))

	generate_verilog_snippet(formatData,sys.argv[2])
