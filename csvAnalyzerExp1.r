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

# STATUS

# Select relevant columns
inputDataStatus <- subset(inputData, select=c("filename","type","order","sat.granularity","status","status.spec"))
# Flatten status
inputDataStatus <- ddply(.parallel=TRUE, inputDataStatus, c("filename","order","sat.granularity","status","status.spec"), summarize, frequency=length(status))
# Abstract status to "ok" and "fail"
inputDataStatusSimple <- inputDataStatus
inputDataStatusSimple$status <- ifelse(grepl("done",inputDataStatus$status),"ok","fail")
inputDataStatusSimple <- ddply(.parallet=TRUE, inputDataStatusSimple, c("filename","order","sat.granularity","status"), summarize, frequency = sum(frequency))
# Flatten order & sat-granularity
statusOk = subset(inputDataStatusSimple, status == "ok")
statusOk = subset(statusOk, select=c("filename","order","sat.granularity","frequency"))
statusOk = ddply(.parallel=TRUE, statusOk, c("order","sat.granularity"), summarize, totalOk = sum(frequency))
statusFail = subset(inputDataStatusSimple, status == "fail")
statusFail = subset(statusFail, select=c("filename","order","sat.granularity","frequency"))
statusFail = ddply(.parallel=TRUE, statusFail, c("order","sat.granularity"), summarize, totalFail = sum(frequency))
# Combine ok frequency and fail frequency in single row
statusOverview = merge(statusOk, statusFail, c("order","sat.granularity"))

statusOverview$total = statusOverview[,3] + statusOverview[,4]
print(statusOverview)

# Make graph of statusOverview

ggplot(statusOverview) + 
	# Data
	geom_line(aes(x=sat.granularity, y=totalOk, color=order)) +
	# Aes
	xlab("Saturation granularity") +
	ylab("# Solved models") +
    scale_colour_discrete(name  ="Exploration order")

ggsave("status.pdf", height=4, width=7)

#inputDataPerformance <- subset(subset(inputData, status == "done"), select=c("filename","type","order","sat.granularity","time","memory","peak.nodes"))
