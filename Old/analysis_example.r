#!/usr/bin/Rscript
library(ggplot2)
library(plyr)
library(reshape2)
library(scales)
library(data.table)
library(doMC)
options(warning=traceback)

doMC::registerDoMC(cores=8)

args <- commandArgs(trailingOnly = TRUE)

# READ INPUT DATA
input <- read.csv(file=args[1], sep=',', nargsa.strings=c(""), quote="\"")

input <- subset(input, status == "done" | status == "oot" | status == "oom")
input <- subset(input, regroup != "")

input$regroup <- gsub("sw,mm,sr,mm,sc,mm,?", "", input$regroup)
input$regroup <- gsub(",hf,vf,vf", ",hf", input$regroup)
input$regroup <- gsub("sw", "W", input$regroup)
input$regroup <- gsub("sc", "C", input$regroup)
input$regroup <- gsub("bg", "bi", input$regroup)
input$regroup <- gsub("tg", "tot", input$regroup)
input$regroup <- gsub("bs", "Sloan", input$regroup)
input$regroup <- gsub("vgps", "GPS", input$regroup)
input$regroup <- gsub("vacm", "aCM", input$regroup)
input$regroup <- gsub("bk", "K", input$regroup)
input$regroup <- gsub("bcm", "CMB", input$regroup)
input$regroup <- gsub("vcm", "CMV", input$regroup)
input$regroup <- gsub("cw,rs", "CS", input$regroup)
input$regroup <- gsub("vf", "vf", input$regroup)
input$regroup <- gsub("hf", "hf", input$regroup)
input$regroup[input$regroup == ""] <- "none"

input <- input[grep("none|W", input$regroup), ]

input$order <- ifelse(grepl("bi|tot", input$regroup), "total", "partial")
input$graph <- ifelse(grepl("tot", input$regroup), "total", "bipartite")

summary_f <- ddply(.parallel = TRUE, input, c(
				"type", "filename", "regroup","order","graph",
				"peak_nodes", 
				"write_event_span",
				"write_norm_event_span",
				"write_weighted_event_span", 
				"read_event_span",
				"read_norm_event_span",
				"read_weighted_event_span", 
				"combined_event_span",
				"combined_norm_event_span",
				"combined_weighted_event_span",
				"bandwidth",
				"profile",
				"span",
				"avg_wavefront",
				"RMS_wavefront"
				), summarize,
    # include some columns	
	N = sum(!is.na(reach_time)),		
    
    # summarize regrouping time    
#    N_regroup_time		= N,
    mean_regroup_time	= mean(regroup_time, na.rm = TRUE),
#    sd_rgt      = sd(rgt),
#    se_rgt      = sd_rgt / sqrt(N_rgt),

    # summarise reachability time
#    N_reach_time	= N,
    mean_reach_time = mean(reach_time, na.rm = TRUE),
#    sd_rt   = sd(rt),
#    se_rt   = sd_rt / sqrt(N_rt),
    
    # summarise memtime time
#    N_time     = N,
    mean_time  = mean(time, na.rm = TRUE),
#    sd_mt    = sd(mt),
#    se_mt    = sd_mt / sqrt(N_mt),
    
    # summarise memtime memory
#    N_RSS     = length(RSS),
    mean_RSS  = mean(RSS, na.rm = TRUE))
#    sd_mm    = sd(mm),
#    se_mm    = sd_mm / sqrt(N_mm))

perf <- subset(summary_f, type == "performance")
stat <- subset(summary_f, type == "statistics")

merged <- merge(perf, stat, by = c("filename", "regroup"))

merged$peak_nodes.x <- NULL

merged$write_event_span.x <- NULL
merged$write_norm_event_span.x <- NULL
merged$write_weighted_event_span.x <- NULL

merged$read_event_span.x <- NULL
merged$read_norm_event_span.x <- NULL
merged$read_weighted_event_span.x <- NULL

merged$combined_event_span.x <- NULL
merged$combined_norm_event_span.x <- NULL
merged$combined_weighted_event_span.x <- NULL

merged$bandwidth.x <- NULL
merged$profile.x <- NULL
merged$span.x <- NULL
merged$RMS_wavefront.x <- NULL
merged$avg_wavefront.x <- NULL

merged$order.x <- NULL
merged$graph.x <- NULL

completes <- ddply(merged, c("filename"), summarise, count = length(regroup[is.na(peak_nodes.y)]))

completes <- subset(completes, completes$count == 0)

merged <- subset(merged, merged$filename %in% unique(completes$filename))

print(paste0("number of used models: ", length(unique(completes$filename))))

mean_sd <- merged
mean_sd_graph <- mean_sd

mean_sd <- ddply(.parallel = TRUE, mean_sd, c("filename"), function(x) c(
					mean_regroup=mean(x$mean_regroup_time.x, na.rm = TRUE), 
					mean_reach=mean(x$mean_reach_time.x, na.rm = TRUE),
					mean_time=mean(x$mean_time.x, na.rm = TRUE),
					mean_peak=mean(x$peak_nodes.y, na.rm = TRUE),
					mean_write_event_span=mean(x$write_event_span.y, na.rm = TRUE),
					mean_write_norm_event_span=mean(x$write_norm_event_span.y, na.rm = TRUE),
					mean_write_weighted_event_span=mean(x$write_weighted_event_span.y, na.rm = TRUE),
					
					mean_read_event_span=mean(x$read_event_span.y, na.rm = TRUE),
					mean_read_norm_event_span=mean(x$read_norm_event_span.y, na.rm = TRUE),
					mean_read_weighted_event_span=mean(x$read_weighted_event_span.y, na.rm = TRUE),
					
					mean_combined_event_span=mean(x$combined_event_span.y, na.rm = TRUE),
					mean_combined_norm_event_span=mean(x$combined_norm_event_span.y, na.rm = TRUE),
					mean_combined_weighted_event_span=mean(x$combined_weighted_event_span.y, na.rm = TRUE),
					
					sd_regroup=sd(x$mean_regroup_time.x, na.rm = TRUE), 
					sd_reach=sd(x$mean_reach_time.x, na.rm = TRUE),
					sd_time=sd(x$mean_time.x, na.rm = TRUE),
					sd_peak=sd(x$peak_nodes.y, na.rm = TRUE),
					sd_write_event_span=sd(x$write_event_span.y, na.rm = TRUE),
					sd_write_norm_event_span=sd(x$write_norm_event_span.y, na.rm = TRUE),
					sd_write_weighted_event_span=sd(x$write_weighted_event_span.y, na.rm = TRUE),
					
					sd_read_event_span=sd(x$read_event_span.y, na.rm = TRUE),
					sd_read_norm_event_span=sd(x$read_norm_event_span.y, na.rm = TRUE),
					sd_read_weighted_event_span=sd(x$read_weighted_event_span.y, na.rm = TRUE),
					
					sd_combined_event_span=sd(x$combined_event_span.y, na.rm = TRUE),
					sd_combined_norm_event_span=sd(x$combined_norm_event_span.y, na.rm = TRUE),
					sd_combined_weighted_event_span=sd(x$combined_weighted_event_span.y, na.rm = TRUE)))

mean_sd_graph <- ddply(.parallel = TRUE, mean_sd_graph, c("filename","order.y","graph.y"), function(x) c(
					mean_bandwidth=mean(x$bandwidth.y, na.rm = TRUE),
					mean_profile=mean(x$profile.y, na.rm = TRUE),
					mean_span=mean(x$span.y, na.rm = TRUE),
					mean_avg_wavefront=mean(x$avg_wavefront.y, na.rm = TRUE),
					mean_RMS_wavefront=mean(x$RMS_wavefront.y, na.rm = TRUE),
					
					sd_bandwidth=sd(x$bandwidth.y, na.rm = TRUE),
					sd_profile=sd(x$profile.y, na.rm = TRUE),
					sd_span=sd(x$span.y, na.rm = TRUE),
					sd_avg_wavefront=sd(x$avg_wavefront.y, na.rm = TRUE),
					sd_RMS_wavefront=sd(x$RMS_wavefront.y, na.rm = TRUE)))

# some models are not interesting, because they compute the same number of peak nodes for al regroups
mean_sd <- subset(mean_sd, sd_peak > 0)
		
score <- merged[,c("regroup", "filename","order.y","graph.y",
				"mean_regroup_time.x", "mean_reach_time.x", "mean_time.x", 
				"peak_nodes.y",
				"write_event_span.y",
				"write_norm_event_span.y",
				"write_weighted_event_span.y",
				"read_event_span.y",
				"read_norm_event_span.y",
				"read_weighted_event_span.y",
				"combined_event_span.y",
				"combined_norm_event_span.y",
				"combined_weighted_event_span.y",
				
				"bandwidth.y",
				"profile.y",
				"span.y",
				"avg_wavefront.y",
				"RMS_wavefront.y")]

score <- merge(score, mean_sd, by = c("filename"))
score <- merge(score, mean_sd_graph, by = c("filename","order.y","graph.y"))

score <- ddply(.parallel = TRUE, score, "regroup", function (x) c(
					
					regroup_score=sum(ifelse(x$sd_regroup == 0, 0, (x$mean_regroup_time.x - x$mean_regroup) / x$sd_regroup)) / length(x$mean_regroup_time.x), 
					
					reach_score=sum((x$mean_reach_time.x - x$mean_reach) / x$sd_reach) / length(x$mean_reach_time.x), 
					time_score=sum((x$mean_time.x - x$mean_time) / x$mean_time) / length(x$mean_time.x), 
					
					peak_score=sum((x$peak_nodes.y - x$mean_peak) / x$sd_peak) / length(x$peak_nodes.y),
					
					write_event_span_score=sum((x$write_event_span.y - x$mean_write_event_span) / x$sd_write_event_span) / length(x$write_event_span.y),
					write_norm_event_span_score=sum((x$write_norm_event_span.y - x$mean_write_norm_event_span) / x$sd_write_norm_event_span) / length(x$write_norm_event_span.y),
					write_weighted_event_span_score=sum((x$write_weighted_event_span.y - x$mean_write_weighted_event_span) / x$sd_write_weighted_event_span) / length(x$write_weighted_event_span.y),
					
					read_event_span_score=sum((x$read_event_span.y - x$mean_read_event_span) / x$sd_read_event_span) / length(x$read_event_span.y),
					read_norm_event_span_score=sum((x$read_norm_event_span.y - x$mean_read_norm_event_span) / x$sd_read_norm_event_span) / length(x$read_norm_event_span.y),
					read_weighted_event_span_score=sum((x$read_weighted_event_span.y - x$mean_read_weighted_event_span) / x$sd_read_weighted_event_span) / length(x$read_weighted_event_span.y),
					
					combined_event_span_score=sum((x$combined_event_span.y - x$mean_combined_event_span) / x$sd_combined_event_span) / length(x$combined_event_span.y),
					combined_norm_event_span_score=sum((x$combined_norm_event_span.y - x$mean_combined_norm_event_span) / x$sd_combined_norm_event_span) / length(x$combined_norm_event_span.y),
					combined_weighted_event_span_score=sum((x$combined_weighted_event_span.y - x$mean_combined_weighted_event_span) / x$sd_combined_weighted_event_span) / length(x$combined_weighted_event_span.y),

					bandwidth_score=sum((x$bandwidth.y - x$mean_bandwidth) / x$sd_bandwidth) / length(x$bandwidth.y),
					profile_score=sum((x$profile.y - x$mean_profile) / x$sd_profile) / length(x$profile.y),
					span_score=sum((x$span.y - x$mean_span) / x$sd_span) / length(x$span.y),
					avg_wavefront_score=sum((x$avg_wavefront.y - x$mean_avg_wavefront) / x$sd_avg_wavefront) / length(x$avg_wavefront.y),
					RMS_wavefront_score=sum((x$RMS_wavefront.y - x$mean_RMS_wavefront) / x$sd_RMS_wavefront) / length(x$RMS_wavefront.y)))

score <- score[with(score, order(peak_score)),]

b <- c("peak_score", "regroup_score", "reach_score", "time_score")
l <- c("Peak nodes", "Reorder time", "Reach time", "Total time")

ggplot(score,aes(x=reorder(regroup, peak_score, function(x) x))) +
		geom_line(stat="identity", aes(y=peak_score, group=3, linetype="peak_score", color="peak_score")) +
		geom_point(aes(y=peak_score, shape="peak_score", color="peak_score")) +
		geom_line(stat="identity", aes(y=regroup_score, group=3, linetype="regroup_score", color="regroup_score")) +
		geom_point(aes(y=regroup_score, shape="regroup_score", color="regroup_score")) +
		geom_line(stat="identity", aes(y=reach_score, group=3, linetype="reach_score", color="reach_score")) +
		geom_point(aes(y=reach_score, shape="reach_score", color="reach_score")) +
		geom_line(stat="identity", aes(y=time_score, group=3, linetype="time_score", color="time_score")) +
		geom_point(aes(y=time_score, shape="time_score", color="time_score")) +
		xlab("Ordering strategy") +
		scale_y_continuous(name="Average total standard score") +
		theme_bw() +
		theme(text = element_text(size=10), axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1), legend.position="bottom", legend.title=element_blank(), legend.direction="horizontal") +
		scale_color_discrete(breaks=b, labels=l) +
		scale_shape_discrete(breaks=b, labels=l) +
		scale_linetype_discrete(breaks=b, labels=l)

ggsave("score.pdf", height=4, width=7)

b <- c("write_weighted_event_span_score",
		"write_event_span_score",
		"bandwidth_score", "profile_score",
		"span_score", "avg_wavefront_score")
l <- c("Write WES", "Write ES", "Bandwidth", "Profile", "Span", "Avg wavefront")

ggplot(score,aes(x=reorder(regroup, peak_score, function(x) x))) +
		geom_line(stat="identity", aes(y=write_weighted_event_span_score, group=3, linetype="write_weighted_event_span_score", color="write_weighted_event_span_score")) +
		geom_point(aes(y=write_weighted_event_span_score, shape="write_weighted_event_span_score", color="write_weighted_event_span_score")) +
		
		geom_line(stat="identity", aes(y=write_event_span_score, group=3, linetype="write_event_span_score", color="write_event_span_score")) +
		geom_point(aes(y=write_event_span_score, shape="write_event_span_score", color="write_event_span_score")) +
		
		geom_line(stat="identity", aes(y=bandwidth_score, group=3, linetype="bandwidth_score", color="bandwidth_score")) +
		geom_point(aes(y=bandwidth_score, shape="bandwidth_score", color="bandwidth_score")) +
		
		geom_line(stat="identity", aes(y=profile_score, group=3, linetype="profile_score", color="profile_score")) +
		geom_point(aes(y=profile_score, shape="profile_score", color="profile_score")) +
		
		geom_line(stat="identity", aes(y=span_score, group=3, linetype="span_score", color="span_score")) +
		geom_point(aes(y=span_score, shape="span_score", color="span_score")) +
		
		geom_line(stat="identity", aes(y=avg_wavefront_score, group=3, linetype="avg_wavefront_score", color="avg_wavefront_score")) +
		geom_point(aes(y=avg_wavefront_score, shape="avg_wavefront_score", color="avg_wavefront_score")) +
				
		xlab("Ordering strategy") +
		scale_y_continuous(name="Average total standard score") +
		theme_bw() +
		theme(text = element_text(size=10), axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1), legend.position="bottom", legend.title=element_blank(), legend.direction="horizontal") +
		scale_color_discrete(breaks=b, labels=l) +
		scale_shape_discrete(breaks=b, labels=l) +
		scale_linetype_discrete(breaks=b, labels=l)

ggsave("metrics.pdf", height=4, width=7)
