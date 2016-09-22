c = ["Cat"]
d = ["Dog"]
r = ["Rabbit"]

import Metrics
predict = 7*c + 8*d + 12*r 
actual = 5*c + 2*d + 3*c + 3*d + 2*r + d + 11*r
confMatrix = Metrics.ConfusionMatrix(predict, actual)

# Basic stats:
print "Matrix:"
print confMatrix.matrix
print "Groups:", confMatrix.index
print "Number of groups:", confMatrix.size
print "Number of tests:", confMatrix.quantity

# Advanced stats:
confMatrix.createSubMatrices()

print ""
print "Recall (macro)   :", confMatrix.recallMacro()
print "Precision (macro):", confMatrix.precisionMacro()
print "Accuracy (macro) :", confMatrix.accuracyMacro()
print "Accuracy (micro) :", confMatrix.accuracyMicro()