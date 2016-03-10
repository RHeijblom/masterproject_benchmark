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

testCase <- c("order","sat.granularity")

# PERFORMANCE based on SPEED

# Metrics per model
metricId <- c("time","memory")
metricName <- c("Time","Memory")
metricUnity <- c("sec","KB")

inputDataPerformance <- subset(subset(inputData, status == "done" & type == "performance"), select=c("filename", testCase, metricId))

for(m in 1:length(metricId)){
	# Set metric
	metric <- metricId[m]
	name <- metricName[m]
	unity <- metricUnity[m]
	
	print(paste("Start generating", metric, "overview per model."))
	
	for(model in unique(inputDataPerformance$filename)){
		# Performance for model
		modelPerf <- subset(subset(inputDataPerformance, filename == model), select=c(testCase, metric))
		# Rename metric to "metric" so ddply will identify the right column
		names(modelPerf)[names(modelPerf)==metric] <- "metric"
		# Flatten metric
		modelOverview <- ddply(.parallel=TRUE, modelPerf, testCase, summarize, 
			mean = mean(metric, na.rm=TRUE),
			sd = sd(metric, na.rm=TRUE)
		)
		
		# Make diagram
		ggplot(modelOverview) + 
			# Data
			geom_line(aes(x=sat.granularity, y=mean, color=order)) +
			geom_errorbar(aes(x=sat.granularity, ymin=mean-sd, ymax=mean+sd, color=order), width=0.25) +
			# Aes
			labs(title=paste0("Performance ", model, " (", name, ")")) +
			xlab("Saturation granularity") +
			ylab(paste0(name, " (", unity, ")")) +
			scale_colour_discrete(name = "Exploration order")
		# Save diagram
		fileOut <- paste0("./Out/", name, "/", model, ".pdf")
		ggsave(fileOut, height=4, width=7)
	}
	
	print(paste("Finished generating", metric, "overview per model."))
}

# PERFORMANCE based on EFFICIENCY

metric <- "peak.nodes"
inputDataStats <- subset(subset(inputData, status == "done" & type == "statistics"), select=c("filename", testCase, metric))
	
print("Start generating peak nodes overview per model.")
	
for(model in unique(inputDataStats$filename)){
	# Efficiency for model
	modelEff <- subset(subset(inputDataStats, filename == model), select=c(testCase, metric))
	# Rename metric to "metric" for convenience
	names(modelEff)[names(modelEff)==metric] <- "metric"
	# Make diagram
	ggplot(modelEff) + 
		# Data
		geom_line(aes(x=sat.granularity, y=metric, color=order)) +
		geom_point(aes(x=sat.granularity, y=metric, color=order)) +
		# Aes
		labs(title=paste0("Efficiency ", model, " (Peak Nodes)")) +
		xlab("Saturation granularity") +
		ylab("# Nodes") +
		scale_colour_discrete(name = "Exploration order")
	# Save diagram
	fileOut <- paste0("./Out/Peaknodes/", model, ".pdf")
	ggsave(fileOut, height=4, width=7)
}
	
print("Finished generating peak nodes overview per model.")