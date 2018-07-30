# Series of intervals and sizes determine file names to load
intervalsStr <- c(0.2, 0.5, 1.0)
sizesStr <- c(16, 120)

# Sequence of breaks in histogram
mBinSize <- 0.001
mBreaks <- seq(0,2,mBinSize)
mYLabel <- paste("Count (",mBinSize,") ms bins",sep="")

# X-Boundary for graph
xBounds <- c(0, 0.5)

# Generate histograms for ipv4 tests
for (i in intervalsStr) {
  for (s in sizesStr) {
    # Read in native, host, and container data
    native <- read.table(paste("native_target_v4_i", format(i,nsmall=1), "_s", s, ".data",sep=""), sep="\n")
    host <- read.table(paste("container_host_v4_i", format(i,nsmall=1),"_s", s, ".data", sep=""), sep="\n")
    container <- read.table(paste("container_target_v4_i", format(i,nsmall=1), "_s", s, ".data",sep=""), sep="\n")

    # Compute histograms, means
    nativeHist <- hist(native[,1], plot=F, breaks=mBreaks)
    nativeMean <- mean(native[,1])
    hostHist <- hist(host[,1], plot=F, breaks=mBreaks)
    hostMean <- mean(host[,1])
    containerHist <- hist(container[,1], plot=F, breaks=mBreaks)
    containerMean <- mean(container[,1])

    # Graph native and container histograms on same axis
    pdf(file=paste("native_host_container_v4_i", format(i,nsmall=1), "_s", s, ".pdf",sep=""), width=5, height=5)
    heading <- paste("Native vs. Host vs. Container ipv4 i=", format(i,nsmall=1), " s=", s,sep="")
    yMax <- max(nativeHist$counts, hostHist$counts, containerHist$counts)
    yBounds <- c(0,yMax)
    plot(nativeHist$breaks[-1], nativeHist$counts, type="l", main=heading, xlim=xBounds, ylim=yBounds, ylab=mYLabel, xlab="")
    lines(hostHist$breaks[-1], hostHist$counts,type="l",col="blue", xlim=xBounds, ylim=yBounds)
    lines(containerHist$breaks[-1], containerHist$counts,type="l",col="red", xlim=xBounds, ylim=yBounds)
    mtext("RTT (ms)",line=2,side=1,adj=1)
    mtext(paste("Native mean:",nativeMean),line=2,side=1,adj=0)
    mtext(paste("Host mean:",hostMean),line=3,side=1,adj=0)
    mtext(paste("Container mean, Difference:",containerMean,containerMean-nativeMean),line=4,side=1,adj=0)
    dev.off()
  }
}


# Generate histograms for ipv6 tests
for (i in intervalsStr) {
  for (s in sizesStr) {
    # Read in native, host, and container data
    native <- read.table(paste("native_target_v6_i", format(i,nsmall=1), "_s", s, ".data",sep=""), sep="\n")
    host <- read.table(paste("container_host_v6_i", format(i,nsmall=1),"_s", s, ".data", sep=""), sep="\n")
    container <- read.table(paste("container_target_v6_i", format(i,nsmall=1), "_s", s, ".data",sep=""), sep="\n")

    # Compute histograms, means
    nativeHist <- hist(native[,1], plot=F, breaks=mBreaks)
    nativeMean <- mean(native[,1])
    hostHist <- hist(host[,1], plot=F, breaks=mBreaks)
    hostMean <- mean(host[,1])
    containerHist <- hist(container[,1], plot=F, breaks=mBreaks)
    containerMean <- mean(container[,1])

    # Graph native and container histograms on same axis
    pdf(file=paste("native_host_container_v6_i", format(i,nsmall=1), "_s", s, ".pdf",sep=""), width=5, height=5)
    heading <- paste("Native vs. Host vs. Container ipv6 i=", format(i,nsmall=1), " s=", s,sep="")
    yMax <- max(nativeHist$counts, hostHist$counts, containerHist$counts)
    yBounds <- c(0,yMax)
    plot(nativeHist$breaks[-1], nativeHist$counts, type="l", main=heading, xlim=xBounds, ylim=yBounds, ylab=mYLabel, xlab="")
    lines(hostHist$breaks[-1], hostHist$counts,type="l",col="blue", xlim=xBounds, ylim=yBounds)
    lines(containerHist$breaks[-1], containerHist$counts,type="l",col="red", xlim=xBounds, ylim=yBounds)
    mtext("RTT (ms)",line=2,side=1,adj=1)
    mtext(paste("Native mean:",nativeMean),line=2,side=1,adj=0)
    mtext(paste("Host mean:",hostMean),line=3,side=1,adj=0)
    mtext(paste("Container mean, Difference:",containerMean,containerMean-nativeMean),line=4,side=1,adj=0)
    dev.off()
  }
}
