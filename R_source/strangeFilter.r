#!/usr/bin/Rscript
.libPaths("/home/richard/Tools/R")
library(ggplot2)
library(plyr)
library(reshape2)
library(scales)
library(doMC)

# Make sure we use all available CPUs
doMC::registerDoMC(cores=8)

#  Script for quickly filtering records

# Read file
args <- commandArgs(trailingOnly = TRUE)
#source("./statUtils.r")
allData <- read.csv(file=args[1], sep=',', quote="\"")

allData <- subset(allData, type == "statistics")
#allData <- subset(allData, filename == "fischer.1" | filename == "Philosophers-10" | filename == "phils.2" | filename == "RAS-R-2")
allData <- subset(allData, filename == "cyclic_scheduler.2" | filename == "phils.3" | filename == "protocols.4" | filename == "RAS-R-10")

outputData <- allData
# Prevent that large numbers are converted to Inf
outputData$statespace.states <- as.character(outputData$statespace.states)
# Order data
outputData <- outputData[order(outputData$filename),]
# Write compressed data
write.table(outputData, file=args[2], sep=',', quote=TRUE ,row.names=FALSE,na="")