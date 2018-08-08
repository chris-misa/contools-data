arg <- "i0.5_s56_"
nums <- seq(0,4)

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

meanNative <- mean(native)
meanContainer <- mean(container)

cat("NTP Feasibility Experiment Results: RTTs as ms (dev)\n")
cat("  Native Mean:   ",meanNative, "(",sd(native),")\n")
cat("  Container Mean:",meanContainer, "(",sd(container),")\n")
cat("    Difference:  ",meanContainer - meanNative,"\n\n")
cat("  Mean NTP RTTs: ",mean(ntpRTT),"\n\n")
