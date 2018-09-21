IPERF_SETTINGS <- c("1M", "10M", "100M", "1G", "10G")

args <- commandArgs(trailingOnly=T)
USAGE <- "Rscript genReport.r <path to data folder>"

if (length(args) != 1) {
  stop(USAGE)
}

DATA_PATH <- args[1]
TARGET <- "10.10.1.2"


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

controlMeans <- c()
controlSDs <- c()
containerMeans <-c()
containerSDs <- c()
raw_latMeans <- c()
raw_latSDs <- c()
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

  controlMean <- mean(controlRTTs)
  controlSD <- sd(controlRTTs)
  containerMean <- mean(containerRTTs)
  containerSD <- sd(containerRTTs)
  raw_latMean <- mean(raw_lat)
  raw_latSD <- sd(raw_lat)

  controlMeans <- c(controlMeans, controlMean)
  controlSDs <- c(controlSDs, controlSD)
  containerMeans <- c(containerMeans, containerMean)
  containerSDs <- c(containerSDs, containerSD)
  raw_latMeans <- c(raw_latMeans, raw_latMean)
  raw_latSDs <- c(raw_latSDs, raw_latSD)

  cat("traffic: ", iperf_arg,
      " control RTT: ", mean(controlRTTs), " (", sd(controlRTTs), ") ",
      " container RTT: ", mean(containerRTTs), " (", sd(containerRTTs), ")",
      " RTT latency: ", mean(raw_lat), " (", sd(raw_lat), ") ",
      "\n",
      sep="")
}

data <- data.frame(arg=IPERF_SETTINGS,
                   control_mean=controlMeans,
                   control_sd=controlSDs,
                   container_mean=containerMeans,
                   container_sd=containerSDs,
                   raw_latency_mean=raw_latMeans,
                   raw_latency_sd=raw_latSDs)
data

yBounds <- c(0,max(data$control_mean, data$container_mean))
pdf(file="test.pdf", width=5, height=5)
plot(data$control_mean, type="b", ylim=yBounds)
lines(data$container_mean, type="b", col="blue")
lines(data$raw_latency_mean, type="b", col="red")
lines(data$control_mean - data$raw_latency_mean, type="b", col="gray")
dev.off()
