NON_TOKEN = 0
TOKEN = 1

TRIGGER = "$trigger"
BUFFER = "$buffer"

def TokenChar(char):
	res = (('a' <= char <= 'z') or ('A' <= char <= 'Z') or ('0' <= char <= '9') or char in ['_','.'])
	return res

def Tokenize(text):
	if len(text) == 0:
		return []

	state = (TOKEN if TokenChar(text[0]) else NON_TOKEN)
	tokenIndex = 0
	index = 0
	tokens = []
	
	while index < len(text):
		if state: # TOKEN state
			if not TokenChar(text[index]):
				tokens.append(text[tokenIndex:index])
				state = NON_TOKEN
		else: # NON_TOKEN state
			if TokenChar(text[index]):
				tokenIndex = index
				state = TOKEN
		
		# Consume single line comments 
		if(text[index] == '/' and text[index+1] == '/'):
			while(text[index] != '\n'):
				index += 1

		# Consume multi line comments
		if(text[index] == '/' and text[index+1] == '*'):
			while not (text[index-1] == '*' and text[index] == '/'):
				index += 1

		if(text[index] == '$'):
			# Consume TRIGGER
			if(text[index:index + len(TRIGGER)] == TRIGGER):
				index += len(TRIGGER)
				tokens.append(TRIGGER)

				start = index
				while index < len(text) and text[index] != '\n':
					index += 1

				line = text[start:index].strip()

				tokens.append(line)
			
			# Consume BUFFER
			if(text[index:index + len(BUFFER)] == BUFFER):
				index += len(BUFFER)
				tokens.append(BUFFER)

		index += 1

	if(state == TOKEN):
		tokens.append(text[tokenIndex:index])

	return tokens

def IsWire(token):
	res = (token[0] != '$')

	return res

def IsTokenSpecial(token):
	res = (token[0] == '$')

	return res

def IsTrigger(token):
	res = (token == TRIGGER)

	return  res

def IsBuffer(token):
	res = (token == BUFFER)

	return res

def ParseSignal(tokens):
	parsed = []
	for i in range(len(tokens) // 2):
		left,right = tokens[i*2:i*2+2]

		if(IsWire(left) or IsBuffer(left)):
			right = int(right)

		parsed.append([left,right])

	return parsed