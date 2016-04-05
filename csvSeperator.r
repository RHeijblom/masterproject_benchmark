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

# Global vars
technique <- c("order","sat.granularity")
MAXINT <- 2147483647 # Identifier of max granularity
solvedThreshold <- 5  # At least x out of 10 models need to be solved in order for a technique to be considered as suitable
relativeMargin <- 5  # Percentage from which the average metric value should lie to the absolute best metric value to be considered as best metric value
signSolvable <- "Y"
signUnsolvable <- "N"

# Metrics per model
metrics <- data.frame(id=c("time","memory"), header=c("TIME","MEMORY"))

# Preprocessing: remove redundant colums and rows
dataPerformance <- subset(inputData, type == "performance")
# Fix cases where sat.granularity is too high; may change testcases for a specific granularity to a multiple of 10 
dataPerformance$sat.granularity <- ifelse(dataPerformance$sat.granularity >= dataPerformance$state.vector.length, MAXINT, dataPerformance$sat.granularity)
# Select relevant columns
dataPerformance <- subset(dataPerformance, select=c("filename","status", technique, as.character(metrics$id)))
# Abstract status to boolean (isSolved)
dataPerformance$isSolved <- dataPerformance$status == "done"
dataPerformance <- subset(dataPerformance, select=c("filename","isSolved", technique, as.character(metrics$id)))

for(mid in 1:nrow(metrics)){
	# Set metric
	m <- metrics[mid,]
	metric <- m$id
	
	dataMetric <- dataPerformance
	# Rename metric to "metric" so ddply will identify the right column
	names(dataMetric)[names(dataMetric)==metric] <- "metric"
	# Check which techniques are suitable candidates; i.e. they can solve the model (most of the time)
	dataMetricSolved <- ddply(.parallel=TRUE, dataMetric, c("filename",technique), summarize, frequency=sum(isSolved), total=length(isSolved))
	dataMetricSolved$isSuitable <- dataMetricSolved$frequency >= ((solvedThreshold*dataMetricSolved$total)/10)
	dataMetric <- merge(dataMetric, dataMetricSolved, c("filename",technique))
	# Select suitable candidates
	dataMetric <- subset(dataMetric, isSuitable & isSolved)
	# Flatten testcases per model and technique
	dataMetric <- ddply(.parallel=TRUE, dataMetric, c("filename", technique), summarize, avgMetric = mean(metric))
	
	# Find best candidates
	dataBestMetric <- ddply(.parallel=TRUE, dataMetric, "filename", summarize, bestMetric = min(avgMetric))
	dataBest <- merge(dataMetric, dataBestMetric, "filename")
	dataBest <- subset(dataBest, avgMetric <= ((bestMetric*(100+relativeMargin))/100))
	
	# List all possible techniques; they make up the venn sets
	allTechniques <- unique(dataBest[,technique])
	allTechniques <- allTechniques[order(allTechniques$order, allTechniques$sat.granularity),]
	
	# Create id per model. The id corresponds to which techniques can solve the model
	dataModel <- data.frame(filename=unique(dataBest$filename), id="")

	for(tid in 1:nrow(allTechniques)){
		t <- allTechniques[tid,]
		# Check which models t can solve; dataTechnique = filename -> boolean
		dataTechnique <- dataBest
		dataTechnique$equals <- dataTechnique$order == t$order & dataTechnique$sat.granularity == t$sat.granularity
		dataTechnique <- ddply(.parallel=TRUE, dataTechnique, "filename", summarize, equals = any(equals))
		# Update dataModel
		dataModel <- merge(dataModel, dataTechnique, "filename")
		dataModel$id <- paste0(dataModel$id, ifelse(dataModel$equals, signSolvable, signUnsolvable))
		dataModel <- subset(dataModel, select=c("filename","id"))
	}
	
	print(paste0("VENNSETS ", m$header))
	print("")
	
	dataSummary <- ddply(.parallel=TRUE, dataBest, technique, summarize, frequency=length(filename))
	dataSummary  <- dataSummary [order(dataSummary$order, dataSummary$sat.granularity),]
	print("Overview times best per technique:")
	print(dataSummary)
	print("")
	print(paste("Total number of venn sets:", length(unique(dataModel$id))))
	print("")
	
	# Resolve venn sets
	for(vennSet in unique(dataModel$id)){
		# Show set
		dataSet <- allTechniques
		dataSet$number <- 1:nrow(dataSet)
		dataSet$isMember <- (substring(vennSet, dataSet$number, dataSet$number) == signSolvable)
		dataSet <- subset(dataSet, isMember)
		for(tid in 1:nrow(dataSet)){
			techniqueGroup <- dataSet[tid,]
			print(paste0(techniqueGroup$order,"-",techniqueGroup$sat.granularity))
		}
		# Show members
		members <- subset(dataModel, id == vennSet)
		for(mid in 1:nrow(members)){
			member <- members[mid,]
			print(paste0("   - ", member$filename))
		}
		print("")
	}
	print("")
	print("")
}