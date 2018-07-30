# Series of intervals and sizes determine file names to load
intervalsStr <- c(0.2, 0.3, 0.5, 1.0)
sizesStr <- c(16, 56, 120, 504, 1472)

# Sequence of breaks in histogram
mBinSize <- 0.001
mBreaks <- seq(0,2,0.001)
mYLabel <- paste("Count (",mBinSize,") sec bins",sep="")

# X-Boundary for graph
xBounds <- c(0, 0.5)

# Generate histograms for ipv4 tests
for (i in intervalsStr) {
  for (s in sizesStr) {
    # Read in native and container data
    native <- read.table(paste("native_v4_i", format(i,nsmall=1), "_s", s, ".data",sep=""), sep="\n")
    container <- read.table(paste("container_v4_i", format(i,nsmall=1), "_s", s, ".data",sep=""), sep="\n")

    # Compute histograms, means
    nativeHist <- hist(native[,1], plot=F, breaks=mBreaks)
    nativeMean <- mean(native[,1])
    containerHist <- hist(container[,1], plot=F, breaks=mBreaks)
    containerMean <- mean(container[,1])

    # Graph native and container histograms on same axis
    pdf(file=paste("native_vs_container_v4_i", format(i,nsmall=1), "_s", s, ".pdf",sep=""), width=5, height=5)
    heading <- paste("Native vs. Container ipv4 i=", format(i,nsmall=1), " s=", s,sep="")
    yMax <- max(nativeHist$counts,containerHist$counts)
    yBounds <- c(0,yMax)
    plot(nativeHist$breaks[-1], nativeHist$counts, type="l", main=heading, xlim=xBounds, ylim=yBounds, ylab=mYLabel, xlab="")
    lines(containerHist$breaks[-1], containerHist$counts,type="l",col="red", xlim=xBounds, ylim=yBounds)
    mtext("RTT (sec)",line=2,side=1,adj=1)
    mtext(paste("Native mean:",nativeMean),line=2,side=1,adj=0)
    mtext(paste("Container mean:",containerMean),line=3,side=1,adj=0)
    mtext(paste("Difference:",containerMean-nativeMean),line=4,side=1,adj=0)
    dev.off()
  }
}


# Generate histograms for ipv6 tests
for (i in intervalsStr) {
  for (s in sizesStr) {
    # Read in native and container data
    native <- read.table(paste("native_v6_i", format(i,nsmall=1), "_s", s, ".data",sep=""), sep="\n")
    container <- read.table(paste("container_v6_i", format(i,nsmall=1), "_s", s, ".data",sep=""), sep="\n")

    # Compute histograms, means
    nativeHist <- hist(native[,1], plot=F, breaks=mBreaks)
    nativeMean <- mean(native[,1])
    containerHist <- hist(container[,1], plot=F, breaks=mBreaks)
    containerMean <- mean(container[,1])

    # Graph native and container histograms on same axis
    pdf(file=paste("native_vs_container_v6_i", format(i,nsmall=1), "_s", s, ".pdf",sep=""), width=5, height=5)
    heading <- paste("Native vs. Container ipv6 i=", format(i,nsmall=1), " s=", s,sep="")
    yMax <- max(nativeHist$counts,containerHist$counts)
    yBounds <- c(0,yMax)
    plot(nativeHist$breaks[-1], nativeHist$counts, type="l", main=heading, xlim=xBounds, ylim=yBounds, ylab=mYLabel, xlab="")
    lines(containerHist$breaks[-1], containerHist$counts,type="l",col="red", xlim=xBounds, ylim=yBounds)
    mtext("RTT (sec)",line=2,side=1,adj=1)
    mtext(paste("Native mean:",nativeMean),line=2,side=1,adj=0)
    mtext(paste("Container mean:",containerMean),line=3,side=1,adj=0)
    mtext(paste("Difference:",containerMean-nativeMean),line=4,side=1,adj=0)
    dev.off()
  }
}
