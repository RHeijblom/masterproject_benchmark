#!/usr/bin/Rscript
.libPaths("/home/richard/Tools/R")
library(plyr)
library(reshape2)
library(doMC)

# Make sure we use all available CPUs
doMC::registerDoMC(cores=8)

# Read file
args <- commandArgs(trailingOnly = TRUE)
inputData <- read.csv(file=args[1], sep=',', quote="\"")
print("Data read...")

# 1st filter: remove all models were all results are wrong.

print(paste("Different models before:",nrow(ddply(.parallel=TRUE, inputData, "filename", summarize, freq = length(filename)))))

allCorrupt <- c("afcs_04_b","afcs_05_b","afcs_06_b"
			   ,"CircularTrain-384","CircularTrain-768"
			   ,"database10UNFOLD","database20UNFOLD","database40UNFOLD"
			   ,"des_00_b","des_01_b","des_02_b","des_05_a","des_05_b"
			   ,"des_10_a","des_10_b","des_20_a","des_20_b","des_30_a","des_30_b","des_40_a","des_40_b","des_50_a","des_50_b","des_60_a","des_60_b"
			   ,"echo-d2r9","echo-d2r11","echo-d2r15","echo-d2r19","echo-d3r3","echo-d3r5","echo-d3r7","echo-d4r3","echo-d5r3"
			   ,"G-PPP-1-10000","G-PPP-1-100000"
			   ,"IOTP_c12m10p15d17"
			   ,"QCertifProtocol_10-unfold","QCertifProtocol_18-unfold","QCertifProtocol_22-unfold","QCertifProtocol_28-unfold","QCertifProtocol_32-unfold"
			   ,"rwmutex-r100w10","rwmutex-r500w10","rwmutex-r1000w10","rwmutex-r2000w10"
			   ,"sokoban.3"
			   ,"SwimmingPool-5","SwimmingPool-6","SwimmingPool-7","SwimmingPool-8","SwimmingPool-9","SwimmingPool-10"
			   ,"trg_2-01-1","trg_3-01-1","trg_3-02-6","trg_4-02-2","trg_5-02-0","trg_5-04-6")

for(cmodel in allCorrupt){
	inputData <- subset(inputData, filename != cmodel)
}

print("Corrupt models removed...")
print(paste("Different models after: ",nrow(ddply(.parallel=TRUE, inputData, "filename", summarize, freq = length(filename)))))
print("----------------------------------------------------------------------------------")

# 2nd filter: remove all models were statespace is too small

print(paste("Entries remaining before:", nrow(inputData)))

inputData <- subset(inputData, is.na(statespace.states) | statespace.states >= 8)
print("Small statespaces removed...")

print(paste("Entries remaining after: ", nrow(inputData)))
print("----------------------------------------------------------------------------------")

# Optional 3rd filter: remove all models which cannot be solved

print(paste("Different models before:",nrow(ddply(.parallel=TRUE, inputData, "filename", summarize, freq = length(filename)))))
print(paste("Entries remaining before:", nrow(inputData)))

nCols <- ncol(inputData)
# Defines which testrun were solved
inputData$isSolved <- inputData$status == "done"
# Defines which models can be solved
solvedData <- ddply(.parallel=TRUE, inputData, "filename", summarize, isSolvable = any(isSolved))
# Remove unsolvable models
inputData <- merge(inputData, solvedData, "filename");
inputData <- subset(inputData, isSolvable)
# Remove temporary data (isSolved and isSolvable)
inputData <- inputData[,1:nCols]

print("Unsolvable models removed...")
print(paste("Different models after: ",nrow(ddply(.parallel=TRUE, inputData, "filename", summarize, freq = length(filename)))))
print(paste("Entries remaining after: ", nrow(inputData)))
print("----------------------------------------------------------------------------------")

# 4th filter: select best entry from multiple conflicting entries using voting

print(paste("Entries remaining before:", nrow(inputData)))

nCols <- ncol(inputData)
voteData <- ddply(.parallel=TRUE, inputData, c("filename","statespace.states"), summarize, vote = length(filename))
voteData <- subset(voteData, !is.na(statespace.states))
maxVoteData <- ddply(.parallel=TRUE, voteData, "filename", summarize, maxvote = max(vote))

voteData <- merge(voteData, maxVoteData, "filename")
inputData <- merge(inputData, voteData, c("filename","statespace.states"), all.x=TRUE)
inputData <- subset(inputData, is.na(statespace.states) | vote == maxvote)
# Remove voting from inputData
inputData <- inputData[,1:nCols]
					
print("Minor conflicting entries removed...")
print(paste("Entries remaining after: ", nrow(inputData)))
print("----------------------------------------------------------------------------------")

# Optional 5th filter: only keep done entries:

#print(paste("Entries remaining before:", nrow(inputData)))
#inputData <- subset(inputData, status == "done")
#print("Non finished entries removed...")
#print(paste("Entries remaining after: ", nrow(inputData)))
#print("----------------------------------------------------------------------------------")

# Write output to file

outputData <- inputData
# Prevent that large numbers are converted to Inf
outputData$statespace.states <- as.character(outputData$statespace.states)
# Order data
outputData <- outputData[order(outputData$filename),]
# Write compressed data
write.table(outputData, file=args[2], sep=',', quote=TRUE ,row.names=FALSE,na="")
print("Data succesfully saved...")

