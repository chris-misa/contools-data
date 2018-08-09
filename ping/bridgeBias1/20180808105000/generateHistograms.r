sizes <- c("120")
# All intervals are 0.5 seconds
nums <- seq(0,9)

# Sequence of breaks in histogram
mBinSize <- 0.001
mBreaks <- seq(0,2,mBinSize)
mYLabel <- paste("Count (",mBinSize,") ms bins",sep="")

# X-Boundary for graph
xBounds <- c(0, 0.4)

# For each interval
for (s in sizes) {
  # Input and agregate data
  containerToTarget <- c()
  nativeToTarget <- c()
  dindContainerToTarget <- c()
  dindToTarget <- c()

  for (n in nums) {
    containerToTarget <- c(containerToTarget,scan(file=paste("rawFiles/v4_container_to_target_i0.5s",s,"_",n,".data",sep=""), sep="\n", quiet=T))
    nativeToTarget <- c(nativeToTarget,scan(file=paste("rawFiles/v4_native_to_target_i0.5s",s,"_",n,".data",sep=""), sep="\n", quiet=T))
    dindContainerToTarget <- c(dindContainerToTarget,scan(file=paste("rawFiles/v4_dind_container_to_target_i0.5s",s,"_",n,".data",sep=""), sep="\n", quiet=T))
    dindToTarget <- c(dindToTarget,scan(file=paste("rawFiles/v4_dind_to_target_i0.5s",s,"_",n,".data",sep=""), sep="\n", quiet=T))
  }

  pdf(file=paste("s",s,"_histContainerToTarget.pdf",sep=""),width=5,height=5)
  containerToTargetHist <- hist(containerToTarget, breaks=mBreaks, xlim=xBounds)
  dev.off()

  pdf(file=paste("s",s,"_histNativeToTarget.pdf",sep=""),width=5,height=5)
  nativeToTargetHist <- hist(nativeToTarget, breaks=mBreaks, xlim=xBounds)
  dev.off()

  pdf(file=paste("s",s,"_histDindContainerToTarget.pdf",sep=""),width=5,height=5)
  dindContainerToTargetHist <- hist(dindContainerToTarget, breaks=mBreaks, xlim=xBounds)
  dev.off()

  pdf(file=paste("s",s,"_histDindToTarget.pdf",sep=""),width=5,height=5)
  dindToTargetHist <- hist(dindToTarget, breaks=mBreaks, xlim=xBounds)
  dev.off()

  pdf(file=paste("s",s,"_histCombined.pdf",sep=""),width=10,height=10)
  yMax <- max(containerToTargetHist$counts,nativeToTargetHist$counts,dindContainerToTargetHist$counts,dindToTargetHist$counts)
  yBounds <- c(0,yMax)
  plot(xBounds,yBounds,type="n")
  lines(mBreaks[-1],containerToTargetHist$counts,type="l",col="red")
  lines(mBreaks[-1],nativeToTargetHist$counts,type="l",col="black")
  lines(mBreaks[-1],dindContainerToTargetHist$counts,type="l",col="blue")
  lines(mBreaks[-1],dindToTargetHist$counts,type="l",col="gray")
  legend("topright",legend=c("Cont. to Target","Native to Target","Cont. in DinD to Target","DinD to Cont. in Target"),col=c("red","black","blue","gray"),lty=1,cex=0.8)
  dev.off()
}
