#!/usr/bin/env python3

from ilaBase import Tokenize,ParseSignal,IsWire,IsTrigger
import sys


def BitSize(val,nBits):
	res = ((val - 1) // nBits) + 1
	return res

def generate_driver_source(ila_instance_name, formatData, sourceFilename):
	sourceFile = open(sourceFilename,"w")
	signal_w = 0
	#trigger_w = 0
	for name,size in formatData:
		if IsWire(name):
			signal_w += size
		#if IsTrigger(name):
		#	trigger_w += 1

	text  = "// Auto generated file\n"
	#text += f"#define {ila_instance_name.upper()}_SIGNAL_W {signal_w}\n"
	text += f"#define {ila_instance_name.upper()}_DWORD_SIZE {BitSize(signal_w,32)}\n"
	text += f"#define {ila_instance_name.upper()}_BYTE_SIZE {BitSize(signal_w,8)}\n"
	#text += f"#define {ila_instance_name.upper()}_TRIGGER_W {trigger_w}\n"
	text += f"#define {ila_instance_name.upper()}_BUFFER_SIZE (2 ** {ila_instance_name.upper()}_BUFFER_W)\n\n"

	text += '#include "ila_static_generate.c"\n'

	sourceFile.write(text)

if __name__ == "__main__":
	if(len(sys.argv) != 3):
		print("Need two arguments, format file and output file path")
		sys.exit(0)

	formatFile = open(sys.argv[1],"r")
	formatData = ParseSignal(Tokenize(formatFile.read()))

	generate_driver_source("ila",formatData,sys.argv[2])
