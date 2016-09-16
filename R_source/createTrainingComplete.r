#!/usr/bin/Rscript
.libPaths("/home/richard/Tools/R")
library(ggplot2)
library(plyr)
library(reshape2)
library(scales)
library(doMC)

# Make sure we use all available CPUs
doMC::registerDoMC(cores=8)

# Merges three files to create the complete training input-output couples
# Args 1 = Path to file with dependency matrix statistics (input)
# Args 2 = Path to file with event span statistics (input)
# Args 3 = Path to file with best strategy per solvable model (output)
# Args 4 = Path to file where the results are saved
args <- commandArgs(trailingOnly = TRUE)

# Columns groups
model <- c("filename","filetype")
strategy <- c("order","saturation","sat.granularity")

mergeVector <- function(vector){
	return(ifelse(all(is.na(vector)), NA, min(vector, na.rm=TRUE)))
}

outputData <- read.csv(file=args[3], sep=',', quote="\"")
outputData <- outputData[,c(model,strategy)]

# Pick unique models which can be solved.
trainingData <- ddply(.parallel=TRUE, outputData, model, summarize, dummy = TRUE)
trainingData <- trainingData[,1:length(model)]

# Summarize dependency matrix statistics
depMatrixData <- read.csv(file=args[1], sep=',', quote="\"")
depMatrixData <- ddply(.parallel=TRUE, depMatrixData, model, summarize, 
					   bandwidth = mergeVector(bandwidth),
					   profile = mergeVector(profile),
					   span = mergeVector(span),
					   average.wavefront = mergeVector(average.wavefront),
					   RMS.wavefront = mergeVector(RMS.wavefront),
					   state.vector.length = mergeVector(state.vector.length),
					   groups = mergeVector(groups))
trainingData <- merge(trainingData, depMatrixData, model, all.x=TRUE)

# Add event span statistics
eventData <- read.csv(file=args[2], sep=',', quote="\"")
trainingData <- merge(trainingData, eventData, model, all.x=TRUE)

# Add best strategy for each model
trainingData <- merge(trainingData, outputData, model, all.x=TRUE)

# Save results
outputData <- trainingData
# Order data
outputData <- outputData[order(outputData$filename),]
# Write compressed data
write.table(outputData, file=args[4], sep=',', quote=TRUE ,row.names=FALSE,na="")