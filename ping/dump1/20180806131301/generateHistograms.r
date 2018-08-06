arg <- "i0.5_s56_"
nums <- seq(0,9)

# Sequence of breaks in histogram
mBinSize <- 0.001
mBreaks <- seq(0,2,mBinSize)
mYLabel <- paste("Count (",mBinSize,") ms bins",sep="")

# X-Boundary for graph
xBounds <- c(0, 0.4)

# For IPv4. . .

# Input and agregate data
controlNative <- c()
controlContainer <- c()
native <- c()
container <- c()

for (n in nums) {
  controlNative <- c(controlNative, scan(file=paste("rawFiles/v4_control_native_target",arg,n,".data",sep=""), sep="\n", quiet=T))
  controlContainer <- c(controlContainer, scan(file=paste("rawFiles/v4_control_container_target",arg,n,".data",sep=""), sep="\n", quiet=T))
  native <- c(native, scan(file=paste("rawFiles/v4_native_target",arg,n,".data",sep=""), sep="\n", quiet=T))
  container <- c(container, scan(file=paste("rawFiles/v4_container_target",arg,n,".data",sep=""), sep="\n", quiet=T))
}

# Compute histograms
controlNativeHist <- hist(controlNative, breaks=mBreaks, plot=F)
controlContainerHist <- hist(controlContainer, breaks=mBreaks, plot=F)
nativeHist <- hist(native, breaks=mBreaks, plot=F)
containerHist <- hist(container, breaks=mBreaks, plot=F)

# Write graph
pdf(file=paste("v4_",arg,"_histCombined.pdf",sep=""),width=10,height=10)
yMax <- max(controlNativeHist$counts,controlContainerHist$counts)
yBounds <- c(0,yMax)
plot(xBounds,yBounds,type="n")
lines(mBreaks[-1],controlNativeHist$counts,type="l",col="black")
lines(mBreaks[-1],controlContainerHist$counts,type="l",col="red")
lines(mBreaks[-1],nativeHist$counts,type="l",col="gray")
lines(mBreaks[-1],containerHist$counts,type="l",col="blue")
legend("topright",legend=c("Control Native","Control Container", "Instrumented Native", "Instrumented Container"),col=c("black","red", "gray", "blue"),lty=1,cex=0.8)
dev.off()

# For good measure, peak at distribution of calculated biases . . .
biases <- scan(file="v4_biases.data",sep="\n",quiet=T)
pdf(file="v4_histBiases.pdf", width=5, height=5)
hist(biases,breaks=mBreaks,xlim=xBounds)
dev.off()


# For IPv6. . .

# Input and agregate data
controlNative <- c()
controlContainer <- c()
native <- c()
container <- c()

for (n in nums) {
  controlNative <- c(controlNative, scan(file=paste("rawFiles/v6_control_native_target",arg,n,".data",sep=""), sep="\n", quiet=T))
  controlContainer <- c(controlContainer, scan(file=paste("rawFiles/v6_control_container_target",arg,n,".data",sep=""), sep="\n", quiet=T))
  native <- c(native, scan(file=paste("rawFiles/v6_native_target",arg,n,".data",sep=""), sep="\n", quiet=T))
  container <- c(container, scan(file=paste("rawFiles/v6_container_target",arg,n,".data",sep=""), sep="\n", quiet=T))
}

# Compute histograms
controlNativeHist <- hist(controlNative, breaks=mBreaks, plot=F)
controlContainerHist <- hist(controlContainer, breaks=mBreaks, plot=F)
nativeHist <- hist(native, breaks=mBreaks, plot=F)
containerHist <- hist(container, breaks=mBreaks, plot=F)

# Write graph
pdf(file=paste("v6_",arg,"_histCombined.pdf",sep=""),width=10,height=10)
yMax <- max(controlNativeHist$counts,controlContainerHist$counts)
yBounds <- c(0,yMax)
plot(xBounds,yBounds,type="n")
lines(mBreaks[-1],controlNativeHist$counts,type="l",col="black")
lines(mBreaks[-1],controlContainerHist$counts,type="l",col="red")
lines(mBreaks[-1],nativeHist$counts,type="l",col="gray")
lines(mBreaks[-1],containerHist$counts,type="l",col="blue")
legend("topright",legend=c("Control Native","Control Container", "Instrumented Native", "Instrumented Container"),col=c("black","red", "gray", "blue"),lty=1,cex=0.8)
dev.off()

# For good measure, peak at distribution of calculated biases . . .
biases <- scan(file="v6_biases.data",sep="\n",quiet=T)
pdf(file="v6_histBiases.pdf", width=5, height=5)
hist(biases,breaks=mBreaks,xlim=xBounds)
dev.off()
