from ilaBase import Tokenize,ParseSignal,IsWire,IsTrigger,IsBuffer
import sys
import os

if(len(sys.argv) != 3):
	print "Need two arguments, format file and output folder path"
	sys.exit(0)

if not os.path.isdir(sys.argv[2]):
	print "Second argument must be filepath to a directory"
	sys.exit(0)

formatFile = open(sys.argv[1],"r")
formatData = ParseSignal(Tokenize(formatFile.read()))

verilogFile = open(os.path.join(sys.argv[2],"signal_inst.v"),"w")

signal_w = 0
trigger_w = 0
buffer_w = 12
for name,size in formatData:
	if IsWire(name):
		signal_w += size
	if IsTrigger(name):
		trigger_w += 1
	if IsBuffer(name):
		buffer_w = size

print(filter(lambda x : IsTrigger(x[0]),formatData))

if signal_w == 0:
	signal = "wire ila_signal;"
else:
	signal = "wire [%d:0] ila_signal = {" % (signal_w - 1)
	signal += ",".join(reversed(filter(IsWire,[x for x,y in formatData]))) # Extracts names 
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
verilogFile.write("\n")
verilogFile.write(signal)
verilogFile.write(trigger)
