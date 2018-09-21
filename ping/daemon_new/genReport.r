#IPERF_SETTINGS <- c("1M", "10M", "100M", "1G", "10G")

args <- commandArgs(trailingOnly=T)
USAGE <- "Rscript genReport.r <path to data folder>"

if (length(args) != 1) {
  stop(USAGE)
}

DATA_PATH <- args[1]
TARGET <- "10.10.1.2"
IPERF_SETTINGS <- scan(file=paste(DATA_PATH,"file_list",sep=""),
                       what=character(),
                       sep="\n")

print(IPERF_SETTINGS)

#
# Read and parse a dump from ping
#
readPingFile <- function(filePath) {
  con <- file(filePath, "r")
  rtts <- c()
  while (T) {
    line <- readLines(con, n=1)
    if (length(line) == 0) {
      break
    }
    time_str <- strsplit(line, "time=")[[1]]
    if (length(time_str) == 2) {
      # Convert to usec
      time <- 1000 * as.numeric(strsplit(time_str[[2]], " ms")[[1]])
      rtts <- c(rtts, time)
    }
  }
  close(con)
  rtts
}

#
# Read and parse a dump from ftrace-based latency tool
#
readLatencyFile <- function(filePath) {
  con <- file(filePath, "r")
  raws <- c()
  ohs <- c()
  while (T) {
    line <- readLines(con, n=1)
    if (length(line) == 0) {
      break
    }
    break1 <- strsplit(line, "rtt raw_latency: ")[[1]]
    if (length(break1) == 2) {
      break2 <- strsplit(break1[[2]], ", events_overhead: ")[[1]]
      raw_latency <- as.numeric(break2[[1]])
      raws <- c(raws, raw_latency)
      break3 <- strsplit(break2[[2]], ", adj_latency: ")[[1]]
      if (length(break3) == 2) {
        events_overhead <- as.numeric(break3[[1]])
        ohs <- c(ohs, events_overhead)
      }
    }
  }
  close(con)
  data.frame(raw=raws, events_overhead=ohs)
}

#
# Work around to draw intervals around
# points in graph
#
drawArrows <- function(ys, sds, color) {
  arrows(seq(1, length(ys), by=1), ys - sds,
         seq(1, length(ys), by=1), ys + sds,
         length=0.05, angle=90, code=3, col=color)
}

#
# collect means and deviations
#
controlMeans <- c()
controlSDs <- c()
containerMeans <-c()
containerSDs <- c()
raw_latMeans <- c()
raw_latSDs <- c()
events_overheadMeans <- c()
events_overheadSDs <- c()
for (iperf_arg in IPERF_SETTINGS) {
  controlRTTs <- readPingFile(paste(DATA_PATH,
                                    "native_control_",
                                      TARGET,
                                      "_",
                                      iperf_arg, 
                                      ".ping",
                                      sep = ""))
  containerRTTs <- readPingFile(paste(DATA_PATH,
                                      "container_monitored_",
                                      TARGET,
                                      "_",
                                      iperf_arg, 
                                      ".ping",
                                      sep = ""))
  latencies <- readLatencyFile(paste(DATA_PATH,
                                      "container_monitored_",
                                      TARGET,
                                      "_",
                                      iperf_arg, 
                                      ".latency",
                                      sep = ""))
  raw_lat <- latencies$raw
  events_overheads <- latencies$events_overhead

  cat(iperf_arg,":\n",sep="")
  cat("  control num pings:  ", length(controlRTTs), "\n")
  cat("  container num pings:", length(containerRTTs), "\n")
  cat("  latency num pings:  ", length(raw_lat), "\n")

  controlMean <- mean(controlRTTs)
  controlSD <- sd(controlRTTs)
  containerMean <- mean(containerRTTs)
  containerSD <- sd(containerRTTs)
  raw_latMean <- mean(raw_lat)
  raw_latSD <- sd(raw_lat)
  events_overheadMean <- mean(events_overheads)
  events_overheadSD <- sd(events_overheads)

  #
  # Generate time-sequences
  #
  pdf(file=paste(DATA_PATH,"seq_",iperf_arg,".pdf",sep=""), width=10, height=5)
  plot(containerRTTs, type="l", col="black",
    ylim=c(0,max(containerRTTs)), ylab="RTT (usec)",
    xlab="Sequence Number",
    main="Time Sequences")
  lines(containerRTTs - raw_lat - events_overheads, type="l", col="blue")
  lines(controlRTTs, type="l", col="red")
  # lines(rep(controlMean, length(containerRTTs)), type="l", col="red")
  legend("topright", legend=c("container", "container adjusted", "control"),
                     col=c("black", "blue", "red"),
                     lty=1, cex=0.8)
  dev.off()

  controlMeans <- c(controlMeans, controlMean)
  controlSDs <- c(controlSDs, controlSD)
  containerMeans <- c(containerMeans, containerMean)
  containerSDs <- c(containerSDs, containerSD)
  raw_latMeans <- c(raw_latMeans, raw_latMean)
  raw_latSDs <- c(raw_latSDs, raw_latSD)
  events_overheadMeans <- c(events_overheadMeans, events_overheadMean)
  events_overheadSDs <- c(events_overheadSDs, events_overheadSD)

  # cat("traffic: ", iperf_arg,
  #     " control RTT: ", mean(controlRTTs), " (", sd(controlRTTs), ") ",
  #     " container RTT: ", mean(containerRTTs), " (", sd(containerRTTs), ")",
  #     " RTT latency: ", mean(raw_lat), " (", sd(raw_lat), ") ",
  #     "\n",
  #     sep="")
}

#
# Make and display a data frame
#
data <- data.frame(arg=IPERF_SETTINGS,
                   control_mean=controlMeans,
                   control_sd=controlSDs,
                   container_mean=containerMeans,
                   container_sd=containerSDs,
                   raw_latency_mean=raw_latMeans,
                   raw_latency_sd=raw_latSDs,
                   events_overhead_mean=events_overheadMeans,
                   events_overhead_sd=events_overheadSDs,
                   stringsAsFactors=F)
data

#
# Generate graph of rtt measurements vs. traffic load
#
yBounds <- c(0,max(data$control_mean, data$container_mean))
pdf(file=paste(DATA_PATH,"rtts.pdf",sep=""), width=5, height=5)
plot(data$control_mean, type="b", ylim=yBounds, col="gray",
     main="RTT", xlab="traffic bandwidth", ylab="usec",
     xaxt="n")
drawArrows(data$control_mean, data$control_sd, "gray")
lines(data$container_mean, type="b", col="black")
drawArrows(data$container_mean, data$container_sd, "black")
lines(data$container_mean - data$raw_latency_mean, type="b", col="red")
lines(data$container_mean - data$raw_latency_mean - data$events_overhead_mean, type="b", col="blue")
axis(1, at=seq(1,length(data$arg),by=1), labels=data$arg)
legend("bottomright", legend=c("control", "container", "cont. raw adj", "cont. event adj"),
                   col=c("gray", "black", "red", "blue"),
                   lty=1, cex=0.8)
dev.off()

