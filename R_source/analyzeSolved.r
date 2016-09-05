#!/usr/bin/Rscript
.libPaths("/home/richard/Tools/R")
library(plyr)
library(reshape2)
library(doMC)

# Make sure we use all available CPUs
doMC::registerDoMC(cores=8)

# analyzeSolved creates an overview to gain insight in which models can be solved per technique

# Read file
args <- commandArgs(trailingOnly = TRUE)
perfData <- read.csv(file=args[1], sep=',', quote="\"")

order <- "order"
sat <- c("saturation","sat.granularity")
model <- c("filename","filetype")

# Solved per TEST CASE
solvedData <- subset(perfData, solvedCount > 0)
testcaseData <- ddply(.parallel=TRUE, solvedData, c(order,sat), summarize, total = length(order))

# If there exists a test case which cannot solve any model, make sure there will appear a record for this test case with total = 0
allTestcases <- ddply(.parallel=TRUE, perfData, c(order,sat), summarize, dummy=TRUE)
allTestcases <- allTestcases[,1:3]
allTestcases <- merge(allTestcases, testcaseData, c(order,sat), all.x=TRUE)
allTestcases$total <- ifelse(is.na(allTestcases$total), 0, allTestcases$total)

# Print results
print("Number of solved models per testcase:")
print(allTestcases)
print("")

# Solved per ORDER
# Abstract from saturation strategy
orderData <- ddply(.parallel=TRUE, solvedData, c(order,model), summarize, dummy=TRUE)
orderData <- ddply(.parallel=TRUE, orderData, order, summarize, total = length(order))

# If there exists an order which cannot solve any model, make sure there will appear a record for this order with total = 0
allOrders <- ddply(.parallel=TRUE, perfData, order, summarize, dummy=TRUE)
allOrders <- merge(allOrders, orderData, order, all.x=TRUE)
allOrders <- allOrders[,c(1,3)]
allOrders$total <- ifelse(is.na(allOrders$total), 0, allOrders$total)

# Print results
print("Number of solved models per  order:")
print(allOrders)
print("")

# Solved per SATURATION STRATEGY
# Abstract from order
satData <- ddply(.parallel=TRUE, solvedData, c(sat,model), summarize, dummy=TRUE)
satData <- ddply(.parallel=TRUE, satData, sat, summarize, total = length(saturation))

# If there exists an order which cannot solve any model, make sure there will appear a record for this order with total = 0
allSats <- ddply(.parallel=TRUE, perfData, sat, summarize, dummy=TRUE)
allSats <- allSats[,1:2]
allSats <- merge(allSats, satData, sat, all.x=TRUE)
allSats$total <- ifelse(is.na(allSats$total), 0, allSats$total)

# Print results
print("Number of solved models per saturation strategy:")
print(allSats)