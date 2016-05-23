# Example from Google ML video 4
from sklearn.datasets import load_iris
iris = load_iris()

# Analogy f(x) = y
x = iris.data
y = iris.target

# Split data in training and testing set
from sklearn.cross_validation import train_test_split
x_train, x_test, y_train, y_test = train_test_split(x, y, test_size = .33)


# Classifier selection
#from sklearn.tree import DecisionTreeClassifier
#clf = DecisionTreeClassifier()
from sklearn.neighbors import KNeighborsClassifier
clf = KNeighborsClassifier()

# Train classifier
clf = clf.fit(x_train, y_train)

# Test classifier
predictions = clf.predict(x_test)

# Evaluate behavior of classifier
from sklearn.metrics import accuracy_score
print accuracy_score(y_test, predictions)