# Example from Google ML video 1
from sklearn import tree
# 1st feature is weight
# 2nd feature is texture; 0 = bumpy, 1 = smooth, 2 = odd
features = [[140, 1], [130, 1], [120, 0], [150, 0], [180, 0], [160, 0], [160, 2], [170, 2]]
# 1st label is fruit; 0 = apple, 1 = orange
# 2nd label is isEdible; 0 = False, 1 = True
labels = [[0,1], [0,1], [0,0], [0,0], [1,1], [1,1], [1,0], [1,0]] # Also works with multiple labels :D
clf = tree.DecisionTreeClassifier()
clf = clf.fit(features, labels)
predicts = clf.predict([[170,0], [120,1], [140,0], [180,2]]) # Expected [ [1,1], [0,1], [0,0], [1,0]]
print predicts
print "1,1:", predicts[1][1]