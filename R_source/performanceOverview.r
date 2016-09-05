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

model <- c("filename","filetype")
testCase <- c("order","saturation","sat.granularity")

dataPerf <- subset(inputData, type == "performance" & (status == "done" | status == "ootime"))
dataPerf$isSolved <- dataPerf$status == "done"
# Penalty for runs with ootime
dataPerf$time <- ifelse(!dataPerf$isSolved, 1800, dataPerf$time)

# Summarize runs per model and testcase
dataOverview <- ddply(.parallel=TRUE, dataPerf, c(model, testCase), summarize, timeAvg = mean(time), timeSd = sd(time), solvedCount = sum(ifelse(isSolved,1,0)))

# Extract peaknodes
dataStat <- subset(inputData, type == "statistics")
dataStat <- subset(dataStat, select=c(model, testCase, "peak.nodes"))

# Merge performance summary with peaknodes
dataOverview <- merge(dataOverview, dataStat, c(model, testCase), all.x=TRUE)

# Determine best performance per model
dataBest <- ddply(.parallel=TRUE, dataOverview, model, summarize, timeBest = min(timeAvg, na.rm=TRUE), memBest = min(peak.nodes, na.rm=TRUE))
dataOverview <- merge(dataOverview, dataBest, model, all.x=TRUE)

print(dataOverview[1:5,])

# Determine marks for time and peaknodes
dataOverview$timeMark <- dataOverview$timeAvg/dataOverview$timeBest
dataOverview$memMark <- dataOverview$peak.nodes/dataOverview$memBest
				   
# Write output to file
outputData <- dataOverview
# Order data
outputData <- outputData[order(outputData$filename),]
# Write compressed data
write.table(outputData, file=args[2], sep=',', quote=TRUE ,row.names=FALSE,na="")

				   