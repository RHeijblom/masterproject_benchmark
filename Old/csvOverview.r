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
source("./dataUtils.r")
inputData <- preprocessAll(inputData)

# Global variables
testCase <- c("order","sat.granularity")
solvedThreshold <- 5 # At least x out of 10 models need to be solved in order for a technique to be considered as suitable
relativeMargin <- 0  # Percentage from which the average metric value should lie to the absolute best metric value to be considered as best metric value

# OVERVIEW SOLVED MODELS (TOTAL)

print("Start generating solved overview.")

# Select relevant columns
inputDataStatus <- subset(inputData, select=c("filename","type", testCase,"status"))
# Flatten status
inputDataStatus <- ddply(.parallel=TRUE, inputDataStatus, c("filename", testCase,"status"), summarize, frequency=length(status))
# Abstract status to "ok" and "fail"
inputDataStatusSimple <- inputDataStatus
inputDataStatusSimple$status <- ifelse(grepl("done",inputDataStatus$status),"ok","fail")
inputDataStatusSimple <- ddply(.parallel=TRUE, inputDataStatusSimple, c("filename", testCase,"status"), summarize, frequency = sum(frequency))
# Flatten order & sat-granularity
statusOk = subset(inputDataStatusSimple, status == "ok")
statusOk = subset(statusOk, select=c("filename",testCase,"frequency"))
statusOk = ddply(.parallel=TRUE, statusOk, testCase, summarize, totalOk = sum(frequency))
statusFail = subset(inputDataStatusSimple, status == "fail")
statusFail = subset(statusFail, select=c("filename", testCase,"frequency"))
statusFail = ddply(.parallel=TRUE, statusFail, testCase, summarize, totalFail = sum(frequency))
# Combine ok frequency and fail frequency in single row
statusOverview = merge(statusOk, statusFail, testCase)

statusOverview$total = statusOverview[,"totalOk"] + statusOverview[,"totalFail"]

print("Overview:")
print(statusOverview)

# Make graph of statusOverview

ggplot(statusOverview) + 
	# Data
	geom_point(aes(x=sat.granularity, y=totalOk, color=order)) +
	# Aes
	labs(title="Performance Overview") +
	xlab("Saturation granularity") +
	ylab("# Solved models") +
    scale_colour_discrete(name = "Exploration order")

ggsave("./Out/Solved.pdf", height=4, width=7)

print("Done generating solved overview.")

# LAZY; RIP FROM CSVSEPERATOR.R	
# PREPROCESSING: only selected models which are solved above the specified threshold
dataPerformance <- subset(inputData, type == "performance")
dataPerformance$isSolved <- dataPerformance$status == "done"
# Check which techniques are suitable candidates; i.e. they can solve the model (most of the time)
dataSolved <- ddply(.parallel=TRUE, dataPerformance, c("filename","order","sat.granularity"), summarize, frequency=sum(isSolved), total=length(isSolved))
dataSolved$isSuitable <- 10*dataSolved$frequency >= solvedThreshold*dataSolved$total
dataPerformance <- merge(dataPerformance, dataSolved, c("filename","order","sat.granularity"))
# Filter rows
dataPerformance <- subset(dataPerformance, isSuitable & isSolved)


# BEST CONFIGURATION wrt a specific metric

metricId <- c("time","memory")
metricName <- c("Time","Memory")
metricLbl <-c("Fastest configuration","Smallest memory footprint")

for(m in 1:length(metricId)){
	# Set metric
	metric <- metricId[m]
	name <- metricName[m]
	label <- paste("#", metricLbl[m])
	
	print(paste("Start generating", metric, "overview."))
	
	dataSolved <- subset(subset(dataPerformance, status == "done"), select=c("filename", testCase, metric))
	# Rename metric to "metric" so ddply will identify the right column
	names(dataSolved)[names(dataSolved)==metric] <- "metric"
	# Flatten time
	dataSolved <- ddply(.parallel=TRUE, dataSolved, c("filename", testCase), summarize, meanMetric = mean(metric))
	# Best per model							
	dataBestMetric <- ddply(.parallel=TRUE, dataSolved, "filename", summarize, bestMetric = min(meanMetric))
	dataBest <- merge(dataSolved, dataBestMetric, "filename")
	#dataBest <- subset(dataBest, meanMetric == bestMetric)
	dataBest <- subset(dataBest, meanMetric <= ((bestMetric*(100+relativeMargin))/100))
	
	# Frequency table for both ORDER & GRANULARITY
	dataCaseBest <- ddply(.parallel=TRUE, dataBest, testCase, summarize, frequency = length(filename))
	print(label)
	print(dataCaseBest)
	# Diagram
	ggplot(dataCaseBest) + 
		# Data
		geom_bar(aes(x=sat.granularity, y=frequency, fill=order), stat="identity", position=position_dodge()) +
		# Aes
		labs(title=paste0("Best configuration (", name, ")")) +
		xlab("Saturation granularity") +
		ylab(label)

	ggsave(paste0("./Out/Best_", name, "_Combined.pdf"), height=4, width=7)

	# Frequency table for ORDER
	dataOrderBest <- ddply(.parallel=TRUE, dataCaseBest, "order", summarize, frequency = sum(frequency))
	print(label)
	print(dataOrderBest)
	# Diagram 
	ggplot(dataOrderBest) + 
		# Data
		geom_bar(aes(x=order, y=frequency, fill=order), stat="identity") +
		# Aes
		labs(title=paste0("Best configuration (", name, ")")) +
		xlab("Exploration order") +
		ylab(label) +
		guides(fill=FALSE)

	ggsave(paste0("./Out/Best_", name, "_Order.pdf"), height=4, width=7)

	# Frequency table for GRANULARITY
	dataGranularityBest <- ddply(.parallel=TRUE, dataCaseBest, "sat.granularity", summarize, frequency = sum(frequency))
	print(label)
	print(dataGranularityBest)
	# Diagram
	ggplot(dataGranularityBest) + 
		# Data
		geom_bar(aes(x=sat.granularity, y=frequency), stat="identity") +
		# Aes
		labs(title=paste0("Best configuration (", name, ")")) +
		xlab("Saturation granularity") +
		ylab(label)

	ggsave(paste0("./Out/Best_", name, "_Granularity.pdf"), height=4, width=7)

	print(paste("Finished generating", metric, "overview."))
	
}

