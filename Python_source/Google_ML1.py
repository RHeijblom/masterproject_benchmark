# Example from Google ML video 1
from sklearn import tree
# 1st feature is weight
# 2nd feature is texture; 0 = bumpy, 1 = smooth
features = [[140, 1], [130, 1], [150, 0], [170, 0]]
# 0 = apple, 1 = orange
labels = [0, 0, 1, 1] # Also works with multiple labels :D
clf = tree.DecisionTreeClassifier()
clf = clf.fit(features, labels)
print clf.predict([[160,0], [120,1]]) # Expected [1, 0]