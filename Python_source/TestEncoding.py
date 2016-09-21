import DataUtils as util

def checkEncoding(inputText, code, outputText):
	if inputText == outputText:
		print "OK -", inputText
	else:
		print "WRONG - input:", inputText, "- code:", code, "- output:", outputText 

# Test encoding of order
array = ["chain-prev","bfs","chain","bfs-prev"]
for order in array:
	code = util.encode_order(order)
	order2 = util.decode_order(code)
	checkEncoding(order, code, order2)
	
# Test encoding of saturation
array = ["sat-like","none","sat-loop"]
for sat in array:
	code = util.encode_sat(sat)
	sat2 = util.decode_sat(code)
	checkEncoding(sat, code, sat2)
	
# Test encoding of saturation granularity
array = ["40","1","20","2147483647","80","20","5",""]
for gran in array:
	code = util.encode_gran(gran)
	gran2 = util.decode_gran(code)
	checkEncoding(gran, code, gran2)