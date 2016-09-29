# Prepare training data

directory = "/home/richard/Project/masterproject_benchmark/R_source/Models/Time/"
setNo = "5"

import DataUtils
dataSet = DataUtils.read_dataset(directory +"Set-"+ setNo +"-train.csv")
features = dataSet.features

def inboxLabels(labels):
	for row in range(len(labels)):
		labels[row] = 100*labels[row][0] + 10*labels[row][1] + labels[row][2]
	return labels

# Inbox labels
labels = inboxLabels(dataSet.labels)

# Select classifier
from sklearn import tree
from sklearn import neighbors
from sklearn import naive_bayes
from sklearn import svm
from sklearn import linear_model
#classifier = tree.DecisionTreeClassifier()
#classifier = neighbors.KNeighborsClassifier()
#classifier = neighbors.RadiusNeighborsClassifier(radius=100000000.0)
#classifier = naive_bayes.GaussianNB()
#classifier = naive_bayes.MultinomialNB()
#classifier = naive_bayes.BernoulliNB()
#classifier = svm.LinearSVC()
classifier = svm.SVC()
#classifier = svm.SVC(kernel="sigmoid", decision_function_shape="ovr")
#classifier = svm.NuSVC()
#classifier = linear_model.SGDClassifier()

# Train classifier
classifier = classifier.fit(features, labels)

# Test classifier
testSet = DataUtils.read_dataset(directory +"Set-"+ setNo +"-validate.csv")
predictionsRaw = classifier.predict(testSet.features)

# Outbox labels
predictions = []
predictionsExpl = []
for row in range(len(predictionsRaw)):
	# Convert float to int
	predictions.append(int(predictionsRaw[row]))
	# Splice int into 3 values
	order = predictions[row]/100
	sat = (predictions[row]/10)%10
	gran = predictions[row]%10
	predictionsExpl.append([order, sat, gran])

# Write results to csv file
results = DataUtils.ResultSet(testSet.id, predictionsExpl, testSet.labels)
DataUtils.write_resultset(results, directory +"Result-"+ setNo +".csv")

# Metrics of classifier
import Metrics
matrix_complete = Metrics.ConfusionMatrix(predictions, inboxLabels(testSet.labels))
	
# Readable printing
#Metrics.printConfusionMatrix("COMPLETE", matrix_complete)
# Simple printing
Metrics.printConfusionMatrixCompact(matrix_complete)
print ""
