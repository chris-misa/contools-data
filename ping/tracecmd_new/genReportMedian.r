#
# R script to parse data files, generate graphs, and dump a report
#

confidence <- 0.90


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
  if (lat_len <= 2) {
    print("adjustContainer: not enough latencies, not-adjusting")
    container
  } else {
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
}

#
# Computes the max of distribution
#
getMaxDist <- function(df) {
  df$mids[which.max(df$counts)]
}

#
# collect means and deviations
#
controlMeans <- c()
controlSDs <- c()
containerControlMeans <- c()
containerControlSDs <- c()
containerMeans <-c()
containerSDs <- c()
raw_latMeans <- c()
raw_latSDs <- c()
events_overheadMeans <- c()
events_overheadSDs <- c()
nativeMonitoredMeans <- c()
nativeMonitoredSDs <- c()
containerAdjMeans <- c()
containerAdjSDs <- c()
ns <- c()

for (iperf_arg in IPERF_SETTINGS) {
  controlRTTs <- readPingFile(paste(DATA_PATH,
                                    "native_control_",
                                      TARGET,
                                      "_",
                                      iperf_arg, 
                                      ".ping",
                                      sep = ""))
  containerControlRTTs <- readPingFile(paste(DATA_PATH,
                                    "container_control_",
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

  nativeMonitoredPath <- paste(DATA_PATH,
                               "native_monitored_",
                               TARGET,
                               "_",
                               iperf_arg,
                               ".ping",
                               sep = "")
  if (file.exists(nativeMonitoredPath)) {
    nativeMonitoredRTTs <- readPingFile(nativeMonitoredPath)
  } else {
    nativeMonitoredRTTs <- NULL
  }

  raw_lat <- latencies$raw
  events_overheads <- latencies$events_overhead

  cat(iperf_arg,":\n",sep="")
  cat("  control num pings:          ", length(controlRTTs$rtt), "\n")
  cat("  container control num pings:", length(containerControlRTTs$rtt), "\n")
  cat("  container num pings:        ", length(containerRTTs$rtt), "\n")
  cat("  latency num pings:          ", length(raw_lat), "\n")

  containerAdjusted <- adjustContainer(containerRTTs, latencies)

  #
  # Generate histogram
  #
  xBnd <- range(controlRTTs$rtt,
                containerRTTs$rtt,
                nativeMonitoredRTTs$rtt,
                containerAdjusted$rtt)
  mBreaks <- seq(xBnd[[1]],xBnd[[2]],1)
  pdf(file=paste(DATA_PATH,"hist_",iperf_arg,".pdf",sep=""), width=10,height=5)
  controlRTTHist <- hist(controlRTTs$rtt, breaks=mBreaks, plot=F)
  containerRTTHist <- hist(containerRTTs$rtt, breaks=mBreaks, plot=F)
  nativeMonitoredHist <- hist(nativeMonitoredRTTs$rtt, breaks=mBreaks, plot=F)
  containerAdjustedHist <- hist(containerAdjusted$rtt, breaks=mBreaks, plot=F)
  yMax <- max(controlRTTHist$counts,
              containerRTTHist$counts,
              nativeMonitoredHist$counts,
              containerAdjustedHist$counts)
  plot(xBnd, c(0,yMax), type="n")
  lines(mBreaks[-1], controlRTTHist$counts, type="l", col="green")
  lines(mBreaks[-1], containerRTTHist$counts, type="l", col="black")
  lines(mBreaks[-1], nativeMonitoredHist$counts, type="l", col="blue")
  lines(mBreaks[-1], containerAdjustedHist$counts, type="l", col="red")
  dev.off()

  controlMean <- getMaxDist(controlRTTHist)
  controlSD <- sd(controlRTTs$rtt)
  containerControlMean <- median(containerControlRTTs$rtt)
  containerControlSD <- sd(containerControlRTTs$rtt)
  containerMean <- getMaxDist(containerRTTHist)
  containerSD <- sd(containerRTTs$rtt)
  raw_latMean <- median(raw_lat)
  raw_latSD <- sd(raw_lat)
  events_overheadMean <- median(events_overheads)
  events_overheadSD <- sd(events_overheads)
  if (!is.null(nativeMonitoredRTTs)) {
    nativeMonitoredMean <- getMaxDist(nativeMonitoredHist)
    nativeMonitoredSD <- sd(nativeMonitoredRTTs$rtt)
  } else {
    nativeMonitoredMean <- 0
    nativeMonitoredSD <- 0
  }

  controlMeans <- c(controlMeans, controlMean)
  controlSDs <- c(controlSDs, controlSD)
  containerControlMeans <- c(containerControlMeans, containerControlMean)
  containerControlSDs <-   c(containerControlSDs,   containerControlSD)
  containerMeans <- c(containerMeans, containerMean)
  containerSDs <- c(containerSDs, containerSD)
  raw_latMeans <- c(raw_latMeans, raw_latMean)
  raw_latSDs <- c(raw_latSDs, raw_latSD)
  events_overheadMeans <- c(events_overheadMeans, events_overheadMean)
  events_overheadSDs <- c(events_overheadSDs, events_overheadSD)
  nativeMonitoredMeans <- c(nativeMonitoredMeans, nativeMonitoredMean)
  nativeMonitoredSDs <- c(nativeMonitoredSDs, nativeMonitoredSD)
  containerAdjMeans <- c(containerAdjMeans, getMaxDist(containerAdjustedHist))
  containerAdjSDs <- c(containerAdjSDs, sd(containerAdjusted$rtt))
  ns <- c(ns, min(controlRTTs$rtt, containerControlRTTs$rtt, raw_lat))

  #
  # Generate time-sequences
  #
  pdf(file=paste(DATA_PATH,"seq_",iperf_arg,".pdf",sep=""), width=10, height=5)
  plot(containerRTTs$ts, containerRTTs$rtt, type="l", col="black",
    ylim=c(0,max(containerRTTs$rtt)), ylab="RTT (usec)",
    xlab="Sequence Number",
    main="Time Sequences")

  # Draw contemporaneous native pings if present, else fall back to a line
  # on the previous native control mean. . .
  if (!is.null(nativeMonitoredRTTs)) {
    lines(nativeMonitoredRTTs$ts, nativeMonitoredRTTs$rtt, type="l", col="blue")
  } else {
    # Horizontal line at control mean because time sequences don't line up
    lines(c(min(containerRTTs$ts), max(containerRTTs$ts)),
          c(controlMean, controlMean),
          type="l", col="blue")
  }

  lines(latencies$ts, latencies$raw, type="l", col="green")

  lines(containerAdjusted$ts, containerAdjusted$rtt, type="l", col="red")


  #lines(containerRTTs$rtt - raw_lat - events_overheads, type="l", col="blue")
  #lines(controlRTTs$ts, controlRTTs$rtt, type="l", col="red")

  legend("topright", legend=c("container", "adjusted container", "raw latency", "native"),
                     col=c("black", "red", "green", "blue"),
                     lty=1, cex=0.8)
  dev.off()

}

#
# Compute confidence intervals
#
a <- confidence + 0.5 * (1.0 - confidence)
n <- mean(ns)
t_an <- qt(a, df=n-1)
controlErrors <- t_an * controlSDs / sqrt(length(controlMeans))
containerControlErrors <- t_an * containerControlSDs / sqrt(length(containerControlMeans))
containerErrors <- t_an * containerSDs / sqrt(length(containerMeans))
containerAdjErrors <- t_an * containerAdjSDs / sqrt(length(containerAdjMeans))
nativeMonitoredErrors <- t_an * nativeMonitoredSDs / sqrt(length(nativeMonitoredMeans))

#
# Make and display a data frame
#
data <- data.frame(arg=IPERF_SETTINGS,
                   control_mean=controlMeans,
                   control_sd=controlSDs,
                   control_err=controlErrors,
                   container_control_mean=containerControlMeans,
                   container_control_sd=containerControlSDs,
                   container_control_err=containerControlErrors,
                   container_mean=containerMeans,
                   container_sd=containerSDs,
                   container_err=containerErrors,
                   raw_latency_mean=raw_latMeans,
                   raw_latency_sd=raw_latSDs,
                   native_monitored_mean=nativeMonitoredMeans,
                   native_monitored_sd=nativeMonitoredSDs,
                   native_monitored_err=nativeMonitoredErrors,
                   container_adj_mean=containerAdjMeans,
                   container_adj_sd=containerAdjSDs,
                   container_adj_err=containerAdjErrors,
                   stringsAsFactors=F)

write.csv(data, file=paste(DATA_PATH, "Report_mode.csv", sep=""))

#
# Generate graph of rtt measurements vs. traffic load
#
yBounds <- c(min(data$control_mean - data$control_err,
                 data$container_mean - data$container_err,
                 data$container_control_mean - data$container_control_err,
                 data$container_adj_mean - data$container_adj_err),
               max(data$control_mean + data$control_err,
                   data$container_mean + data$container_err,
                   data$container_control_mean + data$container_control_err,
                   data$container_adj_mean + data$container_adj_err))
pdf(file=paste(DATA_PATH,"rtts_median.pdf",sep=""), width=5, height=5)
plot(data$control_mean, type="b", ylim=yBounds, col="green",
     main="RTT Mode", xlab="traffic bandwidth", ylab="usec",
     xaxt="n",
     lty=3)
drawArrows(data$control_mean, data$control_err, "green")
if (!is.null(data$native_monitored_mean[[1]])) {
  lines(data$native_monitored_mean, type="b", col="blue", lty=2)
  drawArrows(data$native_monitored_mean, data$native_monitored_err, "blue")
}
lines(data$container_mean, type="b", col="black", lty=1)
drawArrows(data$container_mean, data$container_err, "black")

lines(data$container_control_mean, type="b", col="purple", lty=3)
drawArrows(data$container_control_mean, data$container_control_err, "purple")

lines(data$container_adj_mean, type="b", col="red", lty=1)
drawArrows(data$container_adj_mean, data$container_adj_err, "red")

axis(1, at=seq(1,length(data$arg),by=1), labels=data$arg)
legend("topleft", legend=c("container", "container adjusted", "native control", "un-monitored native", "un-monitored container"),
                   col=c("black", "red", "blue", "green", "purple"),
                   lty=c(1, 1, 2, 3, 3), cex=0.8,
                   bg="white")
dev.off()

