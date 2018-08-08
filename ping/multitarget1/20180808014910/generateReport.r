targets <- c(
  "127.0.0.1",
  "128.110.103.241",
  "140.197.253.0",
  "198.71.45.230",
  "162.252.70.155",
  "128.223.142.224"
)

cat("Multitarget ping RTT: in ms (dev)\n")

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
