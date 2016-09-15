#!/usr/bin/Rscript
.libPaths("/home/richard/Tools/R")
library(ggplot2)
library(plyr)
library(reshape2)
library(scales)
library(doMC)

# Make sure we use all available CPUs
doMC::registerDoMC(cores=8)

# analyzBest investigates the performance per strategy
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

# TIME

print("TIME")
print("")

# BOXPLOTS FOR TIME PERFORMANCE OF STRATEGIES (GROUPED BY SATURATION)

print("Mark distribution for all strategies")
print(summarizeDataByGroup(perfData, c(order,sat), "timeMark"))
print("")

# Create boxplot for TIME
ggplot(perfData, aes(x=reorder(satLabel, -satVal), y=timeMark, fill=order)) + 
	# Data
	geom_boxplot() +
	coord_flip() +
	# Aes
	labs(title=paste0("Performance on all models (Time)")) +
	xlab("Strategy") +
	ylab("Mark")

ggsave(paste0(args[2],"/Time/Performance Strategy - Grouped.pdf"), height=9, width=6)

# Create boxplot for TIME (1st zoom)
ggplot(perfData, aes(x=reorder(satLabel, -satVal), y=timeMark, fill=order)) + 
	# Data
	geom_boxplot() +
	coord_flip(ylim=c(0,20)) +
	# Aes
	labs(title=paste0("Performance on all models (Time)")) +
	xlab("Strategy") +
	ylab("Mark")

ggsave(paste0(args[2],"/Time/Performance Strategy - Grouped (zoom 1x).pdf"), height=9, width=6)

# Create boxplot for TIME (2nd zoom)
ggplot(perfData, aes(x=reorder(satLabel, -satVal), y=timeMark, fill=order)) + 
	# Data
	geom_boxplot() +
	coord_flip(ylim=c(0,5)) +
	# Aes
	labs(title=paste0("Performance on all models (Time)")) +
	xlab("Strategy") +
	ylab("Mark")

ggsave(paste0(args[2],"/Time/Performance Strategy - Grouped (zoom 2x).pdf"), height=9, width=6)

# BOXPLOT FOR TIME PERFORMANCE OF STRATEGIES (ORDERED BY MEAN)
dfAvgMarks <- ddply(.parallel=TRUE, perfData, c(order,sat), summarize, timeMarkAvg = mean(timeMark))
perfData <- merge(perfData, dfAvgMarks, c(order,sat))

# Create boxplot for TIME
ggplot(perfData, aes(x=reorder(stratLabel, timeMarkAvg), y=timeMark, fill=order)) + 
	# Data
	geom_boxplot() +
	stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
	coord_flip() +
	# Aes
	labs(title=paste0("Performance on all models (Time)")) +
	xlab("Strategy") +
	ylab("Mark")

ggsave(paste0(args[2],"/Time/Performance Strategy - Separate.pdf"), height=9, width=6)

# Create boxplot for TIME (1st zoom)
ggplot(perfData, aes(x=reorder(stratLabel, timeMarkAvg), y=timeMark, fill=order)) + 
	# Data
	geom_boxplot() +
	stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
	coord_flip(ylim=c(0,20)) +
	# Aes
	labs(title=paste0("Performance on all models (Time)")) +
	xlab("Strategy") +
	ylab("Mark")

ggsave(paste0(args[2],"/Time/Performance Strategy - Separate (zoom 1x).pdf"), height=9, width=6)

# Create boxplot for TIME (2nd zoom)
ggplot(perfData, aes(x=reorder(stratLabel, timeMarkAvg), y=timeMark, fill=order)) + 
	# Data
	geom_boxplot() +
	stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
	coord_flip(ylim=c(0,5)) +
	# Aes
	labs(title=paste0("Performance on all models (Time)")) +
	xlab("Strategy") +
	ylab("Mark")

ggsave(paste0(args[2],"/Time/Performance Strategy - Separate (zoom 2x).pdf"), height=9, width=6)

# BOXPLOT FOR TIME PERFORMANCE OF ORDER (ORDERED BY MEAN)
ordData <- ddply(.parallel=TRUE, perfData, c(model,order), summarize, timeMark = min(timeMark, na.rm=TRUE))
dfAvgMarks <- ddply(.parallel=TRUE, ordData, order, summarize, timeMarkAvg = mean(timeMark))
ordData <- merge(ordData, dfAvgMarks, order)

print("Mark distribution for all orders")
print(summarizeDataByGroup(ordData, order, "timeMark"))
print("")

# Create boxplot for TIME
ggplot(ordData, aes(x=reorder(order, timeMarkAvg), y=timeMark, fill=order)) + 
	# Data
	geom_boxplot() +
	stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
	coord_flip() +
	# Aes
	labs(title=paste0("Performance on all models (Time)")) +
	xlab("Exploration order") +
	ylab("Mark")

ggsave(paste0(args[2],"/Time/Performance Order.pdf"), height=4, width=6)

# Create boxplot for TIME (1st zoom)
ggplot(ordData, aes(x=reorder(order, timeMarkAvg), y=timeMark, fill=order)) + 
	# Data
	geom_boxplot() +
	stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
	coord_flip(ylim=c(0,4)) +
	# Aes
	labs(title=paste0("Performance on all models (Time)")) +
	xlab("Exploration order") +
	ylab("Mark")

ggsave(paste0(args[2],"/Time/Performance Order (zoom 1x).pdf"), height=4, width=6)

# Create boxplot for TIME (2nd zoom)
ggplot(ordData, aes(x=reorder(order, timeMarkAvg), y=timeMark, fill=order)) + 
	# Data
	geom_boxplot() +
	stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
	coord_flip(ylim=c(1,3)) +
	# Aes
	labs(title=paste0("Performance on all models (Time)")) +
	xlab("Exploration order") +
	ylab("Mark")

ggsave(paste0(args[2],"/Time/Performance Order (zoom 2x).pdf"), height=4, width=6)

# BOXPLOT FOR TIME PERFORMANCE OF SATURATION (ORDERED BY MEAN)
satData <- ddply(.parallel=TRUE, perfData, c(model,sat, "satLabel", "satVal"), summarize, timeMark = min(timeMark, na.rm=TRUE))
dfAvgMarks <- ddply(.parallel=TRUE, satData, sat, summarize, timeMarkAvg = mean(timeMark))
satData <- merge(satData, dfAvgMarks, sat)

print("Mark distribution for all strategies")
print(summarizeDataByGroup(satData, sat, "timeMark"))
print("")

# Create boxplot for TIME
ggplot(satData, aes(x=reorder(satLabel, timeMarkAvg), y=timeMark, fill=saturation)) + 
	# Data
	geom_boxplot() +
	stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
	coord_flip() +
	# Aes
	scale_fill_brewer(palette="Set2") +
	labs(title=paste0("Performance on all models (Time)")) +
	xlab("Saturation strategy") +
	ylab("Mark")

ggsave(paste0(args[2],"/Time/Performance Saturation - Separate.pdf"), height=6, width=6)

# Create boxplot for TIME (1st zoom)
ggplot(satData, aes(x=reorder(satLabel, timeMarkAvg), y=timeMark, fill=saturation)) + 
	# Data
	geom_boxplot() +
	stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
	coord_flip(ylim=c(0,5)) +
	# Aes
	scale_fill_brewer(palette="Set2") +
	labs(title=paste0("Performance on all models (Time)")) +
	xlab("Saturation strategy") +
	ylab("Mark")

ggsave(paste0(args[2],"/Time/Performance Saturation - Separate (zoom 1x).pdf"), height=6, width=6)

# BOXPLOT FOR TIME PERFORMANCE OF SATURATION (ORDERED BY STRATEGY)
# Create boxplot for TIME
ggplot(satData, aes(x=reorder(satLabel, -satVal), y=timeMark, fill=saturation)) + 
	# Data
	geom_boxplot() +
	stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
	coord_flip() +
	# Aes
	scale_fill_brewer(palette="Set2") +
	labs(title=paste0("Performance on all models (Time)")) +
	xlab("Saturation strategy") +
	ylab("Mark")

ggsave(paste0(args[2],"/Time/Performance Saturation - Grouped.pdf"), height=6, width=6)

# Create boxplot for TIME (1st zoom)
ggplot(satData, aes(x=reorder(satLabel, -satVal), y=timeMark, fill=saturation)) + 
	# Data
	geom_boxplot() +
	stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
	coord_flip(ylim=c(0,5)) +
	# Aes
	scale_fill_brewer(palette="Set2") +
	labs(title=paste0("Performance on all models (Time)")) +
	xlab("Saturation strategy") +
	ylab("Mark")

ggsave(paste0(args[2],"/Time/Performance Saturation - Grouped (zoom 1x).pdf"), height=6, width=6)

# PEAKSIZE

print("PEAKSIZE")
print("")

# BOXPLOTS FOR PEAKSIZE PERFORMANCE OF STRATEGIES (GROUPED BY SATURATION)
perfData <- subset(perfData, !is.na(peak.nodes))

print("Mark distribution for all strategies")
print(summarizeDataByGroup(perfData, c(order,sat), "memMark"))
print("")

# Create boxplot for PEAKSIZE
ggplot(perfData, aes(x=reorder(satLabel, -satVal), y=memMark, fill=order)) + 
	# Data
	geom_boxplot() +
	coord_flip() +
	# Aes
	labs(title=paste0("Performance on all models (Peaksize)")) +
	xlab("Strategy") +
	ylab("Mark")

ggsave(paste0(args[2],"/Peaknodes/Performance Strategy - Grouped.pdf"), height=9, width=6)

# Create boxplot for PEAKSIZE (1st zoom)
ggplot(perfData, aes(x=reorder(satLabel, -satVal), y=memMark, fill=order)) + 
	# Data
	geom_boxplot() +
	coord_flip(ylim=c(1,5)) +
	# Aes
	labs(title=paste0("Performance on all models (Peaksize)")) +
	xlab("Strategy") +
	ylab("Mark")

ggsave(paste0(args[2],"/Peaknodes/Performance Strategy - Grouped (zoom 1x).pdf"), height=9, width=6)

# Create boxplot for PEAKSIZE (2nd zoom)
ggplot(perfData, aes(x=reorder(satLabel, -satVal), y=memMark, fill=order)) + 
	# Data
	geom_boxplot() +
	coord_flip(ylim=c(1,2)) +
	# Aes
	labs(title=paste0("Performance on all models (Peaksize)")) +
	xlab("Strategy") +
	ylab("Mark")

ggsave(paste0(args[2],"/Peaknodes/Performance Strategy - Grouped (zoom 2x).pdf"), height=9, width=6)

# BOXPLOT FOR PEAKSIZE PERFORMANCE OF STRATEGIES (ORDERED BY MEAN)
dfAvgMarks <- ddply(.parallel=TRUE, perfData, c(order,sat), summarize, memMarkAvg = mean(memMark))
perfData <- merge(perfData, dfAvgMarks, c(order,sat))

# Create boxplot for PEAKSIZE
ggplot(perfData, aes(x=reorder(stratLabel, memMarkAvg), y= memMark, fill=order)) + 
	# Data
	geom_boxplot() +
	stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
	coord_flip() +
	# Aes
	labs(title=paste0("Performance on all models (Peaksize)")) +
	xlab("Strategy") +
	ylab("Mark")

ggsave(paste0(args[2],"/Peaknodes/Performance Strategy - Separate.pdf"), height=9, width=6)

# Create boxplot for PEAKSIZE (1st zoom)
ggplot(perfData, aes(x=reorder(stratLabel, memMarkAvg), y=memMark, fill=order)) + 
	# Data
	geom_boxplot() +
	stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
	coord_flip(ylim=c(1,5)) +
	# Aes
	labs(title=paste0("Performance on all models (Peaksize)")) +
	xlab("Strategy") +
	ylab("Mark")

ggsave(paste0(args[2],"/Peaknodes/Performance Strategy - Separate (zoom 1x).pdf"), height=9, width=6)

# Create boxplot for PEAKSIZE (2nd zoom)
ggplot(perfData, aes(x=reorder(stratLabel, memMarkAvg), y=memMark, fill=order)) + 
	# Data
	geom_boxplot() +
	stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
	coord_flip(ylim=c(1,2)) +
	# Aes
	labs(title=paste0("Performance on all models (Peaksize)")) +
	xlab("Strategy") +
	ylab("Mark")

ggsave(paste0(args[2],"/Peaknodes/Performance Strategy - Separate (zoom 2x).pdf"), height=9, width=6)

# BOXPLOT FOR PEAKSIZE PERFORMANCE OF ORDER (ORDERED BY MEAN)
ordData <- ddply(.parallel=TRUE, perfData, c(model,order), summarize, memMark = min(memMark, na.rm=TRUE))
dfAvgMarks <- ddply(.parallel=TRUE, ordData, order, summarize, memMarkAvg = mean(memMark))
ordData <- merge(ordData, dfAvgMarks, order)

print("Mark distribution for all strategies")
print(summarizeDataByGroup(ordData, order, "memMark"))
print("")

# Create boxplot for PEAKSIZE
ggplot(ordData, aes(x=reorder(order, memMarkAvg), y=memMark, fill=order)) + 
	# Data
	geom_boxplot() +
	stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
	coord_flip() +
	# Aes
	labs(title=paste0("Performance on all models (Peaksize)")) +
	xlab("Exploration order") +
	ylab("Mark")

ggsave(paste0(args[2],"/Peaknodes/Performance Order.pdf"), height=4, width=6)

# Create boxplot for PEAKSIZE (1st zoom)
ggplot(ordData, aes(x=reorder(order, memMarkAvg), y=memMark, fill=order)) + 
	# Data
	geom_boxplot() +
	stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
	coord_flip(ylim=c(1,1.2)) +
	# Aes
	labs(title=paste0("Performance on all models (Peaksize)")) +
	xlab("Exploration order") +
	ylab("Mark")

ggsave(paste0(args[2],"/Peaknodes/Performance Order (zoom 1x).pdf"), height=4, width=6)

# Create boxplot for PEAKSIZE (2nd zoom)
ggplot(ordData, aes(x=reorder(order, memMarkAvg), y=memMark, fill=order)) + 
	# Data
	geom_boxplot() +
	stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
	coord_flip(ylim=c(1,1.02)) +
	# Aes
	labs(title=paste0("Performance on all models (Peaksize)")) +
	xlab("Exploration order") +
	ylab("Mark")

ggsave(paste0(args[2],"/Peaknodes/Performance Order (zoom 2x).pdf"), height=4, width=6)

# BOXPLOT FOR PEAK PERFORMANCE OF SATURATION (ORDERED BY MEAN)
satData <- ddply(.parallel=TRUE, perfData, c(model,sat, "satLabel", "satVal"), summarize, memMark = min(memMark, na.rm=TRUE))
dfAvgMarks <- ddply(.parallel=TRUE, satData, sat, summarize, memMarkAvg = mean(memMark))
satData <- merge(satData, dfAvgMarks, sat)

print("Mark distribution for all strategies")
print(summarizeDataByGroup(satData, sat, "memMark"))
print("")

# Create boxplot for PEAK
ggplot(satData, aes(x=reorder(satLabel, memMarkAvg), y=memMark, fill=saturation)) + 
	# Data
	geom_boxplot() +
	stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
	coord_flip() +
	# Aes
	scale_fill_brewer(palette="Set2") +
	labs(title=paste0("Performance on all models (Peaksize)")) +
	xlab("Saturation strategy") +
	ylab("Mark")

ggsave(paste0(args[2],"/Peaknodes/Performance Saturation - Separate.pdf"), height=6, width=6)

# Create boxplot for PEAK (1st zoom)
ggplot(satData, aes(x=reorder(satLabel, memMarkAvg), y=memMark, fill=saturation)) + 
	# Data
	geom_boxplot() +
	stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
	coord_flip(ylim=c(1,4)) +
	# Aes
	scale_fill_brewer(palette="Set2") +
	labs(title=paste0("Performance on all models (Peaksize)")) +
	xlab("Saturation strategy") +
	ylab("Mark")

ggsave(paste0(args[2],"/Peaknodes/Performance Saturation - Separate (zoom 1x).pdf"), height=6, width=6)

# Create boxplot for PEAK (2nd zoom)
ggplot(satData, aes(x=reorder(satLabel, memMarkAvg), y=memMark, fill=saturation)) + 
	# Data
	geom_boxplot() +
	stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
	coord_flip(ylim=c(1,2)) +
	# Aes
	scale_fill_brewer(palette="Set2") +
	labs(title=paste0("Performance on all models (Peaksize)")) +
	xlab("Saturation strategy") +
	ylab("Mark")

ggsave(paste0(args[2],"/Peaknodes/Performance Saturation - Separate (zoom 2x).pdf"), height=6, width=6)

# BOXPLOT FOR PEAKSIZE PERFORMANCE OF SATURATION (ORDERED BY STRATEGY)
# Create boxplot for PEAKSIZE
ggplot(satData, aes(x=reorder(satLabel, -satVal), y=memMark, fill=saturation)) + 
	# Data
	geom_boxplot() +
	stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
	coord_flip() +
	# Aes
	scale_fill_brewer(palette="Set2") +
	labs(title=paste0("Performance on all models (Peaksize)")) +
	xlab("Saturation strategy") +
	ylab("Mark")

ggsave(paste0(args[2],"/Peaknodes/Performance Saturation - Grouped.pdf"), height=6, width=6)

# Create boxplot for PEAKSIZE (1st zoom)
ggplot(satData, aes(x=reorder(satLabel, -satVal), y=memMark, fill=saturation)) + 
	# Data
	geom_boxplot() +
	stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
	coord_flip(ylim=c(1,4)) +
	# Aes
	scale_fill_brewer(palette="Set2") +
	labs(title=paste0("Performance on all models (Peaksize)")) +
	xlab("Saturation strategy") +
	ylab("Mark")

ggsave(paste0(args[2],"/Peaknodes/Performance Saturation - Grouped (zoom 1x).pdf"), height=6, width=6)

# Create boxplot for PEAKSIZE (2nd zoom)
ggplot(satData, aes(x=reorder(satLabel, -satVal), y=memMark, fill=saturation)) + 
	# Data
	geom_boxplot() +
	stat_summary(fun.y=mean, geom="point", shape=18, size=5, color="gray33") +
	coord_flip(ylim=c(1,2)) +
	# Aes
	scale_fill_brewer(palette="Set2") +
	labs(title=paste0("Performance on all models (Peaksize)")) +
	xlab("Saturation strategy") +
	ylab("Mark")

ggsave(paste0(args[2],"/Peaknodes/Performance Saturation - Grouped (zoom 2x).pdf"), height=6, width=6)