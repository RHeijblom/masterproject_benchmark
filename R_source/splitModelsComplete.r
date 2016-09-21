#!/usr/bin/Rscript
.libPaths("/home/richard/Tools/R")
library(plyr)
library(reshape2)
library(doMC)

# Make sure we use all available CPUs
doMC::registerDoMC(cores=8)

# Splits the training data into training and validation pairs 

# Args 1: Path to file with training data
# Args 2: Path to file with model data
# Args 3: Output directory
args <- commandArgs(trailingOnly = TRUE)
coupleData <- read.csv(file=args[1], sep=',', quote="\"")
modelData <- read.csv(file=args[2], sep=',', quote="\"")

# Refine coupleData by removing entries with missing data
coupleData <- subset(coupleData, !is.na(bandwidth) & 
					 			!is.na(profile) & 
					 			!is.na(span) & 
					 			!is.na(average.wavefront) & 
					 			!is.na(RMS.wavefront) & 
								!is.na(state.vector.length) &
								!is.na(groups) &
								!is.na(event.span) &
								!is.na(event.span.norm) &
								!is.na(weighted.event.span) &
								!is.na(weighted.event.span.norm))

parentModels <- ddply(.parallel=TRUE, modelData, "parent", summarize, train = TRUE);

print(paste("Unique models:", nrow(parentModels)))
print(paste("Total models:", nrow(coupleData)))

writeData <- function(dataTrain, dataVerify, number){
	# Print statistics
	print(paste("SET", number))
	print(paste("# Models in training set:", nrow(dataTrain)))
	print(paste("# Models in verify set:", nrow(dataVerify)))
	# Sort ascending on filename
	dataTrain <- dataTrain[order(dataTrain$filename),]
	dataVerify <- dataVerify[order(dataVerify$filename),]
	# Write to file
	write.table(dataTrain, paste0(file=args[3],"/Set-",number,"-train.csv"), sep=',', quote=TRUE ,row.names=FALSE,na="")
	write.table(dataVerify, paste0(file=args[3],"/Set-",number,"-validate.csv"), sep=',', quote=TRUE ,row.names=FALSE,na="")
}

# Set 1 Train: PNML - Verify: DVE
writeData(subset(coupleData, filetype == "pnml"), subset(coupleData, filetype == "dve2C"), 1)
# Set 2 Train: DVE - Verify: PNML
writeData(subset(coupleData, filetype == "dve2C"), subset(coupleData, filetype == "pnml"), 2)

# Set 3 - 5 Random 70% - 30% split
totalCol <- ncol(coupleData)
coupleData <- merge(coupleData, modelData, c("filename"))

for(set in 3:5){
	# Select 70% of models
	selectModels <- parentModels[sample(nrow(parentModels), (70*nrow(parentModels))/100), ]
	
	# Make split
	allModels <- merge(coupleData, selectModels, "parent", all.x=TRUE)

	trainModels <- subset(allModels, train)
	trainModels <- trainModels[,2:(totalCol+1)]
	
	
	validateModels <- subset(allModels, is.na(train))
	validateModels <- validateModels[,2:(totalCol+1)]
	
	# Save split
	writeData(trainModels, validateModels, set)
}
