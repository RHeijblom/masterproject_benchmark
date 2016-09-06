#!/usr/bin/Rscript
.libPaths("/home/richard/Tools/R")
library(ggplot2)
library(plyr)
library(reshape2)
library(scales)
library(doMC)

# Make sure we use all available CPUs
doMC::registerDoMC(cores=8)

# analyzeSolved creates an overview to gain insight how good each model is solved
# Argument 1 = File with performance data per model and strategy
# Argument 2 = File with model data
# Argument 3 = Folder where the graphs are stored

# Read file
args <- commandArgs(trailingOnly = TRUE)
perfData <- read.csv(file=args[1], sep=',', quote="\"")
# Remove marks of unsolvable model and strategy pairs
perfData <- subset(perfData, solvedCount > 0)
modelData <- read.csv(file=args[2], sep=',')

allData <- merge(perfData, modelData, "filename")

# Overview per group of models
modelGroups <- unique(modelData$parent.name)
for(m in 1:length(modelGroups)){
	group <- modelGroups[m]
	
	groupData <- subset(allData, parent.name == group)
	
	# Create boxplot for TIME
	ggplot(groupData, aes(x=reorder(param.name, -param.val), y=timeMark)) + 
		# Data
		geom_boxplot() +
		geom_jitter(position=position_jitter(0.2), aes(color=order)) +
		stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
		coord_flip() +
		# Aes
		labs(title=paste0("Performance on model '", group, "' (Time)")) +
		xlab("Model variant") +
		ylab("Mark")

	ggsave(paste0(args[3],"/Time/Model '",group,"'.pdf"), height=6, width=7)
	
	groupData <- subset(groupData, !is.na(peak.nodes))
	
	if(nrow(groupData) > 0){ # Make sure we've discovered peaksize for this model
		# Create boxplot for PEAKSIZE
		ggplot(groupData, aes(x=reorder(param.name, -param.val), y=memMark)) + 
			# Data
			geom_boxplot() +
			geom_jitter(position=position_jitter(0.2), aes(color=order)) +
			stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
			coord_flip() +
			# Aes
			labs(title=paste0("Performance on model '", group, "' (Peaksize)")) +
			xlab("Model variant") +
			ylab("Mark")

		ggsave(paste0(args[3],"/Peaknodes/Model '",group,"'.pdf"), height=6, width=7)
	}
}

# All marks

# Abstract from model differences
allData$param.name <- "All"

# Create boxplot for TIME
ggplot(allData, aes(x=param.name, y=timeMark)) + 
	# Data
	geom_boxplot() +
	geom_jitter(position=position_jitter(0.5), aes(color=order)) +
	stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
	coord_flip() +
	# Aes
	labs(title=paste0("Performance on all models (Time)")) +
	xlab("Model variant") +
	ylab("Mark")

ggsave(paste0(args[3],"/Model Performance - Time.pdf"), height=5, width=7)

print(paste("Mean time mark:", mean(allData$timeMark)))

# Create 2nd boxplot for TIME (limited to Mark = 50)
ggplot(allData, aes(x=param.name, y=timeMark)) + 
	# Data
	geom_boxplot() +
	geom_jitter(position=position_jitter(0.5), aes(color=order)) +
	stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
	# Aes
	labs(title=paste0("Performance on all models (Time)")) +
	xlab("Model variant") +
	ylab("Mark") +
	coord_cartesian(ylim=c(0, 50)) +
	coord_flip()

ggsave(paste0(args[3],"/Model Performance - Time (zoom 1x).pdf"), height=5, width=7)

# Create 3nd boxplot for TIME (limited to Mark = 10)
ggplot(allData, aes(x=param.name, y=timeMark)) + 
	# Data
	geom_boxplot() +
	geom_jitter(position=position_jitter(0.5), aes(color=order)) +
	stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
	# Aes
	labs(title=paste0("Performance on all models (Time)")) +
	xlab("Model variant") +
	ylab("Mark") +
	coord_cartesian(ylim=c(0, 10)) +
	coord_flip()

ggsave(paste0(args[3],"/Model Performance - Time (zoom 2x) .pdf"), height=5, width=7)

# Remove entries where a mark for peaksize does not exist
allData <- subset(allData, !is.na(peak.nodes))

print(paste("Mean peaksize mark:", mean(allData$timeMark)))

# Create boxplot for PEAKSIZE
ggplot(allData, aes(x=param.name, y=memMark)) + 
	# Data
	geom_boxplot() +
	geom_jitter(position=position_jitter(0.5), aes(color=order)) +
	stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
	coord_flip() +
	# Aes
	labs(title=paste0("Performance on all models (Peaksize)")) +
	xlab("Model variant") +
	ylab("Mark")

ggsave(paste0(args[3],"/Model Performance - Peaksize.pdf"), height=5, width=7)
