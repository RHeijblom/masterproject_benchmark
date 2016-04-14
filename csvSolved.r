#!/usr/bin/Rscript
.libPaths("/home/richard/Tools/R")
library(ggplot2)
library(plyr)
library(reshape2)
library(scales)
library(VennDiagram)
library(doMC)

# Make sure we use all available CPUs
doMC::registerDoMC(cores=8)

# HELPER FUNCTIONS

vennSets <- read.csv("./orderIndex.csv",sep=',', quote="\"")

# Makes the different entries for order columns
# dfSolvable: filename X order -> Boolean (solved)
# out: filename -> Boolean⁴ (bfs, bfsprev, chain, chainprev)
rankOrders <- function(dfSolvable){
	colName <- c("bfs","bfsprev","chain","chainprev")
	entryName <- c("bfs","bfs-prev","chain","chain-prev")
	dataResult <- data.frame(filename=unique(dfSolvable$filename))
	for(i in 1:length(colName)){
		# Select entry for specific order and add it as column to dataResult
		column <- colName[i]
		entry <- entryName[i]
		dataOrder <- subset(dfSolvable, order==entry)
		dataOrder <- subset(dataOrder, select=c("filename","solved"))
		# Rename new column to a more suitable name
		names(dataOrder)[names(dataOrder)=="solved"] <- column
		dataResult <- merge(dataResult, dataOrder, "filename")
	}
	return(dataResult)
}

# dfSolvable: filename -> Boolean⁴ (bfs, bfsprev, chain, chainprev)
listPerCategory <- function(dfSolvable){
	for(row in 1:nrow(vennSets)){
		entry <- vennSets[row,]
		dfMatches <- subset(dfSolvable, entry$bfs == bfs & entry$bfsprev == bfsprev & entry$chain == chain & entry$chainprev == chainprev)
		if(nrow(dfMatches) > 0){
			print(paste0(entry$category," (",nrow(dfMatches)," entries):"))
			for(modelNr in 1:nrow(dfMatches)){
				print(paste0("   ",dfMatches[modelNr,]$filename))
			}
			print("");
		}
	}
}

# dfSolvable: filename -> Boolean⁴ (bfs, bfsprev, chain, chainprev)
drawVenn <- function(dfSolvable, file){
	# 1 = BFS
	# 2 = Chain
	# 3 = BFS-PREV
	# 4 = Chain-PREV
	n1 <- sum(dfSolvable$bfs)
	n2 <- sum(dfSolvable$chain)
	n3 <- sum(dfSolvable$bfsprev)
	n4 <- sum(dfSolvable$chainprev)
	n12 <- sum(dfSolvable$bfs & dfSolvable$chain)
	n13 <- sum(dfSolvable$bfs & dfSolvable$bfsprev)
	n14 <- sum(dfSolvable$bfs & dfSolvable$chainprev)
	n23 <- sum(dfSolvable$chain & dfSolvable$bfsprev)
	n24 <- sum(dfSolvable$chain & dfSolvable$chainprev)
	n34 <- sum(dfSolvable$bfsprev & dfSolvable$chainprev)
	n123 <- sum(dfSolvable$bfs & dfSolvable$chain & dfSolvable$bfsprev)
	n124 <- sum(dfSolvable$bfs & dfSolvable$chain & dfSolvable$chainprev)
	n134 <- sum(dfSolvable$bfs & dfSolvable$bfsprev & dfSolvable$chainprev)
	n234 <- sum(dfSolvable$chain & dfSolvable$bfsprev & dfSolvable$chainprev)
	n1234 <- sum(dfSolvable$bfs & dfSolvable$bfsprev & dfSolvable$chain & dfSolvable$chainprev)
	colRed <- "#F8766D"
	colGreen <- "#7CAE00"
	colBlue <- "#00BFC4"
	colPurple <- "#C77CFF"
	colArea <- c(colRed,colBlue,colGreen,colPurple)
	colLine <- c(colRed,colGreen,colPurple,colBlue)
	names <- c("bfs","chain","bfs-prev","chain-prev")
	# draw diagram
	diagram <- draw.quad.venn(area1=n1,area2=n2,area3=n3,area4=n4,
				   n12=n12,n13=n13,n14=n14,n23=n23,n24=n24,n34=n34,
				   n123=n123,n124=n124,n134=n134,n234=n234,
				   n1234=n1234,
				   fill=colArea,
				   col=colLine,
				   category=names,euler.d=TRUE,scaled=TRUE)
	# save diagram
	pdf(file, width=7, height=6)
	grid.draw(diagram)
	dev.off()
}


# START SCRIPT

# Read input from csv
args <- commandArgs(trailingOnly = TRUE)
inputData <- read.csv(file=args[1], sep=',', quote="\"")
source("./dataUtils.r")
inputData <- removeCorruptEntries(inputData)
inputData <- fixSatGranularity(inputData)

# Remove statistics data and irrelevant columns
data <- subset(inputData, type=="performance")
data <- subset(data, select=c("filename","order","sat.granularity","status"))
# Abstract status
data$solved <- data$status == "done"
# Flatten models
data <- ddply(.parallel=TRUE, data, c("filename","order","sat.granularity"), summarize, totalSolved = sum(solved))
# Abstract whether a model can be solved
acceptRate <- 5 # Minimum number of models which have to be solved (currently 5/10)
data$solved <- data$totalSolved >= acceptRate
data <- subset(data, select=c("filename","order","sat.granularity","solved"))
# data: filename X order X sat.granularity -> Boolean (solved)

# Solved by any granularity
dataAny <- ddply(.parallel=TRUE, data, c("filename","order"), summarize, solved = sum(solved) >= 1)
dataAnySplit <- rankOrders(dataAny)
drawVenn(dataAnySplit,"./Out/Venn Diagram - Solved any granularity.pdf")
listPerCategory(dataAnySplit)

# Solved per granularity
dataFreq <- ddply(.parallet=TRUE, data, c("order","sat.granularity"), summarize, frequency=sum(solved))
ggplot(dataFreq) + 
	# Data
	geom_line(aes(x=sat.granularity, y=frequency, color=order)) +
	# Aes
	labs(title="Performance Overview") +
	xlab("Saturation granularity") +
	ylab("# Solved models") +
    scale_colour_discrete(name = "Exploration order")

ggsave("./Out/Solved.pdf", height=4, width=7)

# Solved for a specific granularity
for(gran in unique(data$sat.granularity)){
	dataGran <- subset(data, sat.granularity == gran)
	dataGranSplit <- rankOrders(dataGran)
	drawVenn(dataGranSplit, paste0("./Out/Venn Diagram - Solved granularity = ",gran,".pdf"))
	print(paste0("GRANULARITY = ",gran))
	print("")
	listPerCategory(dataGranSplit)
}

# Distinguish granularity dependent and independent models (aka dynamic and static models)
print("")
print("OVERVIEW COMBINING ALL GRANULARITIES")
print("")

# Determine static models
randomGran <- data$sat.granularity[1]
dataStatic <- rankOrders(subset(data, sat.granularity == randomGran))
dataStatic$isStatic <- TRUE

for(gran in unique(data$sat.granularity)){
	print(gran)
	dataGran <- rankOrders(subset(data, sat.granularity == gran))
	dataStatic$isStatic <- dataStatic$isStatic & dataStatic$bfs == dataGran$bfs & dataStatic$bfsprev == dataGran$bfsprev & dataStatic$chain == dataGran$chain & dataStatic$chainprev == dataGran$chainprev
}

dataDynamic <- merge(data, dataStatic, c("filename"))

# Display static models
dataStatic <- subset(dataStatic, isStatic)
print(paste0("STATIC MODELS (",nrow(dataStatic)," entries):"))
print("")
listPerCategory(dataStatic)

# Analyze dynamic models
dataDynamic <- subset(dataDynamic, !isStatic)

# Display set per granularity
print(paste0("DYNAMIC MODELS (",length(unique(dataDynamic$filename))," entries):"))
print("")
for(gran in unique(dataDynamic$sat.granularity)){
	dataGran <- subset(dataDynamic, sat.granularity == gran)
	dataGranSplit <- rankOrders(dataGran)
	print(paste0("GRANULARITY = ",gran))
	print("")
	listPerCategory(dataGranSplit)
}
