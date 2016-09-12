#!/usr/bin/Rscript
.libPaths("/home/richard/Tools/R")
library(ggplot2)
library(plyr)
library(reshape2)
library(scales)
library(doMC)

# Make sure we use all available CPUs
doMC::registerDoMC(cores=8)

# Adds values satVal, satLabel and stratLabel to improve display of graphs
addGraphLabels <- function(perfData){
	# Values for saturation (most significant part)
	dfSat <- data.frame(saturation=c("sat-like","sat-loop","none"), satVal=c(10,20,30))
	perfData <- merge(perfData, dfSat, "saturation", all.x=TRUE)
	# Values for saturation (least significant part)
	dfGran <- data.frame(sat.granularity=c(1,5,10,20,40,80,2147483647), granVal=1:7)
	perfData <- merge(perfData, dfGran, "sat.granularity", all.x=TRUE)
	# Values for saturation
	perfData$satVal <- perfData$satVal + perfData$granVal
	# Label for saturation strategy
	perfData$satLabel <- ifelse(is.na(perfData$sat.granularity), paste0(perfData$saturation), paste0(perfData$saturation,"(",as.character(perfData$sat.granularity),")"))
	dfOrderChar <- data.frame(order=c("bfs","bfs-prev","chain","chain-prev"), char=c("b","bp","c","cp"))
	perfData <- merge(perfData, dfOrderChar, "order", all.x=TRUE)
	# Label for strategy
	perfData$stratLabel <- paste0(perfData$satLabel,"-",perfData$char)
	return(perfData)
}

# Creates dataframe group -> summary(group) out of data
summarizeDataByGroup <- function(data, group, value){
	dataSum <- data
	dataSum$summaryValue <- data[,value] 
	dataSum <- ddply(.parallel=TRUE, dataSum, group, summarize, 
				min=min(summaryValue),
				lowerQuantile=quantile(summaryValue)[2],
				median=median(summaryValue),
				mean=mean(summaryValue),
				upperQuantile=quantile(summaryValue)[4],
				max=max(summaryValue)
				)	
	return(dataSum)
}