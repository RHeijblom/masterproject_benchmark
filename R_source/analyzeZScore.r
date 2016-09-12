#!/usr/bin/Rscript
.libPaths("/home/richard/Tools/R")
library(ggplot2)
library(plyr)
library(reshape2)
library(scales)
library(doMC)

# Make sure we use all available CPUs
doMC::registerDoMC(cores=8)

# analyzeZScore investigates the Z score or standard score per strategy
# Argument 1 = File with performance data per model and strategy
# Argument 2 = Folder where the graphs are stored

# Read file
args <- commandArgs(trailingOnly = TRUE)
source("./statUtils.r")
perfData <- read.csv(file=args[1], sep=',', quote="\"")
# Remove marks of unsolvable model and strategy pairs
perfData <- subset(perfData, solvedCount > 0)

order <- "order"
sat <- c("saturation","sat.granularity")
model <- c("filename","filetype")

# Add labels for graphs
perfData <- addGraphLabels(perfData)

# PREPARE DATA TIME

print("TIME")
print("")

# Calculate Z scores: (x - mean) / sd
modelData <- ddply(.parallel=TRUE, perfData, model, summarize, avgModelTime=mean(timeAvg), sdModelTime=sd(timeAvg))
timeData <- merge(perfData, modelData, model, all.x=TRUE)
timeData$zScore <- (timeData$timeAvg - timeData$avgModelTime) / timeData$sdModelTime
# Remove entries where zScore cannot be calculated because of a lack of data
timeData <- subset(timeData, !is.na(zScore))

# BOXPLOTS FOR TIME PERFORMANCE OF STRATEGIES

print("Z Score distribution for all strategies")
print(summarizeDataByGroup(timeData, c(order,sat), "zScore"))
print("")

# Create boxplot grouped by saturation strategy
ggplot(timeData, aes(x=reorder(satLabel, -satVal), y=zScore, fill=order)) + 
	# Data
	geom_boxplot() +
	coord_flip() +
	# Aes
	labs(title=paste0("Performance on all models (Time)")) +
	xlab("Strategy") +
	ylab("Z score")

ggsave(paste0(args[2],"/Time/Performance Strategy - Grouped.pdf"), height=9, width=6)

# Calculate average Z Score per strategy
dfZScoreAvg <- ddply(.parallel=TRUE, timeData, c(order,sat), summarize, zScoreAvg = mean(zScore))
timeData <- merge(timeData, dfZScoreAvg, c(order,sat))

# Create boxplot ordered by mean
ggplot(timeData, aes(x=reorder(stratLabel, zScoreAvg), y=zScore, fill=order)) + 
	# Data
	geom_boxplot() +
	stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
	coord_flip() +
	# Aes
	labs(title=paste0("Performance on all models (Time)")) +
	xlab("Strategy") +
	ylab("Z score")

ggsave(paste0(args[2],"/Time/Performance Strategy - Separate.pdf"), height=9, width=6)

# BOXPLOT FOR TIME PERFORMANCE OF ORDER

ordData <- ddply(.parallel=TRUE, timeData, c(model,order), summarize, zScore = min(zScore, na.rm=TRUE))

print("Z Score distribution for all orders")
print(summarizeDataByGroup(ordData, order, "zScore"))
print("")

# Calculate average Z Score per order
dfZScoreAvg <- ddply(.parallel=TRUE, ordData, order, summarize, zScoreAvg = mean(zScore))
ordData <- merge(ordData, dfZScoreAvg, order)

# Create boxplot ordered by mean
ggplot(ordData, aes(x=reorder(order, zScoreAvg), y=zScore, fill=order)) + 
	# Data
	geom_boxplot() +
	stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
	coord_flip() +
	# Aes
	labs(title=paste0("Performance on all models (Time)")) +
	xlab("Exploration order") +
	ylab("Z score")

ggsave(paste0(args[2],"/Time/Performance Order.pdf"), height=4, width=6)

# BOXPLOT FOR TIME PERFORMANCE OF SATURATION 

satData <- ddply(.parallel=TRUE, timeData, c(model,sat, "satLabel", "satVal"), summarize, zScore = min(zScore, na.rm=TRUE))

print("Z Score distribution for all saturation strategies")
print(summarizeDataByGroup(satData, sat, "zScore"))
print("")

# Create boxplot grouped by saturation strategy
ggplot(satData, aes(x=reorder(satLabel, -satVal), y=zScore, fill=saturation)) + 
	# Data
	geom_boxplot() +
	stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
	coord_flip() +
	# Aes
	scale_fill_brewer(palette="Set2") +
	labs(title=paste0("Performance on all models (Time)")) +
	xlab("Saturation strategy") +
	ylab("Z score")

ggsave(paste0(args[2],"/Time/Performance Saturation - Grouped.pdf"), height=6, width=6)

# Calculate average Z Score per saturation strategy
dfZScoreAvg <- ddply(.parallel=TRUE, satData, sat, summarize, zScoreAvg = mean(zScore))
satData <- merge(satData, dfZScoreAvg, sat)

# Create boxplot ordered by mean
ggplot(satData, aes(x=reorder(satLabel, zScoreAvg), y=zScore, fill=saturation)) + 
	# Data
	geom_boxplot() +
	stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
	coord_flip() +
	# Aes
	scale_fill_brewer(palette="Set2") +
	labs(title=paste0("Performance on all models (Time)")) +
	xlab("Saturation strategy") +
	ylab("Z score")

ggsave(paste0(args[2],"/Time/Performance Saturation - Separate.pdf"), height=6, width=6)

# PREPARE DATA PEAKSIZE

print("MEMORY")
print("")

perfData <- subset(perfData, !is.na(peak.nodes))
# Calculate Z scores: (x - mean) / sd
modelData <- ddply(.parallel=TRUE, perfData, model, summarize, avgModelMem=mean(peak.nodes), sdModelMem=sd(peak.nodes))
memData <- merge(perfData, modelData, model, all.x=TRUE)
memData$zScore <- (memData$peak.nodes - memData$avgModelMem) / memData$sdModelMem
# Remove entries where zScore cannot be calculated because of a lack of data
memData <- subset(memData, !is.na(zScore))

# BOXPLOTS FOR PEAKSIZE PERFORMANCE OF STRATEGIES

print("Z Score distribution for all strategies")
print(summarizeDataByGroup(memData, c(order,sat), "zScore"))
print("")

# Create boxplot grouped by saturation strategy
ggplot(memData, aes(x=reorder(satLabel, -satVal), y=zScore, fill=order)) + 
	# Data
	geom_boxplot() +
	coord_flip() +
	# Aes
	labs(title=paste0("Performance on all models (Peaksize)")) +
	xlab("Strategy") +
	ylab("Z score")

ggsave(paste0(args[2],"/Peaknodes/Performance Strategy - Grouped.pdf"), height=9, width=6)

# Calculate average Z Score per strategy
dfZScoreAvg <- ddply(.parallel=TRUE, memData, c(order,sat), summarize, zScoreAvg = mean(zScore))
memData <- merge(memData, dfZScoreAvg, c(order,sat))

# Create boxplot ordered by mean
ggplot(memData, aes(x=reorder(stratLabel, zScoreAvg), y=zScore, fill=order)) + 
	# Data
	geom_boxplot() +
	stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
	coord_flip() +
	# Aes
	labs(title=paste0("Performance on all models (Peaksize)")) +
	xlab("Strategy") +
	ylab("Z score")

ggsave(paste0(args[2],"/Peaknodes/Performance Strategy - Separate.pdf"), height=9, width=6)

# BOXPLOT FOR PEAKSIZE PERFORMANCE OF ORDER

ordData <- ddply(.parallel=TRUE, memData, c(model,order), summarize, zScore = min(zScore, na.rm=TRUE))

print("Z Score distribution for all orders")
print(summarizeDataByGroup(ordData, order, "zScore"))
print("")

# Calculate average Z Score per order
dfZScoreAvg <- ddply(.parallel=TRUE, ordData, order, summarize, zScoreAvg = mean(zScore))
ordData <- merge(ordData, dfZScoreAvg, order)

# Create boxplot ordered by mean
ggplot(ordData, aes(x=reorder(order, zScoreAvg), y=zScore, fill=order)) + 
	# Data
	geom_boxplot() +
	stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
	coord_flip() +
	# Aes
	labs(title=paste0("Performance on all models (Peaksize)")) +
	xlab("Exploration order") +
	ylab("Z score")

ggsave(paste0(args[2],"/Peaknodes/Performance Order.pdf"), height=4, width=6)

# BOXPLOT FOR PEAKSIZE PERFORMANCE OF SATURATION 

satData <- ddply(.parallel=TRUE, memData, c(model,sat, "satLabel", "satVal"), summarize, zScore = min(zScore, na.rm=TRUE))

print("Z Score distribution for all saturation strategies")
print(summarizeDataByGroup(satData, sat, "zScore"))
print("")

# Create boxplot grouped by saturation strategy
ggplot(satData, aes(x=reorder(satLabel, -satVal), y=zScore, fill=saturation)) + 
	# Data
	geom_boxplot() +
	stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
	coord_flip() +
	# Aes
	scale_fill_brewer(palette="Set2") +
	labs(title=paste0("Performance on all models (Peaksize)")) +
	xlab("Saturation strategy") +
	ylab("Z score")

ggsave(paste0(args[2],"/Peaknodes/Performance Saturation - Grouped.pdf"), height=6, width=6)

# Calculate average Z Score per saturation strategy
dfZScoreAvg <- ddply(.parallel=TRUE, satData, sat, summarize, zScoreAvg = mean(zScore))
satData <- merge(satData, dfZScoreAvg, sat)

# Create boxplot ordered by mean
ggplot(satData, aes(x=reorder(satLabel, zScoreAvg), y=zScore, fill=saturation)) + 
	# Data
	geom_boxplot() +
	stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
	coord_flip() +
	# Aes
	scale_fill_brewer(palette="Set2") +
	labs(title=paste0("Performance on all models (Peaksize)")) +
	xlab("Saturation strategy") +
	ylab("Z score")

ggsave(paste0(args[2],"/Peaknodes/Performance Saturation - Separate.pdf"), height=6, width=6)
