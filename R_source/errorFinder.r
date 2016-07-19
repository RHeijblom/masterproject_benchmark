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
print("Data loaded...")

staticFields <- c("filename","bandwidth","profile","span","average.wavefront","RMS.wavefront","state.vector.length","groups","statespace.states")

inputData <- ddply(.parallel=TRUE, inputData, staticFields, summarize, frequency = length(filename))

# Checklist per model if a certain value exist for a static column
dataPresence <- ddply(.parallel=TRUE, inputData, "filename", summarize, hasValBandwidth = !all(is.na(bandwidth)),
					  													hasValProfile = !all(is.na(profile)),
					  													hasValSpan = !all(is.na(span)),
																		hasValAvgwave = !all(is.na(average.wavefront)),
																		hasValRmswave = !all(is.na(RMS.wavefront)),
																		hasValVector = !all(is.na(state.vector.length)),
																		hasValGroups = !all(is.na(groups)),
																		hasValStates = !all(is.na(statespace.states)))
inputData <- merge(inputData, dataPresence, "filename")
print("Data summarized...")

# For all static columns: entry is redundant iff exists any value for a column (hasVal...), but value is NA for a model (filename)
inputData <- subset(inputData, !(is.na(bandwidth) & hasValBandwidth))
inputData <- subset(inputData, !(is.na(profile) & hasValProfile))
inputData <- subset(inputData, !(is.na(span) & hasValSpan))
inputData <- subset(inputData, !(is.na(average.wavefront) & hasValAvgwave))
inputData <- subset(inputData, !(is.na(RMS.wavefront) & hasValRmswave))
inputData <- subset(inputData, !(is.na(state.vector.length) & hasValVector))
inputData <- subset(inputData, !(is.na(groups) & hasValGroups))
inputData <- subset(inputData, !(is.na(statespace.states) & hasValStates))
print("Data filtered...")

# Unique (conflicting) entries per model
dataUnique <- ddply(.parallel=TRUE, inputData, "filename", summarize, uniqueCount = length(filename))

inputData <- merge(inputData, dataUnique, "filename")
#print(inputData[1:100,])
	  
# Only keep entries with a few states or conflicting entries
outputData <- subset(inputData, uniqueCount > 1 | statespace.states < 20)
print("Non conflicting entries removed...")

outputData <- subset(outputData, select=c("filename", staticFields, "frequency"))
# Prevent that large numbers are converted to Inf
outputData$statespace.states <- as.character(outputData$statespace.states)
# Order data
outputData <- outputData[order(outputData$filename),]
# Write compressed data
write.table(outputData, file=args[2], sep=',', quote=TRUE ,row.names=FALSE,na="")
