import sys

if(len(sys.argv) != 4):
	print "Need three arguments, format file, data input file name and output file name"
	sys.exit(0)

formatFile = open(sys.argv[1],"r")
dataFile = open(sys.argv[2],"rb")

dataIn = dataFile.read()

formatData = [x.strip().split(" ") for x in formatFile.readlines()]
print(formatData)