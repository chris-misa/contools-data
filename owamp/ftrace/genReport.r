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
# Read and parse a dump from owping -R
#
# This doesn't work because R can't handle 64 bit integers
#
readOwpingFile <- function(filePath) {
  con <- file(filePath, "r")
  outBound <- data.frame(delay = c(), ts = c())
  inBound <- data.frame(delay = c(), ts = c())
  linePattern <- "seq_no=([0-9]+) .* sent=([0-9\\.]+) recv=([0-9\\.]+)"
  first <- 0
  while (T) {
    line <- readLines(con, n=1)
    if (length(line) == 0) {
      break
    }

    matches <- grep(linePattern, line, value=T)

    if (length(matches) > 0) {
      index <- as.numeric(sub(linePattern, "\\1", matches))
      sendRaw <- as.numeric(sub(linePattern, "\\2", matches))
      recvRaw <- as.numeric(sub(linePattern, "\\3", matches))
      ts <- 0.5 * (sendRaw + recvRaw)

      if (first == 0 && index == 0) {
        first <- 1
      } else if (first == 1 && index == 0) {
        first <- 2
      }

      rawDelayUsec = (recvRaw - sendRaw) * 1000000

      if (first == 1) {
        outBound <- data.frame(delay = c(outBound$delay, rawDelayUsec),
                               ts = c(outBound$ts, ts))
      } else if (first == 2) {
        inBound <- data.frame(delay = c(inBound$delay, rawDelayUsec),
                              ts = c(inBound$ts, ts))
      }
    }
  }
  close(con)
  data.frame(out_bound.delay=outBound$delay,
             out_bound.ts=outBound$ts,
             in_bound.delay=inBound$delay,
             in_bound.ts=inBound$ts)
}

#
# Read and parse a dump from ftrace-based latency tool
#
readLatencyFile <- function(filePath) {
  con <- file(filePath, "r")
  outBound <- data.frame(latency=c(), ts=c())
  inBound <- data.frame(latency=c(), ts=c())
  sendPattern <- "\\[([0-9\\.]+)\\] send latency: ([0-9\\.]+), .*"
  recvPattern <- "\\[([0-9\\.]+)\\] recv raw_latency: ([0-9\\.]+), .*"
  while (T) {
    line <- readLines(con, n=1)
    if (length(line) == 0) {
      break
    }
    matches <- grep(sendPattern, line, value=T)

    if (length(matches) > 0) {
      ts <- as.numeric(sub(sendPattern, "\\1", matches))
      sendTime <- as.numeric(sub(sendPattern, "\\2", matches))
      outBound <- data.frame(latency=c(outBound$latency, sendTime),
                             ts=c(outBound$ts, ts))
    } else {
      matches <- grep(recvPattern, line, value=T)

      if (length(matches) > 0) {
        ts <- as.numeric(sub(recvPattern, "\\1", matches))
        recvTime <- as.numeric(sub(recvPattern, "\\2", matches))
        inBound <- data.frame(latency=c(inBound$latency, recvTime),
                              ts=c(inBound$ts, ts))
      }
    }
  }

  close(con)
  data.frame(out_bound.latency=outBound$latency,
             out_bound.ts=outBound$ts,
             in_bound.latency=inBound$latency,
             in_bound.ts=inBound$ts)
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
# Function to subtract latency from container by nearest timestamp correlation
#
adjustContainer <- function(container, container_ts, latency, latency_ts) {
  adjs <- c()
  l <- 2
  lat_len <- length(latency_ts)
  if (lat_len <= 2) {
    print("adjustContainer: not enough latencies, not-adjusting")
    container
  } else {
    for (i in 1:length(container)) {
      if (l < lat_len && container_ts[[i]] > latency_ts[[l]]) {
        l <- l + 1
      }
      
      if (abs(latency_ts[[l]] - container_ts[[i]])
          < abs(latency_ts[[l-1]] - container_ts[[i]])) {
        ave_lat <- latency[[l]]
      } else {
        ave_lat <- latency[[l-1]]
      }
      adj <- container[[i]] - ave_lat
      adjs <- c(adjs, adj)
    }
    data.frame(adjusted=adjs, ts=container_ts)
  }
}

#
# Computes the max of distribution
#
mode <- function(data) {
  df <- hist(data,plot=F)
  df$mids[which.max(df$counts)]
}

addStats <- function(oldData, rtts) {
  newMean = mean(rtts)
  newMode = mode(rtts)
  newMin  = min(rtts)
  newSD   = sd(rtts)
  newErr  = 0
  data.frame(mean=c(oldData$mean, newMean),
             mode=c(oldData$mode, newMode),
             min=c(oldData$min, newMin),
             sd=c(oldData$sd, newSD),
             err=c(oldData$err, newErr))
}

#
# collect statistics
#
nativeControls = data.frame(mean=c(),mode=c(),min=c(),sd=c(),err=c())
containerControls = data.frame(mean=c(),mode=c(),min=c(),sd=c(),err=c())
nativeMonitoreds = data.frame(mean=c(),mode=c(),min=c(),sd=c(),err=c())
containerMonitoreds = data.frame(mean=c(),mode=c(),min=c(),sd=c(),err=c())
latencies = data.frame(mean=c(),mode=c(),min=c(),sd=c(),err=c())
containerAdjusteds = data.frame(mean=c(),mode=c(),min=c(),sd=c(),err=c())

ns <- c()

for (iperf_arg in IPERF_SETTINGS) {
  nativeControl <- readOwpingFile(paste(DATA_PATH, "native_control_", TARGET, "_", iperf_arg, ".owping", sep = ""))
  containerControl <- readOwpingFile(paste(DATA_PATH, "container_control_", TARGET, "_", iperf_arg, ".owping", sep = ""))
  nativeMonitored <- readOwpingFile(paste(DATA_PATH, "native_monitored_", TARGET, "_", iperf_arg, ".owping", sep = ""))
  containerMonitored <- readOwpingFile(paste(DATA_PATH, "container_monitored_", TARGET, "_", iperf_arg, ".owping", sep = ""))

  latency <- readLatencyFile(paste(DATA_PATH, "container_monitored_", TARGET, "_", iperf_arg, ".latency", sep = ""))


  cat(iperf_arg," number of out-bound data points:\n",sep="")
  cat("  native control:     ", length(nativeControl$out_bound.delay), "\n")
  cat("  container control:  ", length(containerControl$out_bound.delay), "\n")
  cat("  native monitored:   ", length(nativeMonitored$out_bound.delay), "\n")
  cat("  container monitored:", length(containerMonitored$out_bound.delay), "\n")
  cat("  latencies:          ", length(latency$out_bound.latency), "\n")

  adjusted_out <- adjustContainer(containerMonitored$out_bound.delay,
                                  containerMonitored$out_bound.ts,
                                  latency$out_bound.latency,
                                  latency$out_bound.ts)
  adjusted_in <- adjustContainer(containerMonitored$out_bound.delay,
                                 containerMonitored$out_bound.ts,
                                 latency$out_bound.latency,
                                 latency$out_bound.ts)
  containerAdjusted = data.frame(out_bound.delay=adjusted_out$adjusted,
                                 out_bound.ts=adjusted_out$ts,
                                 in_bound.delay=adjusted_in$adjusted,
                                 in_bound.ts=adjusted_in$ts)


  nativeControls <- addStats(nativeControls, nativeControl$out_bound.delay)
  containerControls <- addStats(containerControls, containerControl$out_bound.delay)
  nativeMonitoreds <- addStats(nativeMonitoreds, nativeMonitored$out_bound.delay)
  containerMonitoreds <- addStats(containerMonitoreds, containerMonitored$out_bound.delay)
  latencies <- addStats(latencies, latency$out_bound.latency)
  containerAdjusteds <- addStats(containerAdjusteds, containerAdjusted$out_bound.delay)

  #
  # Generate time-sequences
  #
  pdf(file=paste(DATA_PATH,"seq_",iperf_arg,".pdf",sep=""), width=10, height=5)
  plot(containerMonitored$out_bound.ts, containerMonitored$out_bound.delay, type="l", col="black",
    ylim=c(0,max(containerMonitored$out_bound.delay)), ylab="Out-bound time (usec)",
    xlab="Time Stamp",
    main="Time Sequences")
  lines(nativeMonitored$out_bound.ts, nativeMonitored$out_bound.delay, type="l", col="blue")
  lines(latency$out_bound.ts, latency$out_bound.latency, type="l", col="green")
  lines(containerAdjusted$out_bound.ts, containerAdjusted$out_bound.delay, type="l", col="red")
  legend("topright", legend=c("container", "adjusted container", "raw latency", "native"),
                     col=c("black", "red", "green", "blue"),
                     lty=1, cex=0.8)
  dev.off()

  #
  # Generate histogram
  #
  xmin <- min(nativeControl$out_bound.delay,
              containerMonitored$out_bound.delay,
              nativeMonitored$out_bound.delay,
              containerAdjusted$out_bound.delay)
  xmax <- max(nativeControl$out_bound.delay,
              containerMonitored$out_bound.delay,
              nativeMonitored$out_bound.delay,
              containerAdjusted$out_bound.delay)
  mBreaks <- seq(xmin - 1, xmax + 1, 1)

  cat("Hist range:", xmin, xmax,"\n")

  pdf(file=paste(DATA_PATH,"hist_",iperf_arg,".pdf",sep=""), width=10,height=5)
  controlRTTHist <- hist(nativeControl$out_bound.delay, breaks=mBreaks, plot=F)
  containerRTTHist <- hist(containerMonitored$out_bound.delay, breaks=mBreaks, plot=F)
  nativeMonitoredHist <- hist(nativeMonitored$out_bound.delay, breaks=mBreaks, plot=F)
  containerAdjustedHist <- hist(containerAdjusted$out_bound.delay, breaks=mBreaks, plot=F)
  yMax <- max(controlRTTHist$counts,
              containerRTTHist$counts,
              nativeMonitoredHist$counts,
              containerAdjustedHist$counts)
  plot(c(0,xmax), c(0,yMax), type="n")
  lines(mBreaks[-1], controlRTTHist$counts, type="l", col="green")
  lines(mBreaks[-1], containerRTTHist$counts, type="l", col="black")
  lines(mBreaks[-1], nativeMonitoredHist$counts, type="l", col="blue")
  lines(mBreaks[-1], containerAdjustedHist$counts, type="l", col="red")
  dev.off()
}

cat("Native control\n")
nativeControls
cat("Container control\n")
containerControls
cat("Native monitored\n")
nativeMonitoreds
cat("Container monitored\n")
containerMonitoreds
cat("Container Adjusted\n")
containerAdjusteds

#
# Generate graph of rtt measurements vs. traffic load MEAN
#
yBounds <- c(min(nativeControls$mean - nativeControls$sd,
                 containerMonitoreds$mean - containerMonitoreds$sd,
                 containerControls$mean - containerControls$sd,
                 containerAdjusteds$mean - containerAdjusteds$sd),
             max(nativeControls$mean + nativeControls$sd,
                 containerMonitoreds$mean + containerMonitoreds$sd,
                 containerControls$mean + containerControls$sd,
                 containerAdjusteds$mean + containerAdjusteds$sd))
pdf(file=paste(DATA_PATH,"rtts_mean.pdf",sep=""), width=5, height=5)
plot(nativeControls$mean, type="b", ylim=yBounds, col="green",
     main="RTT Mean", xlab="traffic bandwidth", ylab="usec",
     xaxt="n",
     lty=3)
drawArrows(nativeControls$mean, nativeControls$sd, "green")

lines(nativeMonitoreds$mean, type="b", col="blue", lty=2)

lines(containerMonitoreds$mean, type="b", col="black", lty=1)
drawArrows(containerMonitoreds$mean, containerMonitoreds$sd, "black")

lines(containerControls$mean, type="b", col="purple", lty=3)
drawArrows(containerControls$mean, containerControls$sd, "purple")

lines(containerAdjusteds$mean, type="b", col="red", lty=1)
drawArrows(containerAdjusteds$mean, containerAdjusteds$sd, "red")

axis(1, at=seq(1,length(IPERF_SETTINGS),by=1), labels=IPERF_SETTINGS)
legend("topleft", legend=c("container", "container adjusted", "native control", "un-monitored native", "un-monitored container"),
                   col=c("black", "red", "blue", "green", "purple"),
                   lty=c(1, 1, 2, 3, 3), cex=0.8,
                   bg="white")
dev.off()



#
# Generate graph of rtt measurements vs. traffic load MODE
#
yBounds <- c(min(nativeControls$mode - nativeControls$sd,
                 containerMonitoreds$mode - containerMonitoreds$sd,
                 containerControls$mode - containerControls$sd,
                 containerAdjusteds$mode - containerAdjusteds$sd),
             max(nativeControls$mode + nativeControls$sd,
                 containerMonitoreds$mode + containerMonitoreds$sd,
                 containerControls$mode + containerControls$sd,
                 containerAdjusteds$mode + containerAdjusteds$sd))
pdf(file=paste(DATA_PATH,"rtts_mode.pdf",sep=""), width=5, height=5)
plot(nativeControls$mode, type="b", ylim=yBounds, col="green",
     main="RTT Mode", xlab="traffic bandwidth", ylab="usec",
     xaxt="n",
     lty=3)
drawArrows(nativeControls$mode, nativeControls$sd, "green")

lines(nativeMonitoreds$mode, type="b", col="blue", lty=2)

lines(containerMonitoreds$mode, type="b", col="black", lty=1)
drawArrows(containerMonitoreds$mode, containerMonitoreds$sd, "black")

lines(containerControls$mode, type="b", col="purple", lty=3)
drawArrows(containerControls$mode, containerControls$sd, "purple")

lines(containerAdjusteds$mode, type="b", col="red", lty=1)
drawArrows(containerAdjusteds$mode, containerAdjusteds$sd, "red")

axis(1, at=seq(1,length(IPERF_SETTINGS),by=1), labels=IPERF_SETTINGS)
legend("topleft", legend=c("container", "container adjusted", "native control", "un-monitored native", "un-monitored container"),
                   col=c("black", "red", "blue", "green", "purple"),
                   lty=c(1, 1, 2, 3, 3), cex=0.8,
                   bg="white")
dev.off()
