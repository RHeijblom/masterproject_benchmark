#!/usr/bin/Rscript
.libPaths("/home/richard/Tools/R")
library(plyr)
library(reshape2)
library(doMC)

# Make sure we use all available CPUs
doMC::registerDoMC(cores=8)

# Read file
args <- commandArgs(trailingOnly = TRUE)
inputData <- read.csv(file=args[1], sep=',', quote="\"")

parentModels <- ddply(.parallel=TRUE, inputData, "parent", summarize, train = TRUE);

print(paste("Unique models:", nrow(parentModels)))
print(paste("Total models:", nrow(inputData)))

for(set in 1:3){
	# Select 70% of models
	selectModels <- parentModels[sample(nrow(parentModels), (70*nrow(parentModels))/100), ]
	
	# Make split
	allModels <- merge(inputData, selectModels, "parent", all.x=TRUE)
	
	trainModels <- subset(allModels, train)
	trainModels <- subset(trainModels, select="filename")
	print(paste("Train models:", nrow(trainModels)))
	
	validateModels <- subset(allModels, is.na(train))
	validateModels <- subset(validateModels, select="filename")
	print(paste("Validate models:", nrow(validateModels)))
	
	# Write split
	write.table(trainModels, paste0("./set", set, "_train.csv"), sep=',', quote=TRUE ,row.names=FALSE,na="")
	write.table(validateModels, paste0("./set", set, "_validate.csv"), sep=',', quote=TRUE ,row.names=FALSE,na="")
}
	



	  
	  