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
		for matrix in self.sub:
			val += matrix.recall()
		return val / self.size
	
	def precisionMacro(self):
		val = 0.0
		for matrix in self.sub:
			val += matrix.precision()
		return val / self.size
	
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
		return (1.0*self.tp) / (self.tp + self.fn)
	
	def precision(self):
		return (1.0*self.tp) / (self.tp + self.fp)
	
	def accuracy(self):
		t = self.tp + self.tn + 0.0
		return t / (t + self.fp + self.fn)