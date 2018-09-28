confidence <- 0.90

args <- commandArgs(trailingOnly=T)
USAGE <- "Rscript genReport.r <path to data folder>"

if (length(args) != 1) {
  stop(USAGE)
}


DATA_PATH <- args[1]
TARGET <- "10.10.1.2"
SETTINGS <- scan(file=paste(DATA_PATH, "file_list", sep=""),
                 what=character(),
                 sep="\n")

print(SETTINGS)

#
# Read and parse a dump from ping
#
readPingFile <- function(filePath) {
  con <- file(filePath, "r")
  rtts <- c()
  linePattern <- ".* time=([0-9\\.]+) ms"
  while (T) {
    line <- readLines(con, n=1)
    if (length(line) == 0) {
      break
    }
    matches <- grep(linePattern, line, value=T)

    rtt <- as.numeric(sub(linePattern, "\\1", matches)) * 1000
    rtts <- c(rtts, rtt)
  }
  close(con)
  rtts
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

drawArrowsCenters <- function(ys, sds, color, centers) {
  arrows(centers, ys - sds,
         centers, ys + sds,
         length=0.05, angle=90, code=3, col=color)
}

#
# Start main work
#
nativeMeans <- c()
nativeSDs <- c()
containerMeans <- c()
containerSDs <- c()
ns <- c()
for (s in SETTINGS) {
  native <- readPingFile(paste(DATA_PATH, "native_control_", TARGET, "_", s, ".ping", sep=""))
  container <- readPingFile(paste(DATA_PATH, "container_monitored_", TARGET, "_", s, ".ping", sep=""))

  nativeMeans <- c(nativeMeans, mean(native))
  nativeSDs <- c(nativeSDs, sd(native))
  containerMeans <- c(containerMeans, mean(container))
  containerSDs <- c(containerSDs, sd(container))
  ns <- c(ns, length(native))
}

#
# Build confidence intervals
#
a <- confidence + 0.5 * (1.0 - confidence)
n <- min(ns)
t_an <- qt(a, df=length(nativeMeans)-1)
nativeErrs <- t_an * nativeSDs / sqrt(length(nativeMeans))
containerErrs <- t_an * containerSDs / sqrt(length(containerMeans))

#
# Graph means with confidence intervals
#
pdf(file=paste(DATA_PATH, "mean_summary.pdf", sep=""), width=10, height=5)
yBounds <- c(min(nativeMeans - nativeErrs, containerMeans - containerErrs),
             max(nativeMeans + nativeErrs, containerMeans + containerErrs))
par(mar=c(7,4,4,4))
plot(nativeMeans, type="p", ylim=yBounds, col="gray",
     main="Mean RTT Summary", xlab="", ylab="usec", xaxt="n")
drawArrows(nativeMeans, nativeErrs, "gray")

lines(containerMeans, type="p", col="black")
drawArrows(containerMeans, containerErrs, "black")

axis(1, at=seq(1, length(SETTINGS), by=1), labels=SETTINGS, las=2)
mtext("ping settings (i: interval in sec, s: payload size in bytes)", 1, 5)
legend("bottomright", legend=c("native", "container"),
       col=c("gray", "black"), lty=1, cex=0.8)
dev.off()

#
# Graph mean differences
#
diffs <- containerMeans - nativeMeans
diffsSDs <- containerSDs + nativeSDs
diffsErrors <- qt(a, df=length(diffs)-1) * diffsSDs / sqrt(length(diffs))

pdf(file=paste(DATA_PATH, "mean_diff.pdf", sep=""), width=10, height=5)
yBounds <- c(0, max(diffs + diffsErrors))
par(mar=c(7,4,4,4))
barCenters <- barplot(diffs, main="Container - Native RTT Difference", ylim=yBounds,
  xlab="", ylab="usec",
  names.arg=SETTINGS, las=2)
drawArrowsCenters(diffs, diffsErrors, "black", barCenters)
mtext("ping settings (i: interval in sec, s: payload size in bytes)", 1, 5)
dev.off()
