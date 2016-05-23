# Example from Google ML video 2
import numpy as np
from sklearn.datasets import load_iris
from sklearn import tree

iris = load_iris()
test_idx = [0,50,100]

# Training data
train_target = np.delete(iris.target, test_idx)
train_data = np.delete(iris.data, test_idx, axis=0)

# Testing data
test_target = iris.target[test_idx]
test_data = iris.data[test_idx]

# Build classifier
clf = tree.DecisionTreeClassifier()
clf = clf.fit(train_data, train_target)

# Test classifier
print test_target
print clf.predict(test_data)