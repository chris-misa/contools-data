arg <- "i0.5_s56_"
nums <- seq(0,9)

# IPv4 . . .

# Input and agregate data
controlNative <- c()
controlContainer <- c()
native <- c()
container <- c()

# Read in ping data
for (n in nums) {
  controlNative <- c(controlNative, scan(file=paste("rawFiles/v4_control_native_target",arg,n,".data",sep=""), sep="\n", quiet=T))
  controlContainer <- c(controlContainer, scan(file=paste("rawFiles/v4_control_container_target",arg,n,".data",sep=""), sep="\n", quiet=T))
  native <- c(native, scan(file=paste("rawFiles/v4_native_target",arg,n,".data",sep=""), sep="\n", quiet=T))
  container <- c(container, scan(file=paste("rawFiles/v4_container_target",arg,n,".data",sep=""), sep="\n", quiet=T))
}

# Read in biases computed by getBiases.py
biases <- scan(file="v4_biases.data",sep="\n",quiet=T)

# Output some perhaps interesting things
meanControlNative <- mean(controlNative)
sdControlNative <- sd(controlNative)
meanControlContainer <- mean(controlContainer)
sdControlContainer <- sd(controlContainer)
meanNative <- mean(native)
sdNative <- sd(native)
meanContainer <- mean(container)
sdContainer <- sd(container)
cat("Pcap Dump Strategy 1 Report for ping",arg,"\n\n")
cat("IPv4:\n\n")
cat(" Control: mean (deviation) in ms\n")
cat("  native:    ",meanControlNative,"(",sdControlNative,")\n")
cat("  container: ",meanControlContainer,"(",sdControlContainer,")\n")
cat("  difference:",meanControlContainer - meanControlNative)
cat("\n\n")
cat(" Instrumented: mean (deviation) in ms\n")
cat("  native:    ",meanNative,"(",sdNative,")\n")
cat("  container: ",meanContainer,"(",sdContainer,")\n")
cat("  difference:",meanContainer - meanNative)
cat(" \n\n")
cat(" Estimated RTT bias: mean (deviation) in ms\n")
cat("  ",mean(biases),"(",sd(biases),")\n\n")
cat(" Agregated across",length(controlNative),"packets in each path.\n\n")

# IPv6 . . .
# Input and agregate data
controlNative <- c()
controlContainer <- c()
native <- c()
container <- c()

# Read in ping data
for (n in nums) {
  controlNative <- c(controlNative, scan(file=paste("rawFiles/v6_control_native_target",arg,n,".data",sep=""), sep="\n", quiet=T))
  controlContainer <- c(controlContainer, scan(file=paste("rawFiles/v6_control_container_target",arg,n,".data",sep=""), sep="\n", quiet=T))
  native <- c(native, scan(file=paste("rawFiles/v6_native_target",arg,n,".data",sep=""), sep="\n", quiet=T))
  container <- c(container, scan(file=paste("rawFiles/v6_container_target",arg,n,".data",sep=""), sep="\n", quiet=T))
}

# Read in biases computed by getBiases.py
biases <- scan(file="v6_biases.data",sep="\n",quiet=T)

# Output some perhaps interesting things
meanControlNative <- mean(controlNative)
sdControlNative <- sd(controlNative)
meanControlContainer <- mean(controlContainer)
sdControlContainer <- sd(controlContainer)
meanNative <- mean(native)
sdNative <- sd(native)
meanContainer <- mean(container)
sdContainer <- sd(container)
cat("Pcap Dump Strategy 1 Report for ping",arg,"\n\n")
cat("IPv6:\n\n")
cat(" Control: mean (deviation) in ms\n")
cat("  native:    ",meanControlNative,"(",sdControlNative,")\n")
cat("  container: ",meanControlContainer,"(",sdControlContainer,")\n")
cat("  difference:",meanControlContainer - meanControlNative)
cat("\n\n")
cat(" Instrumented: mean (deviation) in ms\n")
cat("  native:    ",meanNative,"(",sdNative,")\n")
cat("  container: ",meanContainer,"(",sdContainer,")\n")
cat("  difference:",meanContainer - meanNative)
cat(" \n\n")
cat(" Estimated RTT bias: mean (deviation) in ms\n")
cat("  ",mean(biases),"(",sd(biases),")\n\n")
cat(" Agregated across",length(controlNative),"packets in each path.\n\n")

