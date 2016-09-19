#!/usr/bin/Rscript
.libPaths("/home/richard/Tools/R")
library(ggplot2)
library(plyr)
library(reshape2)
library(scales)
library(doMC)

# Make sure we use all available CPUs
doMC::registerDoMC(cores=8)

# Read file
args <- commandArgs(trailingOnly = TRUE)
trainData <- read.csv(file=args[1], sep=',', quote="\"")
trainData$model <- "Model"

ggplot(trainData, aes(x=order, y=state.vector.length)) + 
	# Data
	geom_boxplot() +
	geom_jitter(position=position_jitter(0.2), aes(color=order)) +
	# Aes
	coord_flip() +
	scale_y_log10() +
	labs(title=paste0("Distribution of bandwidth")) +
	xlab("Bandwidth") +
    ylab("Exploration order") 

ggsave(paste0(args[2],"/Bandwidth.pdf"), height=6, width=7)