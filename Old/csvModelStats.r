#!/usr/bin/Rscript
.libPaths("/home/richard/Tools/R")
library(plyr)
library(reshape2)
library(doMC)

# Make sure we use all available CPUs
doMC::registerDoMC(cores=8)

# HELPER FUNCTIONS

# Read input from csv
args <- commandArgs(trailingOnly = TRUE)
inputData <- read.csv(file=args[1], sep=',', quote="\"")

# Compress data
outputData <- ddply(.parallel=TRUE, inputData, c("filename","PT.places","PT.transitions","PT.arcs","PT.safeplaces",
												 "state.vector.length","groups","statespace.states","statespace.nodes",
												 "group.next","group.explored.nodes","group.explored.vectors","max.tokens",
												 "bandwidth","profile","span","average.wavefront","RMS.wavefront"),
				   summarize, freq=length(filename))

# Prevent that large numbers are converted to Inf
outputData$statespace.states <- as.character(outputData$statespace.states)
# Order data
outputData <- outputData[order(outputData$filename),]
# Write compressed data
write.table(outputData, file=args[2], sep=',', quote=TRUE ,row.names=FALSE,na="")