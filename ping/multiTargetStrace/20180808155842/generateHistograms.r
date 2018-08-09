targets <- c("127.0.0.1", "128.110.153.106", "128.223.142.244", "140.197.253.0", "162.252.70.155", "198.71.45.230")

mBreaks <- seq(0,30,0.001) # for ping distributions
mBreaksSys <- seq(0,1,0.000001) # for strace syscall distributions

for (t in targets) {
  # For ping data
  native <- scan(paste("rawFiles/strace_native_",t,".data",sep=""),sep="\n",quiet=T)
  container <- scan(paste("rawFiles/strace_container_",t,".data",sep=""),sep="\n",quiet=T)
  nativeControl <- scan(paste("rawFiles/control_native_",t,".data",sep=""),sep="\n",quiet=T)
  containerControl <- scan(paste("rawFiles/control_container_",t,".data",sep=""),sep="\n",quiet=T)

  
  pdf(file=paste("hist_",t,".pdf",sep=""),width=5,height=5)
  nativeHist <- hist(native[native<30], plot=F,breaks=mBreaks)
  containerHist <- hist(container[container<30], plot=F,breaks=mBreaks)
  nativeControlHist <- hist(nativeControl[nativeControl<30], plot=F,breaks=mBreaks)
  containerControlHist <- hist(containerControl[containerControl<30], plot=F,breaks=mBreaks)

  # Generate range for graph
  meanNative <- mean(native)
  sdNative <- sd(native)
  meanContainer <- mean(container)
  sdContainer <- sd(container)
  meanNativeControl <- mean(nativeControl)
  sdNativeControl <- sd(nativeControl)
  meanContainerControl <- mean(containerControl)
  sdContainerControl <- sd(containerControl)
  minX <- min(meanNative-3*sdNative,meanContainer-3*sdContainer,meanNativeControl-3*sdNativeControl)
  maxX <- max(meanNative+3*sdNative,meanContainer+3*sdContainer,meanContainerControl+3*sdContainerControl)

  # Draw the graph
  plot(nativeHist$breaks[-1],nativeHist$counts,type="l",col="black",xlim=c(minX,maxX))
  lines(containerHist$breaks[-1],containerHist$counts,type="l",col="red")
  lines(nativeControlHist$breaks[-1],nativeControlHist$counts,type="l",col="gray",xlim=c(minX,maxX))
  lines(containerControlHist$breaks[-1],containerControlHist$counts,type="l",col="blue")
  dev.off()

  # For strace data
  nativeStrace <- scan(paste("rawFiles/native_",t,".data",sep=""),sep="\n",quiet=T)
  containerStrace <- scan(paste("rawFiles/container_",t,".data",sep=""),sep="\n",quiet=T)

  meanNativeStrace <- mean(nativeStrace)
  sdNativeStrace <- sd(nativeStrace)
  meanContainerStrace <- mean(containerStrace)
  sdContainerStrace <- sd(containerStrace)

  minX <- min(meanNativeStrace - 3*sdNativeStrace, meanContainerStrace - 3*sdContainerStrace)
  maxX <- max(meanNativeStrace + 3*sdNativeStrace, meanContainerStrace + 3*sdContainerStrace)

  nativeStraceHist <- hist(nativeStrace,plot=F,breaks=mBreaksSys)
  containerStraceHist <- hist(containerStrace,plot=F,breaks=mBreaksSys)

  # Draw it
  pdf(file=paste("hist_straces_",t,".pdf",sep=""),width=5, height=5)
  plot(nativeStraceHist$breaks[-1],nativeStraceHist$counts,type="l",col="black",xlim=c(minX,maxX))
  lines(containerStraceHist$breaks[-1],containerStraceHist$counts,type="l",col="red")
  dev.off()

}
