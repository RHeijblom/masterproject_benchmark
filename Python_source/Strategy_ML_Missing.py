# Prepare training data

directory = "/home/richard/Project/masterproject_benchmark/R_source/Models/Peaksize/"

import DataUtils
from sklearn import svm
import Metrics

def inboxLabels(labels):
		for row in range(len(labels)):
			labels[row] = 100*labels[row][0] + 10*labels[row][1] + labels[row][2]
		return labels
	
missingCount = 8

for setNo in range(3,6):
	setNo = str(setNo)
	# Import set setNo
	dataSet = DataUtils.read_dataset(directory +"Set-"+ setNo +"-train.csv")
	testSet = DataUtils.read_dataset(directory +"Set-"+ setNo +"-validate.csv")
	names = dataSet.names
	features = dataSet.features

	# Inbox labels
	labels = inboxLabels(dataSet.labels)
	testLabels = inboxLabels(testSet.labels)

	missingCombinations = DataUtils.nPrCombinations(range(len(names)), missingCount) 
	
	print "SET", setNo
	
	for missingColumns in missingCombinations:
		# Print omitted featus
		#for col in missingColumns:
		#	print names[col],
		#	print "\t",
		print DataUtils.removeMultipleRows(range(len(names)), missingColumns), "\t",
		
		# Cropped training and validation data
		cropFeatures = DataUtils.removeMultipleColumns(features, missingColumns)
		cropValidation = DataUtils.removeMultipleColumns(testSet.features, missingColumns)
		
		# Select classifier
		classifier = svm.SVC()
		# Train classifier
		classifier = classifier.fit(cropFeatures, labels)
		# Test classifier
		predictionsRaw = classifier.predict(cropValidation)

		# Outbox labels
		predictions = []
		for row in range(len(predictionsRaw)):
			# Convert float to int
			predictions.append(int(predictionsRaw[row]))

		# Metrics of classifier
		matrix_complete = Metrics.ConfusionMatrix(predictions, testLabels)

		# Simple printing
		Metrics.printConfusionMatrixCompact(matrix_complete)
		print ""
		
		#print cropFeatures[0]
