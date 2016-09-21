# Encodes order into real value
def encodeOrder(text):
	value = 0
	if text == "bfs":
		value = 1
	elif text == "bfs-prev":
		value = 2
	elif text == "chain":
		value = 3
	else: # assuming chain-prev
		value = 4
	return value
	
# Encodes saturation into real value
def encodeSat(text):
	value = 0
	if text == "sat-like":
		value = 2
	elif text == "sat-loop":
		value = 3
	else: # assuming none
		value = 1
	return value
	
# Encodes sat.granularity into real value
def encodeGran(text):
	value = 0
	if text == "1":
		value = 2
	elif text == "5":
		value = 3
	elif text == "10":
		value = 4
	elif text == "20":
		value = 5
	elif text == "40":
		value = 6
	elif text == "80":
		value = 7
	elif text == "2147483647":
		value = 8
	else: # assuming none
		value = 1
	return value

# Translates the value for order into text
def decodeOrder(value):
	return decodeFromArray(value, ["bfs","bfs-prev","chain","chain-prev"])

# Translates the value for saturation into text
def decodeSat(value):
	return decodeFromArray(value, ["none","sat-like","sat-loop"])

# Translates the value for sat.granularity into text
def decodeGran(value):
	return decodeFromArray(value, ["","1","5","10","20","40","80","2147483647"])

# Helper method
# Uses value to retrieve the item in array. Returns "Unknown" if value is a index outside the array
def decodeFromArray(value, array):
	index = decodeIndex(value)
	text = "Unknown"
	if index > 0 and index <= len(array):
		text = array[index-1]
	return text

# Helper method
# Converts float to integer
def decodeIndex(value):
	return int(round(value))