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

ggplot(trainData, aes(x=profile, y=sat.granularity, color=order)) + 
	# Data
	geom_point() +
    geom_smooth(method=lm, se=FALSE, fullrange=TRUE)+
	#stat_ellipse() +
	# Aes
	scale_x_log10() +
	scale_y_log10() +
	labs(title=paste0("Distribution of bandwidth")) +
	xlab("State vector length") +
    ylab("Groups") 

ggsave(paste0(args[2],"/View2D.pdf"), height=6, width=7)