class ConfusionMatrix:
	def __init__(self, predicted, actual):
		self.index = list(set(predicted + actual))
		self.size = len(self.index)
		self.matrix = [[0 for x in range(self.size)] for y in range(self.size)]
		for p,a in zip(predicted, actual):
			self.matrix[self.index.index(p)][self.index.index(a)] += 1
		self.quantity = len(predicted)
		self.sub = []
		
	def createSubMatrices(self):
		self.sub = []
		for group in range(self.size):
			tp = self.matrix[group][group]
			fp = sum(self.matrix[group]) - tp
			fn = -tp
			for predicted in range(self.size):
				fn += self.matrix[predicted][group]
			tn = self.quantity - tp - fp - fn
			self.sub.append(ConfusionMatrix2D(tp, fp, fn, tn))
			
	def recallMacro(self):
		val = 0.0
		n = self.size
		result = "NaN"
		for matrix in self.sub:
			recall = matrix.recall()
			if recall != "NaN":
				val += recall
			else:
				n -= 1
		if n > 0:
			result = val /n
		return result
	
	def precisionMacro(self):
		val = 0.0
		n = self.size
		result = "NaN"
		for matrix in self.sub:
			precision = matrix.precision()
			if precision != "NaN":
				val += precision
			else:
				n -= 1
		if n > 0:
			result = val / n
		return result
	
	def accuracyMacro(self):
		val = 0.0
		for matrix in self.sub:
			val += matrix.accuracy()
		return val / self.size
	
	def accuracyMicro(self):
		val = 0.0
		for group in range(self.size):
			val += self.matrix[group][group]
		return val / self.quantity
	
class ConfusionMatrix2D:
	def __init__(self, true_pos, false_pos, false_neg, true_neg):
		self.tp = true_pos
		self.fp = false_pos
		self.fn = false_neg
		self.tn = true_neg
		
	def recall(self):
		result = "NaN"
		denom = self.tp + self.fn
		if denom > 0:
			result = (1.0*self.tp) / denom
		return result
	
	def precision(self):
		result = "NaN"
		denom = self.tp + self.fp
		if denom > 0:
			result = (1.0*self.tp) / denom
		return result
	
	def accuracy(self):
		t = self.tp + self.tn + 0.0
		return t / (t + self.fp + self.fn)

# Print function for matrix statistics
def printConfusionMatrix(header, matrix):
	# Basic stats:
	print header+":"
	print ""
	# print matrix.matrix
	print "Groups:", matrix.index
	print "Number of groups:", matrix.size
	print "Number of tests:", matrix.quantity
	# Advanced stats:
	matrix.createSubMatrices()
	print ""
	print "Recall (macro)   :", matrix.recallMacro()
	print "Precision (macro):", matrix.precisionMacro()
	print "Accuracy (macro) :", matrix.accuracyMacro()
	print "Accuracy (micro) :", matrix.accuracyMicro()
	print ""
	
# Print function for matrix statistics (one liner for easy ctrl+C, ctrl+V)
def printConfusionMatrixCompact(matrix):
	matrix.createSubMatrices()
	print matrix.recallMacro(),
	print "\t",
	print matrix.precisionMacro(),
	print "\t",
	print matrix.accuracyMacro(),
	print "\t",
	print matrix.accuracyMicro(),
	print "\t",