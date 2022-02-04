from ilaBase import Tokenize,ParseSignal,IsWire,IsTrigger,IsBuffer
import sys

if(len(sys.argv) != 3):
	print "Need two arguments, format file and output file path"
	sys.exit(0)

formatFile = open(sys.argv[1],"r")
formatData = ParseSignal(Tokenize(formatFile.read()))

sourceFile = open(sys.argv[2],"w")

signal_w = 0
trigger_w = 0
buffer_w = 8
for name,size in formatData:
	if IsWire(name):
		signal_w += size
	if IsTrigger(name):
		trigger_w += 1
	if IsBuffer(name):
		buffer_w = size

def BitSize(val,nBits):
	res = ((val - 1) // nBits) + 1

	return res

text  = "// Auto generated file\n"
text += "#define ILA_SIGNAL_W %d\n" % signal_w
text += "#define ILA_DWORD_SIZE %d\n" % BitSize(signal_w,32)
text += "#define ILA_BYTE_SIZE %d\n" % BitSize(signal_w,8)
text += "#define ILA_TRIGGER_W %d\n" % trigger_w
text += "#define ILA_BUFFER_SIZE %d\n\n" % (2 ** buffer_w)

text += '#include "ila_static_generate.c"\n'

sourceFile.write(text)
