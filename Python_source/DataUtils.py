import csv

class DataSet:
	def __init__(self, idList, featureList, labelList):
		self.id = idList
		self.features = featureList
		self.labels = labelList		

# Read dataset from .csv file
def read_dataset(file):
	ids = []
	features = []
	labels = []
	with open(file, 'rb') as csvfile:
		file_reader = csv.reader(csvfile, delimiter=',', quotechar='"')
		is_header = True
		for row in file_reader:
			if is_header:
				is_header = False
			else:
				ids.append(row[0:2])
				features.append(row[2:13])
				labels.append([encode_order(row[13]), encode_sat(row[14]), encode_gran(row[15])])
	return DataSet(ids, features, labels)

class ResultSet:
	def __init__(self, idList, predictList, actualList):
		self.id = idList
		self.predict = predictList
		self.actual = actualList
		
# Writes data to filesystem
def write_resultset(data, file):
	with open(file, 'w') as csvfile:
		file_writer = csv.writer(csvfile, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
		# Header
		file_writer.writerow(["filename", "filetype", "predict-order", "predict-saturation", "predict-sat-granularity", "actual-order", "actual-saturation", "actual-sat-granularity"])
		# Data
		ids = data.id
		predict = data.predict
		actual = data.actual
		for row in range(len(ids)):
			file_writer.writerow(ids[row]+ decode_all(predict[row]) + decode_all(actual[row]))

# Encodes order into real value
def encode_order(text):
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
def encode_sat(text):
	value = 0
	if text == "sat-like":
		value = 2
	elif text == "sat-loop":
		value = 3
	else: # assuming none
		value = 1
	return value
	
# Encodes sat.granularity into real value
def encode_gran(text):
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

# Translates a order,saturation,sat.granularity value triple to readable text
def decode_all(triple):
	return [decode_order(triple[0]), decode_sat(triple[1]), decode_gran(triple[2])]

# Translates the value for order into text
def decode_order(value):
	return decode_array(value, ["bfs","bfs-prev","chain","chain-prev"])

# Translates the value for saturation into text
def decode_sat(value):
	return decode_array(value, ["none","sat-like","sat-loop"])

# Translates the value for sat.granularity into text
def decode_gran(value):
	return decode_array(value, ["","1","5","10","20","40","80","2147483647"])

# Helper method
# Uses value to retrieve the item in array. Returns "Unknown" if value is a index outside the array
def decode_array(value, array):
	index = float_2_int(value)
	text = "Unknown"
	if index > 0 and index <= len(array):
		text = array[index-1]
	return text

# Helper method
# Converts float to integer
def float_2_int(value):
	return int(round(value))

# UNUSED
def zipArray(array2D):
	array = []
	for row in range(len(array2D)):
		entry = ""
		vals = array2D[row]
		for col in range(len(vals)):
			entry += vals[col] + " "
		array.append(entry[0:-1])
	return array
	
	