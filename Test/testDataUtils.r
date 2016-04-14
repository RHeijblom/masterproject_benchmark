#!/usr/bin/Rscript
source("./dataUtils.r")

csv <- read.csv("./sampleTDU.csv")
csv <- subset(csv, select=c("filename","sat.granularity","state.vector.length"))
print("SAMPLE DATA:")
print(csv)
print("")


print("AFTER REMOVING CORRUPT DATA:")
csv <- removeCorruptEntries(csv)
print(csv)
print("")

print("AFTER SAT GRANULARITY FIX:")
csv <- fixSatGranularity(csv)
print(csv)