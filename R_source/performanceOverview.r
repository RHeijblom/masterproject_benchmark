#!/usr/bin/Rscript
.libPaths("/home/richard/Tools/R")
library(plyr)
library(reshape2)
library(doMC)

# Make sure we use all available CPUs
doMC::registerDoMC(cores=8)

# This file summarizes the performance data of refinedResults.csv. It compresses the results into one entry per model and testcase.
# Furthermore the best time and smallest peaksize will be determined for all models. This data is used to assign marks for performance for
# all entries. It is possible that no mark will be given for peaksize, because all runs for that model did not manage to record these values.

# Read file
args <- commandArgs(trailingOnly = TRUE)
inputData <- read.csv(file=args[1], sep=',', quote="\"")

model <- c("filename","filetype")
testCase <- c("order","saturation","sat.granularity")

# Sat.granularity fix
colCount <- ncol(inputData)
# Identifier of max granularity
MAXINT <- 2147483647 
# Derive state_vector_length for models with at least one solved instance, otherwise set derivedSvl to NA.
mapSvl <- ddply(.parallel=TRUE, inputData, model, summarize, derivedSvl = mean(state.vector.length, na.rm=TRUE))
# Add derived state.vector.length to data
inputData <- merge(inputData, mapSvl, model)
# Fix cases where sat.granularity is too high; may change testcases for a specific granularity to a multiple of 10 
inputData$sat.granularity <- ifelse(!is.na(inputData$derivedSvl) & inputData$sat.granularity >= inputData$derivedSvl, MAXINT, inputData$sat.granularity)
# Remove derived svl
inputData <- inputData[,1:colCount]

# Determine performance data
dataPerf <- subset(inputData, type == "performance" & (status == "done" | status == "ootime"))
dataPerf$isSolved <- dataPerf$status == "done"
# Penalty for runs with ootime
dataPerf$time <- ifelse(dataPerf$isSolved, dataPerf$time, 1800)

# Summarize runs per model and testcase
dataOverview <- ddply(.parallel=TRUE, dataPerf, c(model, testCase), summarize, timeAvg = mean(time), timeSd = sd(time), solvedCount = sum(ifelse(isSolved,1,0)))

# Extract peaknodes
dataStat <- subset(inputData, type == "statistics")
dataStat <- ddply(.parallel=TRUE, dataStat, c(model, testCase), summarize, peak.nodes= ifelse(all(is.na(peak.nodes)),NA, min(peak.nodes, na.rm=TRUE)))

# Merge performance summary with peaknodes
dataOverview <- merge(dataOverview, dataStat, c(model, testCase), all.x=TRUE)

# Fix values for peaknodes; if there are no solved models the peaknodes value cannot be used (only affects one entry for lamport_fmea-5)
dataOverview$peak.nodes <- ifelse(dataOverview$solvedCount > 0, dataOverview$peak.nodes, NA)

# Determine best performance per model
dataBest <- ddply(.parallel=TRUE, dataOverview, model, summarize, timeBest = min(timeAvg, na.rm=TRUE), memBest = ifelse(all(is.na(peak.nodes)), NA, min(peak.nodes, na.rm=TRUE)))
dataOverview <- merge(dataOverview, dataBest, model, all.x=TRUE)

# Determine marks for time and peaknodes
dataOverview$timeMark <- dataOverview$timeAvg/dataOverview$timeBest
dataOverview$memMark <- dataOverview$peak.nodes/dataOverview$memBest
				   
# Write output to file
outputData <- dataOverview
# Order data
outputData <- outputData[order(outputData$filename),]
# Write compressed data
write.table(outputData, file=args[2], sep=',', quote=TRUE ,row.names=FALSE,na="")

				   