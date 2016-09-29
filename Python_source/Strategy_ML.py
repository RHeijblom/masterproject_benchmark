# Prepare training data

directory = "/home/richard/Project/masterproject_benchmark/R_source/Models/Time/"
setNo = "2"

import DataUtils
dataSet = DataUtils.read_dataset(directory +"Set-"+ setNo +"-train.csv")
features = dataSet.features
labels = dataSet.labels

# Select classifier
from sklearn import tree
from sklearn import neighbors
#classifier = tree.DecisionTreeClassifier()
classifier = neighbors.KNeighborsClassifier(n_neighbors=6, weights="uniform")
#classifier = neighbors.RadiusNeighborsClassifier(radius=100000000.0)

# Train classifier
classifier = classifier.fit(features, labels)

# Test classifier
testSet = DataUtils.read_dataset(directory +"Set-"+ setNo +"-validate.csv")
predictions = classifier.predict(testSet.features)

# Write results to csv file
results = DataUtils.ResultSet(testSet.id, predictions, testSet.labels)
DataUtils.write_resultset(results, directory +"Result-"+ setNo +".csv")

dim = len(predictions[0])

# Determine metrics based on confusion matrix
predict_complete = []
actual_complete = []
predict_single = []
actual_single = []
for index in range(dim):
	predict_single.append([])
	actual_single.append([])

# Inboxing
for index in range(len(predictions)):
	p = predictions[index]
	a = testSet.labels[index]
	str_p = ""
	str_a = ""
	for col in range(dim):
		p_single = int(p[col])
		a_single = int(a[col])
		str_p += str(p_single) + " "
		str_a += str(a_single) + " "
		predict_single[col].append(p_single)
		actual_single[col].append(a_single)
	str_p = str_p[0:-1]
	str_a = str_a[0:-1]
	predict_complete.append(str_p)
	actual_complete.append(str_a)

import Metrics
matrix_complete = Metrics.ConfusionMatrix(predict_complete, actual_complete)
matrix_single = []

for col in range(dim):
	matrix_single.append(Metrics.ConfusionMatrix(predict_single[col], actual_single[col]))
	
# Hardcoded for better formatting
#Metrics.printConfusionMatrix("COMPLETE", matrix_complete)
#Metrics.printConfusionMatrix("EXPLORATION ORDER", matrix_single[0])
#Metrics.printConfusionMatrix("SATURATION STRATEGY", matrix_single[1])
#Metrics.printConfusionMatrix("SATURATION GRANULARITY", matrix_single[2])

# Simple printing
Metrics.printConfusionMatrixCompact(matrix_complete)
for col in range(dim):
	Metrics.printConfusionMatrixCompact(matrix_single[col])
print ""
