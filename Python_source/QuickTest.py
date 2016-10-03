import DataUtils

print DataUtils.removeMultipleRows(range(9), [1,3,5])
print DataUtils.removeMultipleRows(range(9), [0,1,8])
print DataUtils.removeMultipleRows(range(9), [4,5,6,7])

matrix = [range(5), range(5,10), range(10,15), range(15,20)]

print DataUtils.removeMultipleColumns(matrix, [0,4])
print DataUtils.removeMultipleColumns(matrix, [3])
print DataUtils.removeMultipleColumns(matrix, [1,2,3])
print DataUtils.removeMultipleColumns(matrix, [0,2,4])