# Prepare training data

directory = "/home/richard/Project/masterproject_benchmark/R_source/Models/Time/"
setNo = "3"

import DataUtils
dataSet = DataUtils.read_dataset(directory +"Set-"+ setNo +"-train.csv")
features = dataSet.features
labels = dataSet.labels

# Select classifier
from sklearn.tree import DecisionTreeClassifier
classifier = DecisionTreeClassifier()

# Train classifier
classifier = classifier.fit(features, labels)

# Test classifier
testSet = DataUtils.read_dataset(directory +"Set-"+ setNo +"-validate.csv")
predictions = classifier.predict(testSet.features)

results = DataUtils.ResultSet(testSet.id, predictions, testSet.labels)
DataUtils.write_resultset(results, directory +"Result-"+ setNo +".csv")