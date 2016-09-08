#!/usr/bin/Rscript
.libPaths("/home/richard/Tools/R")
library(ggplot2)
library(plyr)
library(reshape2)
library(scales)
library(doMC)

# Make sure we use all available CPUs
doMC::registerDoMC(cores=8)

# analyzBest investigates the number of times a technique was the best strategy to solve a model 
# Argument 1 = File with performance data per model and strategy
# Argument 2 = Folder where the graphs are stored

# Anything below markThreshold will be considered as 'best' strategy
markThreshold <- 1
header <- "Number of times selected as best"
outputFile <- "Best"

# Read file
args <- commandArgs(trailingOnly = TRUE)
perfData <- read.csv(file=args[1], sep=',', quote="\"")
# Remove marks of unsolvable model and strategy pairs
perfData <- subset(perfData, solvedCount > 0)

order <- "order"
sat <- c("saturation","sat.granularity")
model <- c("filename","filetype")

# Add labels for graphs
dfSat <- data.frame(saturation=c("sat-like","sat-loop","none"), satVal=c(10,20,30))
perfData <- merge(perfData, dfSat, "saturation", all.x=TRUE)
dfGran <- data.frame(sat.granularity=c(1,5,10,20,40,80,2147483647), granVal=1:7)
perfData <- merge(perfData, dfGran, "sat.granularity", all.x=TRUE)
perfData$satVal <- perfData$satVal + perfData$granVal
perfData$satLabel <- ifelse(is.na(perfData$sat.granularity), paste0(perfData$saturation), paste0(perfData$saturation,"(",as.character(perfData$sat.granularity),")"))
dfOrderChar <- data.frame(order=c("bfs","bfs-prev","chain","chain-prev"), char=c("b","bp","c","cp"))
perfData <- merge(perfData, dfOrderChar, "order", all.x=TRUE)
perfData$stratLabel <- paste0(perfData$satLabel,"-",perfData$char)

print("TIME")
print("")

# Best TIME (STRATEGY)

timeData <- subset(perfData, timeMark <= markThreshold)
stratData <- ddply(.parallel=TRUE, timeData, c(order, sat, "satLabel", "satVal", "stratLabel"), summarize, count=length(order))
# Add missing strategies
allStrat <- ddply(.parallel=TRUE, perfData, c(order, sat, "satLabel", "satVal", "stratLabel"), summarize, dummy=TRUE)
allStrat <- allStrat[,1:6]
stratData <- merge(stratData, allStrat, c(order, sat, "satLabel", "satVal", "stratLabel"), all.y=TRUE)
stratData$count <- ifelse(is.na(stratData$count), 0, stratData$count)

print("Number times a strategy is the most appropiate strategy.")
print(stratData[,c(1,2,3,7)])
print("")

# Create graph - saturation strategy is grouped
ggplot(stratData) + 
	# Data
	geom_bar(aes(x=reorder(satLabel, -satVal), y=count, fill=order), stat="identity", position=position_dodge()) +
	coord_flip() +
	# Aes
	labs(title=paste0(header)) +
	xlab("Saturation") +
	ylab("Number of models")

ggsave(paste0(args[2],"/Time/",outputFile," Strategy - Grouped.pdf"), height=9, width=6)

# Create graph - ordered on count
ggplot(stratData) + 
	# Data
	geom_bar(aes(x=reorder(stratLabel,count), y=count, fill=order), stat="identity", position=position_dodge()) +
	coord_flip() +
	# Aes
	labs(title=paste0(header)) +
	xlab("Strategy") +
	ylab("Number of models")

ggsave(paste0(args[2],"/Time/",outputFile," Strategy - Separate.pdf"), height=9, width=6)

# Best TIME (ORDER)

orderData <- ddply(.parallel=TRUE, timeData, c(model, order), summarize, dummy=TRUE)
orderData <- ddply(.parallel=TRUE, orderData, order, summarize, count=length(order))

print("Number times an exploration order is the most appropiate strategy.")
print(orderData)
print("")

# Create graph - ordered on count
ggplot(orderData) + 
	# Data
	geom_bar(aes(x=reorder(order,count), y=count, fill=order), stat="identity", position=position_dodge()) +
	coord_flip() +
	# Aes
	labs(title=paste0(header)) +
	xlab("Exploration order") +
	ylab("Number of models")

ggsave(paste0(args[2],"/Time/",outputFile," Order.pdf"), height=4, width=6)

# Best TIME (SATURATION)

satData <- ddply(.parallel=TRUE, timeData, c(model, sat, "satLabel", "satVal"), summarize, dummy=TRUE)
satData <- ddply(.parallel=TRUE, satData, c(sat, "satLabel", "satVal"), summarize, count=length(saturation))

print("Number times a saturation strategy is the most appropiate strategy.")
print(satData[,c(1,2,5)])
print("")

# Create graph - saturation strategy is grouped
ggplot(satData) + 
	# Data
	geom_bar(aes(x=reorder(satLabel, -satVal), y=count, fill=saturation), stat="identity", position=position_dodge()) +
	coord_flip() +
	# Aes
	scale_fill_brewer(palette="Set2") +
	labs(title=paste0(header)) +
	xlab("Saturation strategy") +
	ylab("Number of models")

ggsave(paste0(args[2],"/Time/",outputFile," Saturation - Grouped.pdf"), height=6, width=6)

# Create graph - ordered on count
ggplot(satData) + 
	# Data
	geom_bar(aes(x=reorder(satLabel, count), y=count, fill=saturation), stat="identity", position=position_dodge()) +
	coord_flip() +
	# Aes
	scale_fill_brewer(palette="Set2") +
	labs(title=paste0(header)) +
	xlab("Saturation strategy") +
	ylab("Number of models")

ggsave(paste0(args[2],"/Time/",outputFile," Saturation - Separate.pdf"), height=6, width=6)

print("PAEKSIZE")
print("")

# Best PAEKSIZE (STRATEGY)

memData <- subset(perfData, !is.na(peak.nodes) & memMark <= markThreshold)
print(paste("Number of models:", nrow(ddply(.parallel=TRUE, memData, model, summarize, dummy=TRUE))))
print("")

stratData <- ddply(.parallel=TRUE, memData, c(order, sat, "satLabel", "satVal", "stratLabel"), summarize, count=length(order))
# Add missing strategies
allStrat <- ddply(.parallel=TRUE, perfData, c(order, sat, "satLabel", "satVal", "stratLabel"), summarize, dummy=TRUE)
allStrat <- allStrat[,1:6]
stratData <- merge(stratData, allStrat, c(order, sat, "satLabel", "satVal", "stratLabel"), all.y=TRUE)
stratData$count <- ifelse(is.na(stratData$count), 0, stratData$count)

print("Number times a strategy is the most appropiate strategy.")
print(stratData[,c(1,2,3,7)])
print("")

# Create graph - saturation strategy is grouped
ggplot(stratData) + 
	# Data
	geom_bar(aes(x=reorder(satLabel, -satVal), y=count, fill=order), stat="identity", position=position_dodge()) +
	coord_flip() +
	# Aes
	labs(title=paste0(header)) +
	xlab("Saturation") +
	ylab("Number of models")

ggsave(paste0(args[2],"/Peaknodes/",outputFile," Strategy - Grouped.pdf"), height=9, width=6)

# Create graph - ordered on count
ggplot(stratData) + 
	# Data
	geom_bar(aes(x=reorder(stratLabel,count), y=count, fill=order), stat="identity", position=position_dodge()) +
	coord_flip() +
	# Aes
	labs(title=paste0(header)) +
	xlab("Strategy") +
	ylab("Number of models")

ggsave(paste0(args[2],"/Peaknodes/",outputFile," Strategy - Separate.pdf"), height=9, width=6)

# Best PAEKSIZE (ORDER)

orderData <- ddply(.parallel=TRUE, memData, c(model, order), summarize, dummy=TRUE)
orderData <- ddply(.parallel=TRUE, orderData, order, summarize, count=length(order))
# Add missing orders
allOrder <- ddply(.parallel=TRUE, perfData, order, summarize, dummy=TRUE)
orderData <- merge(orderData, allOrder, order, all.y=TRUE)
orderData <- orderData[,1:2]
orderData$count <- ifelse(is.na(orderData$count), 0, orderData$count)

print("Number times an exploration order is the most appropiate strategy.")
print(orderData)
print("")

# Create graph - ordered on count
ggplot(orderData) + 
	# Data
	geom_bar(aes(x=reorder(order,count), y=count, fill=order), stat="identity", position=position_dodge()) +
	coord_flip() +
	# Aes
	labs(title=paste0(header)) +
	xlab("Exploration order") +
	ylab("Number of models")

ggsave(paste0(args[2],"/Peaknodes/",outputFile," Order.pdf"), height=4, width=6)

# Best PAEKSIZE (SATURATION)

satData <- ddply(.parallel=TRUE, memData, c(model, sat, "satLabel", "satVal"), summarize, dummy=TRUE)
satData <- ddply(.parallel=TRUE, satData, c(sat, "satLabel", "satVal"), summarize, count=length(saturation))

print("Number times a saturation strategy is the most appropiate strategy.")
print(satData[,c(1,2,5)])
print("")

# Create graph - saturation strategy is grouped
ggplot(satData) + 
	# Data
	geom_bar(aes(x=reorder(satLabel, -satVal), y=count, fill=saturation), stat="identity", position=position_dodge()) +
	coord_flip() +
	# Aes
	scale_fill_brewer(palette="Set2") +
	labs(title=paste0(header)) +
	xlab("Saturation strategy") +
	ylab("Number of models")

ggsave(paste0(args[2],"/Peaknodes/",outputFile," Saturation - Grouped.pdf"), height=6, width=6)

# Create graph - ordered on count
ggplot(satData) + 
	# Data
	geom_bar(aes(x=reorder(satLabel, count), y=count, fill=saturation), stat="identity", position=position_dodge()) +
	coord_flip() +
	# Aes
	scale_fill_brewer(palette="Set2") +
	labs(title=paste0(header)) +
	xlab("Saturation strategy") +
	ylab("Number of models")

ggsave(paste0(args[2],"/Peaknodes/",outputFile," Saturation - Separate.pdf"), height=6, width=6)
