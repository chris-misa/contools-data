arg_seq <- c("i0.5s16", "i0.5s56", "i0.5s120", "i0.5s504", "i0.5s1472")

# Sequence of breaks in histogram
mBinSize <- 0.001
mBreaks <- seq(0,2,mBinSize)
mYLabel <- paste("Count (",mBinSize,") ms bins",sep="")

# X-Boundary for graph
xBounds <- c(0.05, 0.15)

# Generate histograms for ipv4 tests
for (i in arg_seq) {
  # Read in native, host, and container data
  native <- read.table(paste("nativeping_target_v4_", i, ".data",sep=""), sep="\n")
  container <- read.table(paste("containerping_target_v4_", i, ".data",sep=""), sep="\n")

  # Compute histograms, means
  nativeHist <- hist(native[,1], plot=F, breaks=mBreaks)
  nativeMean <- mean(native[,1])
  containerHist <- hist(container[,1], plot=F, breaks=mBreaks)
  containerMean <- mean(container[,1])

  # Graph native and container histograms on same axis
  pdf(file=paste("native_container_v4_", i, ".pdf",sep=""), width=5, height=5)
  heading <- paste("Native vs. Container ipv4", i)
  yMax <- max(nativeHist$counts, containerHist$counts)
  yBounds <- c(0,yMax)
  plot(nativeHist$breaks[-1], nativeHist$counts, type="l", main=heading, xlim=xBounds, ylim=yBounds, ylab=mYLabel, xlab="")
  lines(containerHist$breaks[-1], containerHist$counts,type="l",col="blue", xlim=xBounds, ylim=yBounds)
  mtext("RTT (ms)",line=2,side=1,adj=1)
  mtext(paste("Native mean:",nativeMean),line=2,side=1,adj=0)
  mtext(paste("Container mean:",containerMean),line=3,side=1,adj=0)
  dev.off()
}



# Generate histograms for ipv6 tests
for (i in arg_seq) {
  # Read in native, host, and container data
  native <- read.table(paste("nativeping_target_v6_", i, ".data",sep=""), sep="\n")
  container <- read.table(paste("containerping_target_v6_", i, ".data",sep=""), sep="\n")

  # Compute histograms, means
  nativeHist <- hist(native[,1], plot=F, breaks=mBreaks)
  nativeMean <- mean(native[,1])
  containerHist <- hist(container[,1], plot=F, breaks=mBreaks)
  containerMean <- mean(container[,1])

  # Graph native and container histograms on same axis
  pdf(file=paste("native_container_v6_", i, ".pdf",sep=""), width=5, height=5)
  heading <- paste("Native vs. Container ipv6", i)
  yMax <- max(nativeHist$counts, containerHist$counts)
  yBounds <- c(0,yMax)
  plot(nativeHist$breaks[-1], nativeHist$counts, type="l", main=heading, xlim=xBounds, ylim=yBounds, ylab=mYLabel, xlab="")
  lines(containerHist$breaks[-1], containerHist$counts,type="l",col="blue", xlim=xBounds, ylim=yBounds)
  mtext("RTT (ms)",line=2,side=1,adj=1)
  mtext(paste("Native mean:",nativeMean),line=2,side=1,adj=0)
  mtext(paste("Container mean:",containerMean),line=3,side=1,adj=0)
  dev.off()
}
