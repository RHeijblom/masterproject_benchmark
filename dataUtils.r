#!/usr/bin/Rscript
.libPaths("/home/richard/Tools/R")
library(plyr)
library(reshape2)
library(scales)
library(doMC)

# Make sure we use all available CPUs
doMC::registerDoMC(cores=8)

MAXINT <- 2147483647 # Identifier of max granularity

removeCorruptEntries <- function(dfCsvEntries){
	dfResult <- dfCsvEntries
	# Corrupt models for sat-granularity=1
	corruptModels <- c("CircularTrain-","closed_system","database","echo-","HouseConstruction-",
					  "IBM319.pnml","IBM5964.pnml","IBMB2S565S3960.pnml","IOTP","open_system_0.pnml",
					  "ProductionCell.pnml","QCertifProtocol_","RAS-C","RAS-R-1","RAS-R-20.pmnl","RAS-R-3.pmnl",
					  "RAS-R-5","ring.pnml","rwmutex-r","SwimmingPool-")
	for(cmodel in corruptModels){
		dfResult <- subset(dfResult, sat.granularity!=1 | !grepl(cmodel, filename))
	}
	# Corrupt models for sat-granularity=5
	corruptModels <- c("QCertifProtocol_10-unfold.pnml","QCertifProtocol_18-unfold.pnml","QCertifProtocol_22-unfold.pnml",
					  "QCertifProtocol_28-unfold.pnml","QCertifProtocol_32-unfold.pnml")
	dfResult <- subset(dfResult, sat.granularity!=5 | !is.element(filename, corruptModels))
	return(dfResult)
}

fixSatGranularity <- function(dfCsvEntries){
	# Derive state_vector_length for models with at least one solved instance, otherwise set derivedSvl to NA.
	mapSvl <- ddply(.parallel=TRUE, dfCsvEntries, "filename", summarize, derivedSvl = mean(state.vector.length, na.rm=TRUE))
	# Add derived state.vector.length to data
	dfResult <- merge(dfCsvEntries, mapSvl, "filename")
	# Fix cases where sat.granularity is too high; may change testcases for a specific granularity to a multiple of 10 
	dfResult$sat.granularity <- ifelse(!is.na(dfResult$derivedSvl) & dfResult$sat.granularity >= dfResult$derivedSvl, MAXINT, dfResult$sat.granularity)
	# Remove derived svl
	dfResult <- dfResult[,names(dfCsvEntries)]
	return(dfResult)
}