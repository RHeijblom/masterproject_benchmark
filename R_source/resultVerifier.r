#!/usr/bin/Rscript
.libPaths("/home/richard/Tools/R")
library(ggplot2)
library(plyr)
library(reshape2)
library(scales)
library(doMC)

# Make sure we use all available CPUs
doMC::registerDoMC(cores=8)

# Calculates how good the predictions given by the classifier are.

# Read file
# Args 1 = Path to file with test
# Args 2 = Path to file with results
# Args 3 = Path to file with performance data
args <- commandArgs(trailingOnly = TRUE)
#source("./statUtils.r")
testData <- read.csv(file=args[1], sep=',', quote="\"")
resultData <- read.csv(file=args[2], sep=',', quote="\"")
perfData <- read.csv(file=args[3], sep=',', quote="\"")

model <- c("filename","filetype")
strat <- c("order","saturation","sat.granularity")
mark <- "memMark"

# Add state.vector.length to result in order to fix sat.granularity later on
testData <- testData[,c(model, "state.vector.length")]
resultData <- merge(resultData, testData, model)
predictData <- resultData
predictData <- rename(predictData, c("predict.order"="order","predict.saturation"="saturation","predict.sat.granularity"="sat.granularity"))

# Extracts how many models were solved and the average mark for those models
metrics <- function(metricData){
	metricData$sat.granularity <- ifelse(is.na(metricData$state.vector.length) | is.na(metricData$sat.granularity) | metricData$state.vector.length > metricData$sat.granularity, metricData$sat.granularity, 2147483647)
	metricData <- merge(metricData, perfData, c(model, strat), all.x=TRUE)
	total <- nrow(metricData)
	#metricData$isSolved <- !is.na(metricData$solvedCount) & metricData$solvedCount > 0 # TIME
	metricData$isSolved <- !is.na(metricData$memMark) & metricData$solvedCount > 0 # PEAKSIZE
	metricData <- subset(metricData, isSolved)
	return(c(nrow(metricData), total, mean(metricData[,mark])))
}

# The metrics for the classifier
classifierResults = metrics(predictData)
results <- data.frame(order="dynamic",saturation="dynamic", sat.granularity="dynamic", solvedCount=classifierResults[1], total=classifierResults[2], avgMark=classifierResults[3])

# List of all strategies
allStrats = ddply(.parallel=TRUE, perfData, strat, summarize, dummy=TRUE)
allStrats = allStrats[,strat]

for(row in 1:nrow(allStrats)){
	# Fix all predictions to a specific strategy
	stratData <- predictData
	selectOrder <- allStrats$order[[row]]
	selectSat <- allStrats$saturation[[row]]
	selectGran <- allStrats$sat.granularity[[row]]
	stratData$order <- selectOrder
	stratData$saturation <- selectSat
	stratData$sat.granularity <- selectGran
	# Determine metrics for the fixed strategy
	stratResults <- metrics(stratData)
	dfr <- data.frame(order=paste(selectOrder), saturation=paste(selectSat), sat.granularity=paste(selectGran), solvedCount=stratResults[1], total=stratResults[2], avgMark=stratResults[3])
	# Storage results in data frame 'results'
	results <- rbind(results, dfr)
}

print(results)
	