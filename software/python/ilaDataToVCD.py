from ilaBase import Tokenize,ParseSignal,IsWire
import sys

if(len(sys.argv) != 4):
	print "Need three arguments, format file, data input file name and output file name"
	sys.exit(0)

dataFile = open(sys.argv[2],"rb")

dataIn = [x.strip() for x in dataFile.readlines()]
dataIn = [x for x in dataIn if x != ''] # Remove empty lines

formatFile = open(sys.argv[1],"r")
formatData = ParseSignal(Tokenize(formatFile.read()))

# Easier to work in strings
def HexToBin(hexStr):
	mapping = {'0':"0000",'1':"0001",'2':"0010",'3':"0011",
			   '4':"0100",'5':"0101",'6':"0110",'7':"0111",
			   '8':"1000",'9':"1001",'A':"1010",'B':"1011",
			   'C':"1100",'D':"1101",'E':"1110",'F':"1111"}

	res = ""
	for ch in hexStr:
		res += mapping[ch.upper()]

	return res

def GenerateId():
	symbols = "!#$%&()*+,-.:;<=>?@GHIJKLMNOPQRSTUVWXYZghijklmnopqrstuvwxyz" # Only use this symbols, its simpler

	res = ""
	if(GenerateId.index < len(symbols)):
		res = symbols[GenerateId.index]
	else:
		first = GenerateId.index % len(symbols)
		second = GenerateId.index // len(symbols)
		res = symbols[second - 1] + symbols[first]

	GenerateId.index += 1
	return res
GenerateId.index = 0

nameToVarMapping = {}
for name,_ in formatData:
	if IsWire(name):
		nameToVarMapping.update({name:GenerateId()})

valueChanges = []
for data in dataIn:
	binRep = HexToBin(data)
	values = []

	for name,size in formatData:
		if IsWire(name):
			binary = binRep[-size:]
			values.append([nameToVarMapping[name],binary])
			binRep = binRep[:-size]

	valueChanges.append(values)

def InsideHieararchy(top,val):
	if(len(top) > len(val)):
		return False

	for x,y in zip(top[:-1],val[:-1]):
		if(x != y):
			return False

	return True

orderedNames = []

for name,size in formatData:
	if IsWire(name):
		last = 0
		for i,val in enumerate(orderedNames):
			if InsideHieararchy(val[0].split("."),name.split(".")):
				last = i + 1

		orderedNames.insert(last,[name,size])

outputFile = open(sys.argv[3],"w")

currentHierarchyIndex = 0
for name,size in orderedNames:
	hierarchy = name.split(".")
	
	while len(hierarchy) > currentHierarchyIndex + 1:
		outputFile.write("$scope module %s $end\n" % hierarchy[currentHierarchyIndex])
		currentHierarchyIndex += 1

	while len(hierarchy) < currentHierarchyIndex + 1:
		outputFile.write("$upscope $end\n")
		currentHierarchyIndex -= 1

	outputFile.write("$var wire %d %s %s $end\n" % (size,nameToVarMapping[name],hierarchy[-1],))

while currentHierarchyIndex >= 1:
	outputFile.write("$upscope $end\n")
	currentHierarchyIndex -= 1

# Start everything at zero
outputFile.write("$dumpvars\n")

for name,size in formatData:
	if IsWire(name):
		if size == 1:
			outputFile.write("0%s\n" % nameToVarMapping[name])
		else:
			outputFile.write("b%s %s\n" % ("0" * size,nameToVarMapping[name]))

outputFile.write("$end\n")

for i in range(len(valueChanges)):
	outputFile.write("#%d\n" % (i*2+2))
	
	values = valueChanges[i]

	for var,binary in values:
		if len(binary) == 1:
			outputFile.write("%s%s\n" % (binary,var))
		else:
			outputFile.write("b%s %s\n" % (binary,var))

outputFile.write("#%d\n" % ((len(valueChanges)+1) * 2))

outputFile.close()
