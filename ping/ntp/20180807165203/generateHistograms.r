arg <- "i0.5_s56_"
nums <- seq(0,4)

# Sequence of breaks in histogram
mBinSize <- 0.001
mBreaks <- seq(0,2,mBinSize)
mYLabel <- paste("Count (",mBinSize,") ms bins",sep="")

# X-Boundary for graph
xBounds <- c(0, 0.4)

# For IPv4. . .

# Input and agregate data
native <- c()
container <- c()
ntpRTT <- c()

for (n in nums) {
  native <- c(native, scan(file=paste("native_",arg,n,".data",sep=""), sep="\n", quiet=T))
  container <- c(container, scan(file=paste("container_",arg,n,".data",sep=""), sep="\n", quiet=T))
  ntpRTT <- c(ntpRTT, scan(file=paste("ntp_bais_",arg,n,".data",sep=""),sep="\n", quiet=T))
}

# Convert seconds into ms
ntpRTT <- ntpRTT * 1000

# Compute histograms
nativeHist <- hist(native, breaks=mBreaks, plot=F)
containerHist <- hist(container, breaks=mBreaks, plot=F)
ntpRTTHist <- hist(ntpRTT, breaks=mBreaks, plot=F)

# Write graph
pdf(file=paste("v4_",arg,"_histCombined.pdf",sep=""),width=10,height=10)
yMax <- max(nativeHist$counts, containerHist$counts, ntpRTTHist$counts)
yBounds <- c(0,yMax)
plot(xBounds,yBounds,type="n")
lines(mBreaks[-1],nativeHist$counts,type="l",col="black")
lines(mBreaks[-1],containerHist$counts,type="l",col="blue")
lines(mBreaks[-1],ntpRTTHist$counts,type="l",col="red")
legend("topright",legend=c("Native","Container","NTP RTT"),col=c("black","blue","red"),lty=1,cex=0.8)
dev.off()


