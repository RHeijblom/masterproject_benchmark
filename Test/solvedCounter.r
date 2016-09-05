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

print(paste("Different models:",nrow(ddply(.parallel=TRUE, inputData, "filename", summarize, freq = length(filename)))))

nCols <- ncol(inputData)
# Defines which testrun were solved
inputData$isSolved <- inputData$status == "done" & inputData$type == "performance"
# Defines which models can be solved
solvedData <- ddply(.parallel=TRUE, inputData, "filename", summarize, solvedCount = sum(ifelse(isSolved, 1, 0)), isSolvable = any(isSolved))
solvedData <- subset(solvedData, !isSolvable)
print(solvedData)
