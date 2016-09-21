import DataUtils as util

def checkEncoding(inputText, code, outputText):
	if inputText == outputText:
		print "OK -", inputText
	else:
		print "WRONG - input:", inputText, "- code:", code, "- output:", outputText 

# Test encoding of order
array = ["chain-prev","bfs","chain","bfs-prev"]
for order in array:
	code = util.encodeOrder(order)
	order2 = util.decodeOrder(code)
	checkEncoding(order, code, order2)
	
# Test encoding of saturation
array = ["sat-like","none","sat-loop"]
for sat in array:
	code = util.encodeSat(sat)
	sat2 = util.decodeSat(code)
	checkEncoding(sat, code, sat2)
	
# Test encoding of saturation granularity
array = ["40","1","20","2147483647","80","20","5",""]
for gran in array:
	code = util.encodeGran(gran)
	gran2 = util.decodeGran(code)
	checkEncoding(gran, code, gran2)