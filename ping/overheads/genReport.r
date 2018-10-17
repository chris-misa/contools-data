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

SIZES <- rep(c("16", "56", "120", "504", "1472"), 4)
INTERVALS <- c("0.2", "0.3", "0.5", "1.0")

print(SIZES)
print(INTERVALS)

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


mode <- function(data) {
  brks <- seq(min(data), max(data), 1)
  hst <- hist(data, breaks=brks, plot=F)
  hst$mids[which.max(hst$counts)]
}

#
# Start main work
#
nativeMeans <- c()
nativeModes <- c()
nativeSDs <- c()
containerMeans <- c()
containerModes <- c()
containerSDs <- c()
ns <- c()
for (s in SETTINGS) {
  native <- readPingFile(paste(DATA_PATH, "native_control_", TARGET, "_", s, ".ping", sep=""))
  container <- readPingFile(paste(DATA_PATH, "container_monitored_", TARGET, "_", s, ".ping", sep=""))

  nativeMeans <- c(nativeMeans, mean(native))
  nativeModes <- c(nativeModes, mode(native))
  nativeSDs <- c(nativeSDs, sd(native))
  containerMeans <- c(containerMeans, mean(container))
  containerModes <- c(containerModes, mode(container))
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
par(mar=c(7,7,4,4))
plot(nativeMeans, type="p", ylim=yBounds, col="deeppink",
     main="", xlab="", ylab=expression(paste(mu,"s")), xaxt="n")
drawArrows(nativeMeans, nativeErrs, "deeppink")

lines(containerMeans, type="p", col="black")
drawArrows(containerMeans, containerErrs, "black")

axis(1, at=seq(1, length(SIZES), by=1), labels=SIZES, las=2)
mtext("payload (b)", 1, 1, at=-1)
axis(1, at=seq(3, length(SIZES), by=5), labels=INTERVALS, line=3, lwd=0, lwd.ticks=0)
mtext("interval (s)", 1, 4, at=-1)
legend("bottomright", legend=c("native", "container"),
       col=c("deeppink", "black"), lty=1, cex=0.8, bg="white")
dev.off()

#
# Graph mean differences
#
diffs <- containerMeans - nativeMeans
diffsSDs <- containerSDs + nativeSDs
diffsErrors <- qt(a, df=length(diffs)-1) * diffsSDs / sqrt(length(diffs))

pdf(file=paste(DATA_PATH, "mean_diff.pdf", sep=""), width=10, height=5)
yBounds <- c(0, max(diffs + diffsErrors))
par(mar=c(7,7,4,4))
barCenters <- barplot(diffs, main="", ylim=yBounds,
  xlab="", ylab=expression(paste(mu,"s")), las=2)
drawArrowsCenters(diffs, diffsErrors, "black", barCenters)

axis(1, at=barCenters, labels=SIZES, las=2)
mtext("payload (b)", 1, 1, at=-2)
axis(1, at=barCenters[seq(3, length(barCenters), by=5)],
     labels=INTERVALS, line=3, lwd=0, lwd.ticks=0)
mtext("interval (s)", 1, 4, at=-1)

dev.off()


#
# Graph modes with confidence intervals
#
pdf(file=paste(DATA_PATH, "mode_summary.pdf", sep=""), width=10, height=5)
yBounds <- c(min(nativeModes - nativeErrs, containerModes - containerErrs),
             max(nativeModes + nativeErrs, containerModes + containerErrs))
par(mar=c(7,7,4,4))
plot(nativeModes, type="p", ylim=yBounds, col="deeppink",
     main="", xlab="", ylab=expression(paste(mu,"s")), xaxt="n")
drawArrows(nativeModes, nativeErrs, "deeppink")

lines(containerModes, type="p", col="black")
drawArrows(containerModes, containerErrs, "black")

axis(1, at=seq(1, length(SIZES), by=1), labels=SIZES, las=2)
mtext("payload (b)", 1, 1, at=-1)
axis(1, at=seq(3, length(SIZES), by=5), labels=INTERVALS, line=3, lwd=0, lwd.ticks=0)
mtext("interval (s)", 1, 4, at=-1)
legend("bottomright", legend=c("native", "container"),
       col=c("deeppink", "black"), lty=1, cex=0.8, bg="white")
dev.off()


#
# Graph mode differences
#
diffs <- containerModes - nativeModes
diffsSDs <- containerSDs + nativeSDs
diffsErrors <- qt(a, df=length(diffs)-1) * diffsSDs / sqrt(length(diffs))
pdf(file=paste(DATA_PATH, "mode_diff.pdf", sep=""), width=10, height=5)
yBounds <- c(0, max(diffs + diffsErrors))
par(mar=c(7,7,4,4))
barCenters <- barplot(diffs, main="", ylim=yBounds,
  xlab="", ylab=expression(paste(mu,"s")), las=2)
drawArrowsCenters(diffs, diffsErrors, "black", barCenters)
axis(1, at=barCenters, labels=SIZES, las=2)
mtext("payload (b)", 1, 1, at=-2)
axis(1, at=barCenters[seq(3, length(barCenters), by=5)],
     labels=INTERVALS, line=3, lwd=0, lwd.ticks=0)
mtext("interval (s)", 1, 4, at=-1)
dev.off()
