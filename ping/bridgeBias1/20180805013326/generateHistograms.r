intervals <- c("1.0", "0.8", "0.6", "0.4")
# All payloads are 120 bytes
nums <- seq(0,9)

# Sequence of breaks in histogram
mBinSize <- 0.001
mBreaks <- seq(0,2,mBinSize)
mYLabel <- paste("Count (",mBinSize,") ms bins",sep="")

# X-Boundary for graph
xBounds <- c(0, 0.2)

# For each interval
for (i in intervals) {
  # Input and agregate data
  containerToTarget <- c()
  nativeToTarget <- c()
  dindContainerToContainer <- c()
  dindToContainer <- c()

  for (n in nums) {
    containerToTarget <- c(containerToTarget,scan(file=paste("rawFiles/v4_container_to_target_i",i,"s120_",n,".data",sep=""), sep="\n", quiet=T))
    nativeToTarget <- c(nativeToTarget,scan(file=paste("rawFiles/v4_native_to_target_i",i,"s120_",n,".data",sep=""), sep="\n", quiet=T))
    dindContainerToContainer <- c(dindContainerToContainer,scan(file=paste("rawFiles/v4_dind_container_to_container_i",i,"s120_",n,".data",sep=""), sep="\n", quiet=T))
    dindToContainer <- c(dindToContainer,scan(file=paste("rawFiles/v4_dind_to_container_i",i,"s120_",n,".data",sep=""), sep="\n", quiet=T))
  }

  pdf(file=paste("i",i,"_histContainerToTarget.pdf",sep=""),width=5,height=5)
  containerToTargetHist <- hist(containerToTarget, breaks=mBreaks, xlim=xBounds)
  dev.off()

  pdf(file=paste("i",i,"_histNativeToTarget.pdf",sep=""),width=5,height=5)
  nativeToTargetHist <- hist(nativeToTarget, breaks=mBreaks, xlim=xBounds)
  dev.off()

  pdf(file=paste("i",i,"_histDindContainerToContainer.pdf",sep=""),width=5,height=5)
  dindContainerToContainerHist <- hist(dindContainerToContainer, breaks=mBreaks, xlim=xBounds)
  dev.off()

  pdf(file=paste("i",i,"_histDindToContainer.pdf",sep=""),width=5,height=5)
  dindToContainerHist <- hist(dindToContainer, breaks=mBreaks, xlim=xBounds)
  dev.off()

  pdf(file=paste("i",i,"_histCombined.pdf",sep=""),width=10,height=10)
  yMax <- max(containerToTargetHist$counts,nativeToTargetHist$counts,dindContainerToContainerHist$counts,dindToContainerHist$counts)
  yBounds <- c(0,yMax)
  plot(xBounds,yBounds,type="n")
  lines(mBreaks[-1],containerToTargetHist$counts,type="l",col="red")
  lines(mBreaks[-1],nativeToTargetHist$counts,type="l",col="black")
  lines(mBreaks[-1],dindContainerToContainerHist$counts,type="l",col="blue")
  lines(mBreaks[-1],dindToContainerHist$counts,type="l",col="gray")
  legend("topright",legend=c("Cont. to Target","Native to Target","Cont. in DinD to Cont. in Native","DinD to Cont. in Native"),col=c("red","black","blue","gray"),lty=1,cex=0.8)
  dev.off()
}
