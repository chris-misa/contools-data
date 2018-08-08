targets <- c("127.0.0.1", "128.110.103.241", "128.223.142.224", "140.197.253.0", "162.252.70.155", "198.71.45.230")

for (t in targets) {
  native <- scan(paste("native_",t,".data",sep=""),sep="\n",quiet=T)
  container <- scan(paste("container_",t,".data",sep=""),sep="\n",quiet=T)
  pdf(file=paste("hist_",t,".pdf",sep=""),width=5,height=5)
  nativeHist <- hist(native, plot=F,breaks=100)
  containerHist <- hist(container, plot=F,breaks=100)
  plot(nativeHist$breaks[-1],nativeHist$counts,type="l",col="black")
  lines(containerHist$breaks[-1],containerHist$counts,type="l",col="red")
  dev.off()
}
