#!/usr/bin/Rscript
.libPaths("/home/richard/Tools/R")
library(plyr)
library(reshape2)
library(doMC)

# Make sure we use all available CPUs
doMC::registerDoMC(cores=8)

# Read file
args <- commandArgs(trailingOnly = TRUE)
inputDataA <- read.csv(file=args[1], sep=',', quote="\"")
# inputDataB should be a function mergePoint to other columns
inputDataB <- read.csv(file=args[1], sep=',', quote="\"")
print("Data loaded...")

# Merge both dataframes 
mergePoint <- c("filename","filetype")
outputData <- merge(inputDataA, inputDataB, mergePoint, all.x = TRUE, all.y = FALSE)
print("Data merged...")

# Order data
outputData <- outputData[order(outputData$filename),]
# Write compressed data
write.table(outputData, file=args[2], sep=',', quote=TRUE ,row.names=FALSE,na="")
print("Data saved...")