
# Series of intervals and sizes determine file names to load
intervals <- c(0.2, 0.4, 0.6, 0.8, 1.0, 1.2)

# Sequence of breaks in histogram
mBinSize <- 0.001
mBreaks <- seq(0,100,mBinSize)
mYLabel <- paste("Count (",mBinSize,") sec bins",sep="")

# X-Boundary for graph
xBounds <- c(0, 1)

# Generate histograms for ipv4 tests
for (i in intervals) {
  # Read in native and container data
  native <- read.table(paste("native_v4_", format(i,nsmall=1), ".data", sep=""), sep="\n")
  container <- read.table(paste("container_v4_", format(i,nsmall=1), ".data",sep=""), sep="\n")

  # Compute histograms, means
  nativeHist <- hist(native[,1], plot=F, breaks=mBreaks)
  nativeMean <- mean(native[,1])
  containerHist <- hist(container[,1], plot=F, breaks=mBreaks)
  containerMean <- mean(container[,1])

  # Graph native and container histograms on same axis
  pdf(file=paste("native_vs_container_v4_", format(i,nsmall=1), ".pdf",sep=""), width=5, height=5)
  heading <- paste("Native vs. Container ipv4 i=", format(i,nsmall=1), sep="")
  yMax <- max(nativeHist$counts,containerHist$counts)
  yBounds <- c(0,yMax)
  plot(nativeHist$breaks[-1], nativeHist$counts, type="l", main=heading, xlim=xBounds, ylim=yBounds, ylab=mYLabel, xlab="")
  lines(containerHist$breaks[-1], containerHist$counts,type="l",col="red", xlim=xBounds, ylim=yBounds)
  mtext("RTT (ms)",line=2,side=1,adj=1)
  mtext(paste("Native mean:",nativeMean),line=2,side=1,adj=0)
  mtext(paste("Container mean:",containerMean),line=3,side=1,adj=0)
  mtext(paste("Difference:",containerMean-nativeMean),line=4,side=1,adj=0)
  dev.off()
}
