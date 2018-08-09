targets <- c("127.0.0.1", "128.110.153.106", "128.223.142.244", "140.197.253.0", "162.252.70.155", "198.71.45.230")

cat("Multitarget with strace profiling\n\n")

cat("RTTs: mean (dev)\n")

for (t in targets) {
  native <- scan(paste("rawFiles/strace_native_",t,".data",sep=""),sep="\n",quiet=T)
  container <- scan(paste("rawFiles/strace_container_",t,".data",sep=""),sep="\n",quiet=T)
  nativeControl <- scan(paste("rawFiles/control_native_",t,".data",sep=""),sep="\n",quiet=T)
  containerControl <- scan(paste("rawFiles/control_container_",t,".data",sep=""),sep="\n",quiet=T)
  nativeStrace <- scan(paste("rawFiles/native_",t,".data",sep=""),sep="\n",quiet=T)
  containerStrace <- scan(paste("rawFiles/container_",t,".data",sep=""),sep="\n",quiet=T)


  
  meanNative <- mean(native)
  sdNative <- sd(native)
  meanContainer <- mean(container)
  sdContainer <- sd(container)
  meanNativeControl <- mean(nativeControl)
  sdNativeControl <- sd(nativeControl)
  meanContainerControl <- mean(containerControl)
  sdContainerControl <- sd(containerControl)
  meanNativeStrace <- mean(nativeStrace)
  sdNativeStrace <- sd(nativeStrace)
  meanContainerStrace <- mean(containerStrace)
  sdContainerStrace <- sd(containerStrace)

  cat("  Target:",t,"\n")
  cat("    Control:\n")
  cat("      native:   ",meanNativeControl,"(",sdNativeControl,")\n")
  cat("      container:",meanContainerControl,"(",sdContainerControl,")\n")
  cat("      diff:     ",meanContainerControl - meanNativeControl,"\n")
  cat("    Instrumented (with strace):\n")
  cat("      native:   ",meanNative,"(",sdNative,")\n")
  cat("      container:",meanContainer,"(",sdContainer,")\n")
  cat("      diff:     ",meanContainer-meanNative,"\n")
  cat("    Time spent in sendto and recvmsg syscalls:\n")
  cat("      native:   ",meanNativeStrace,"(",sdNativeStrace,")\n")
  cat("      container:",meanContainerStrace,"(",sdContainerStrace,")\n\n")
}
