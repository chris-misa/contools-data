sizes <- c("120", "56")
# All intervals are 0.5 seconds
nums <- seq(0,9)

cat("Ping interval 0.5 seconds\n\n")

# For each interval
for (s in sizes) {

  # Read in data
  containerToTarget <- c()
  nativeToTarget <- c()
  dindContainerToContainer <- c()
  dindToContainer <- c()

  for (n in nums) {
    containerToTarget <- c(containerToTarget,scan(file=paste("rawFiles/v4_container_to_target_i0.5s",s,"_",n,".data",sep=""), sep="\n", quiet=T))
    nativeToTarget <- c(nativeToTarget,scan(file=paste("rawFiles/v4_native_to_target_i0.5s",s,"_",n,".data",sep=""), sep="\n", quiet=T))
    dindContainerToContainer <- c(dindContainerToContainer,scan(file=paste("rawFiles/v4_dind_container_to_container_i0.5s",s,"_",n,".data",sep=""), sep="\n", quiet=T))
    dindToContainer <- c(dindToContainer,scan(file=paste("rawFiles/v4_dind_to_container_i0.5s",s,"_",n,".data",sep=""), sep="\n", quiet=T))
  }

  cat("Ping with",s,"byte payloads: mean (deviation) in ms\n")
  meanContainerToTarget <- mean(containerToTarget)
  meanNativeToTarget <- mean(nativeToTarget)
  cat(" Container to Target:", meanContainerToTarget,"(",sd(containerToTarget),")\n")
  cat(" Native to Target:   ", meanNativeToTarget,"(",sd(nativeToTarget),")\n")
  cat(" Difference:         ", meanContainerToTarget-meanNativeToTarget,"\n")
  cat(" Fraction:           ", meanContainerToTarget / meanNativeToTarget,"\n\n")

  meanDindContainerToContainer <- mean(dindContainerToContainer)
  meanDindToContainer <- mean(dindToContainer)
  cat(" Dind Container to Container:", meanDindContainerToContainer, "(",sd(dindContainerToContainer),")\n")
  cat(" Dind to Container:          ", meanDindToContainer,"(",sd(dindToContainer),")\n")
  cat(" Difference:                 ", meanDindContainerToContainer-meanDindToContainer,"\n")
  cat(" Fraction:                   ", meanDindContainerToContainer/meanDindToContainer,"\n\n")
  cat(" From",length(containerToTarget),"packets in each path\n\n")
}
