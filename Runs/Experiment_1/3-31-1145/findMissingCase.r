#!/usr/bin/Rscript
.libPaths("/home/richard/Tools/R")
library(ggplot2)
library(plyr)
library(reshape2)
library(scales)
library(doMC)

# Make sure we use all available CPUs
doMC::registerDoMC(cores=8)

# Read input from csv
args <- commandArgs(trailingOnly = TRUE)
inputData <- read.csv(file=args[1], sep=',', quote="\"")

sumModel <- ddply(.parallel=TRUE, inputData, c("filename", "order"), summarize, frequency=length(status))
subSet <- subset(sumModel, frequency < 11)
print(subSet)