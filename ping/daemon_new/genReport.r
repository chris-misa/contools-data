#
# R script to parse data files, generate graphs, and dump a report
#
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
  timestamps <- c()
  rtts <- c()
  linePattern <- "\\[([0-9\\.]+)\\] .* time=([0-9\\.]+) ms"
  while (T) {
    line <- readLines(con, n=1)
    if (length(line) == 0) {
      break
    }
    matches <- grep(linePattern, line, value=T)

    ts <- as.numeric(sub(linePattern, "\\1", matches))
    rtt <- as.numeric(sub(linePattern, "\\2", matches)) * 1000

    timestamps <- c(timestamps, ts)
    rtts <- c(rtts, rtt)
  }
  close(con)
  data.frame(rtt=rtts, ts=timestamps)
}

#
# Read and parse a dump from ftrace-based latency tool
#
readLatencyFile <- function(filePath) {
  con <- file(filePath, "r")
  timestamps <- c()
  raws <- c()
  ohs <- c()
  linePattern <- "\\[([0-9\\.]+)\\] rtt raw_latency: ([0-9]+), events_overhead: ([0-9\\.]+),.*"
  while (T) {
    line <- readLines(con, n=1)
    if (length(line) == 0) {
      break
    }
    matches <- grep(linePattern, line, value=T)

    timestamp <- as.numeric(sub(linePattern, "\\1", matches))
    raw <- as.numeric(sub(linePattern, "\\2", matches))
    oh <- as.numeric(sub(linePattern, "\\3", matches))

    timestamps <- c(timestamps, timestamp)
    raws <- c(raws, raw)
    ohs <- c(ohs, oh)
  }

  close(con)
  data.frame(raw=raws, events_overhead=ohs, ts=timestamps)
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
# Function to subtract latency from container RTTs
#
adjustContainer <- function(container, latency) {
  adjs <- c()
  l <- 2
  lat_len <- length(latency$ts)
  for (i in 1:nrow(container)) {
    if (l < lat_len && container$ts[[i]] > latency$ts[[l]]) {
      l <- l + 1
    }
    if (abs(latency$ts[[l]] - container$ts[[i]])
        < abs(latency$ts[[l-1]] - container$ts[[i]])) {
      ave_lat <- latency$raw[[l]]
    } else {
      ave_lat <- latency$raw[[l-1]]
    }
    adj <- container$rtt[[i]] - ave_lat
    adjs <- c(adjs, adj)
  }
  data.frame(rtt=adjs, ts=container$ts)
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
  cat("  control num pings:  ", length(controlRTTs$rtt), "\n")
  cat("  container num pings:", length(containerRTTs$rtt), "\n")
  cat("  latency num pings:  ", length(raw_lat), "\n")

  controlMean <- mean(controlRTTs$rtt)
  controlSD <- sd(controlRTTs$rtt)
  containerMean <- mean(containerRTTs$rtt)
  containerSD <- sd(containerRTTs$rtt)
  raw_latMean <- mean(raw_lat)
  raw_latSD <- sd(raw_lat)
  events_overheadMean <- mean(events_overheads)
  events_overheadSD <- sd(events_overheads)

  containerAdjusted <- adjustContainer(containerRTTs, latencies)

  #
  # Generate time-sequences
  #
  pdf(file=paste(DATA_PATH,"seq_",iperf_arg,".pdf",sep=""), width=10, height=5)
  plot(containerRTTs$ts, containerRTTs$rtt, type="l", col="black",
    ylim=c(0,max(containerRTTs$rtt)), ylab="RTT (usec)",
    xlab="Sequence Number",
    main="Time Sequences")

  # Horizontal line at control mean because time sequences don't line up
  lines(c(min(containerRTTs$ts), max(containerRTTs$ts)),
        c(controlMean, controlMean),
        type="l", col="blue")

  lines(latencies$ts, latencies$raw, type="l", col="gray")

  lines(containerAdjusted$ts, containerAdjusted$rtt, type="l", col="red")


  #lines(containerRTTs$rtt - raw_lat - events_overheads, type="l", col="blue")
  #lines(controlRTTs$ts, controlRTTs$rtt, type="l", col="red")

  legend("topright", legend=c("container", "adjusted container", "raw latency", "control mean"),
                     col=c("black", "red", "gray", "blue"),
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

