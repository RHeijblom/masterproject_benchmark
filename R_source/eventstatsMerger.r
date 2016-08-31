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

combine <- function(vector) ifelse(all(is.na(vector)), NA, max(vector, na.rm=TRUE))
								   
outputData <- ddply(.parallel=TRUE, inputData, c("filename","filetype"), summarize, 
					"event-span" = combine(event.span),
					"event-span-norm" = combine(event.span.norm),
					"weighted-event-span" = combine(weighted.event.span),
					"weighted-event-span-norm" = combine(weighted.event.span.norm)				   
				   )
print("Data merged...")

# Order data
outputData <- outputData[order(outputData$filename),]
# Write compressed data
write.table(outputData, file=args[2], sep=',', quote=TRUE ,row.names=FALSE,na="")
print("Data saved...")