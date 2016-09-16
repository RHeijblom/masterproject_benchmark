#!/usr/bin/Rscript
.libPaths("/home/richard/Tools/R")
library(ggplot2)
library(plyr)
library(reshape2)
library(scales)
library(doMC)

# Make sure we use all available CPUs
doMC::registerDoMC(cores=8)

# This script gives an overview of which best strategies are selected in the training data. This script also compares the differences between the time and peaksize data.
# Args 1 = File to training data optimized for time
# Args 2 = File to training data optimized for peaksize
# Args 3 = Directory where the results are stored.
args <- commandArgs(trailingOnly = TRUE)
source("./statUtils.r")

order <- "order"
sat <- c("saturation","sat.granularity")
model <- c("filename","filetype")

createGraphs <- function(trainingData, subdirectory){
	outputDirectory <- paste0(args[3], subdirectory)
	
	trainingData <- ddply(.parallel=TRUE, trainingData, c(order,sat), summarize, freq = length(order))
	trainingData <- addGraphLabels(trainingData)
	
	# STRATEGY
	
	# Print results
	print("Strategy frequency:")
	print(trainingData[,c(1,2,3,4)])
	print("")

	# Create diagram grouped by saturation strategy
	ggplot(trainingData) + 
		# Data
		geom_bar(aes(x=reorder(satLabel, -satVal), y=freq, fill=order), stat="identity", position=position_dodge()) +
		coord_flip() +
		# Aes
		labs(title=paste0("Frequency of strategies occuring in training data")) +
		xlab("Saturation") +
		ylab("Frequency")

	ggsave(paste0(outputDirectory,"/Frequency Strategy - Grouped.pdf"), height=9, width=6)

	# Create diagram sorted by frequency only
	ggplot(trainingData) + 
		# Data
		geom_bar(aes(x=reorder(stratLabel,freq), y=freq, fill=order), stat="identity", position=position_dodge()) +
		coord_flip() +
		# Aes
		labs(title=paste0("Frequency of strategies occuring in training data")) +
		xlab("Strategy") +
		ylab("Frequency")

	ggsave(paste0(outputDirectory,"/Frequency Strategy - Separate.pdf"), height=9, width=6)
	
	# Solved per ORDER

	# Abstract from saturation strategy
	orderData <- ddply(.parallel=TRUE, trainingData, order, summarize, freq = sum(freq))

	# Print results
	print("Order frequency:")
	print(orderData)
	print("")

	# Create diagram
	ggplot(orderData) + 
		# Data
		geom_bar(aes(x=order, y=freq, fill=order), stat="identity") +
		coord_flip() +
		# Aes
		labs(title=paste0("Frequency of exploration orders occuring in training data")) +
		xlab("Exploration order") +
		ylab("Frequency")

	ggsave(paste0(outputDirectory,"/Frequency Order.pdf"), height=4, width=6)
	
	# Solved per SATURATION STRATEGY
	
	# Abstract from order
	satData <- ddply(.parallel=TRUE, trainingData, c(sat,"satLabel","satVal"), summarize, freq = sum(freq))

	# Print results
	print("Saturation frequency:")
	print(satData[,c(1,2,5)])
	print("")
	
	# Create diagram grouped by saturation strategy
	ggplot(satData) + 
		# Data
		geom_bar(aes(x=reorder(satLabel,-satVal), y=freq, fill=saturation), stat="identity", position=position_dodge()) +
		coord_flip() +
		# Aes
		scale_fill_brewer(palette="Set2") +
		labs(title=paste0("Frequency of saturation strategies occuring in training data")) +
		xlab("Saturation strategy") +
		ylab("Frequency")

	ggsave(paste0(outputDirectory,"/Frequency Saturation - Grouped.pdf"), height=6, width=6)

	# Create diagram sorted by frequency only
	ggplot(satData) + 
		# Data
		geom_bar(aes(x=reorder(satLabel,freq), y=freq, fill=saturation), stat="identity", position=position_dodge()) +
		coord_flip() +
		# Aes
		scale_fill_brewer(palette="Set2") +
		labs(title=paste0("Frequency of saturation strategies occuring in training data")) +
		xlab("Saturation strategy") +
		ylab("Frequency")

	ggsave(paste0(outputDirectory,"/Frequency Saturation - Separate.pdf"), height=6, width=6)
	}

timeData <- read.csv(file=args[1], sep=',', quote="\"")
peakData <- read.csv(file=args[2], sep=',', quote="\"")

# Discover distribution of best strategies
print("TIME")
print("")
createGraphs(timeData, "/Time")
print("PEAKSIZE")
print("")
createGraphs(peakData, "/Peaknodes")

# Discover differences
timeData <- timeData[,c(model,order,sat)]
peakData <- peakData[,c(model,order,sat)]

allData <- merge(timeData, peakData, model)
allData <- subset(allData, order.x != order.y | saturation.x != saturation.y | ifelse(is.na(sat.granularity.x),!is.na(sat.granularity.y),is.na(sat.granularity.y) | sat.granularity.x != sat.granularity.y))

print("Best strategy differences: ")
print(allData)
