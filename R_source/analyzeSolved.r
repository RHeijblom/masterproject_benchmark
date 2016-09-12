#!/usr/bin/Rscript
.libPaths("/home/richard/Tools/R")
library(ggplot2)
library(plyr)
library(reshape2)
library(scales)
library(doMC)

# Make sure we use all available CPUs
doMC::registerDoMC(cores=8)

# analyzeSolved creates an overview to gain insight in which models can be solved per technique

# Read file
args <- commandArgs(trailingOnly = TRUE)
source("./statUtils.r")
perfData <- read.csv(file=args[1], sep=',', quote="\"")

order <- "order"
sat <- c("saturation","sat.granularity")
model <- c("filename","filetype")

# Solved per TEST CASE

perfData <- subset(perfData, solvedCount > 0)
perfData <- addGraphLabels(perfData)
testcaseData <- ddply(.parallel=TRUE, perfData, c(order,sat), summarize, total = length(order))

# If there exists a test case which cannot solve any model, make sure there will appear a record for this test case with total = 0
allTestcases <- ddply(.parallel=TRUE, perfData, c(order,sat,"satLabel","satVal","stratLabel"), summarize, dummy=TRUE)
allTestcases <- allTestcases[,1:6]
allTestcases <- merge(allTestcases, testcaseData, c(order,sat), all.x=TRUE)
allTestcases$total <- ifelse(is.na(allTestcases$total), 0, allTestcases$total)

# Print results
print("Number of solved models per testcase:")
print(allTestcases[,c(1,2,3,7)])
print("")

# Create diagram grouped by saturation strategy
ggplot(allTestcases) + 
	# Data
	geom_bar(aes(x=reorder(satLabel, -satVal), y=total, fill=order), stat="identity", position=position_dodge()) +
	coord_flip() +
	# Aes
	labs(title=paste0("Capability of the selected strategies")) +
	xlab("Saturation") +
	ylab("Number of models")

ggsave(paste0(args[2],"/Solved Strategy - Grouped.pdf"), height=9, width=6)

# Create diagram sorted by total only
ggplot(allTestcases) + 
	# Data
	geom_bar(aes(x=reorder(stratLabel,total), y=total, fill=order), stat="identity", position=position_dodge()) +
	coord_flip() +
	# Aes
	labs(title=paste0("Capability of the selected strategies")) +
	xlab("Strategy") +
	ylab("Number of models")

ggsave(paste0(args[2],"/Solved Strategy - Seperate.pdf"), height=9, width=6)

# Solved per ORDER

# Abstract from saturation strategy
orderData <- ddply(.parallel=TRUE, perfData, c(order,model), summarize, dummy=TRUE)
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

# Create diagram
ggplot(allOrders) + 
	# Data
	geom_bar(aes(x=order, y=total, fill=order), stat="identity") +
	coord_flip() +
	# Aes
	labs(title=paste0("Capability of exploration order with dynamic saturation")) +
	xlab("Exploration order") +
	ylab("Number of models")

ggsave(paste0(args[2],"/Solved Order.pdf"), height=4, width=6)

# Solved per SATURATION STRATEGY
# Abstract from order
satData <- ddply(.parallel=TRUE, perfData, c(sat,model), summarize, dummy=TRUE)
satData <- ddply(.parallel=TRUE, satData, sat, summarize, total = length(saturation))

# If there exists an order which cannot solve any model, make sure there will appear a record for this order with total = 0
allSats <- ddply(.parallel=TRUE, perfData, c(sat,"satLabel","satVal"), summarize, dummy=TRUE)
allSats <- allSats[,1:4]
allSats <- merge(allSats, satData, sat, all.x=TRUE)
allSats$total <- ifelse(is.na(allSats$total), 0, allSats$total)

# Print results
print("Number of solved models per saturation strategy:")
print(allSats[,c(1,2,5)])

# Create diagram grouped by saturation strategy
ggplot(allSats) + 
	# Data
	geom_bar(aes(x=reorder(satLabel,-satVal), y=total, fill=saturation), stat="identity", position=position_dodge()) +
	coord_flip() +
	# Aes
	scale_fill_brewer(palette="Set2") +
	labs(title=paste0("Capability of saturation strategy with dynamic exploration order")) +
	xlab("Saturation strategy") +
	ylab("Number of models")

ggsave(paste0(args[2],"/Solved Saturation - Grouped.pdf"), height=6, width=6)

# Create diagram sorted by total only
ggplot(allSats) + 
	# Data
	geom_bar(aes(x=reorder(satLabel,total), y=total, fill=saturation), stat="identity", position=position_dodge()) +
	coord_flip() +
	# Aes
	scale_fill_brewer(palette="Set2") +
	labs(title=paste0("Capability of saturation strategy with dynamic exploration order")) +
	xlab("Saturation strategy") +
	ylab("Number of models")

ggsave(paste0(args[2],"/Solved Saturation - Seperate.pdf"), height=6, width=6)
