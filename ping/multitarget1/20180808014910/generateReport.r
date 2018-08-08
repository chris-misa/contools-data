targets <- c(
  "128.110.103.241",
  "140.197.253.0",
  "198.71.45.230",
  "162.252.70.155",
  "128.223.142.224"
)

cat("Multitarget ping RTT: in ms (dev)\n\n")

nativeLo <- scan("native_127.0.0.1.data",sep="\n",quiet=T)
meanNativeLo <- mean(nativeLo)
sdNativeLo <- sd(nativeLo)
cat("  Native loopback:    ",meanNativeLo,"(",sdNativeLo,")\n")

containerLo <- scan("container_127.0.0.1.data",sep="\n",quiet=T)
meanContainerLo <- mean(containerLo)
sdContainerLo <- sd(containerLo)
cat("  Container loopback: ",meanContainerLo,"(",sdContainerLo,")\n")

bridge <- scan("container_bridge.data",sep="\n",quiet=T)
meanBridge <- mean(bridge)
sdBridge <- sd(bridge)
cat("  Container to bridge:",meanBridge,"(",sdBridge,")\n\n")

for (t in targets) {
  native <- scan(paste("native_",t,".data",sep=""),sep="\n",quiet=T)
  container <- scan(paste("container_",t,".data",sep=""),sep="\n",quiet=T)
  meanNative <- mean(native)
  sdNative <- sd(native)
  meanContainer <- mean(container)
  sdContainer <- sd(container)
  diff <- meanContainer - meanNative
  cat("  Target:",t,"\n")
  cat("    Native:   ",meanNative,"(",sdNative,")\n")
  cat("    Container:",meanContainer,"(",sdContainer,")\n")
  cat("    diff:     ",diff,"\n")
  cat("    diff / container deviation:",round(100*diff/sdContainer,digits=2),"%\n\n")
}
