#!/usr/bin/Rscript
.libPaths("/home/richard/Tools/R")
library(ggplot2)
library(plyr)
library(reshape2)
library(scales)
library(doMC)

# Make sure we use all available CPUs
doMC::registerDoMC(cores=8)

# Creates the input-output couples for training

# Read file
args <- commandArgs(trailingOnly = TRUE)
#source("./statUtils.r")
perfData <- read.csv(file=args[1], sep=',', quote="\"")

model <- c("filename","filetype")

print(paste("Unique Modelcheck 1:", nrow(ddply(.parallel=TRUE, perfData, model, summarize, count = length("filename")))))

# Main Objective: minimize peaksize
memData <- ddply(.parallel=TRUE, perfData, model, summarize, minMemMark = ifelse(all(is.na(memMark)),NA,min(memMark, na.rm=TRUE)))
perfData <- merge(perfData, memData, model, all.x=TRUE)
perfData <- subset(perfData, is.na(minMemMark) | memMark == minMemMark)

print(paste("Unique Modelcheck 2:", nrow(ddply(.parallel=TRUE, perfData, model, summarize, count = length("filename")))))

# 1st tie breaker: faster is better
timeData <- ddply(.parallel=TRUE, perfData, model, summarize, minTimeMark = min(timeMark))
perfData <- merge(perfData, timeData, model, all.x=TRUE)
perfData <- subset(perfData, is.na(minTimeMark) | timeMark == minTimeMark)

print(paste("Unique Modelcheck 3:", nrow(ddply(.parallel=TRUE, perfData, model, summarize, count = length("filename")))))

# 2nd tie breaker: more models solved is better
solvedData <- ddply(.parallel=TRUE, perfData, model, summarize, maxSolvedCount = max(solvedCount))
perfData <- merge(perfData, solvedData, model, all.x=TRUE)
perfData <- subset(perfData, solvedCount == maxSolvedCount)

print(paste("Unique Modelcheck 4:", nrow(ddply(.parallel=TRUE, perfData, model, summarize, count = length("filename")))))

# 3rd tie breaker: small standard deviation is slightly better; time mark is probably more accurate
sdData <- ddply(.parallel=TRUE, perfData, model, summarize, minSd = min(timeSd))
perfData <- merge(perfData, sdData, model, all.x=TRUE)
perfData <- subset(perfData, timeSd == minSd)

print(paste("Unique Modelcheck 5:", nrow(ddply(.parallel=TRUE, perfData, model, summarize, count = length("filename")))))

# Check whether each models has a unique entry
multiOptionData <- ddply(.parallel=TRUE, perfData, model, summarize, count = length(filename))
multiOptionData <- subset(multiOptionData, count > 1)
print("The following models contain multiple best strategies:")
print(multiOptionData)

outputData <- perfData
# Order data
outputData <- outputData[order(outputData$filename),]
# Write compressed data
write.table(outputData, file=args[2], sep=',', quote=TRUE ,row.names=FALSE,na="")