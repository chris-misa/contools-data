intervals <- c("1.0", "0.8", "0.6", "0.4")
# All payloads are 120 bytes
nums <- seq(0,9)

cat("All payloads, 120 bytes\n\n")

# For each interval
for (i in intervals) {

  # Read in data
  containerToTarget <- c()
  nativeToTarget <- c()
  dindContainerToContainer <- c()
  dindToContainer <- c()

  for (n in nums) {
    containerToTarget <- c(containerToTarget,scan(file=paste("rawFiles/v4_container_to_target_i",i,"s120_",n,".data",sep=""), sep="\n", quiet=T))
    nativeToTarget <- c(nativeToTarget,scan(file=paste("rawFiles/v4_native_to_target_i1.0s120_",n,".data",sep=""), sep="\n", quiet=T))
    dindContainerToContainer <- c(dindContainerToContainer,scan(file=paste("rawFiles/v4_dind_container_to_container_i",i,"s120_",n,".data",sep=""), sep="\n", quiet=T))
    dindToContainer <- c(dindToContainer,scan(file=paste("rawFiles/v4_dind_to_container_i",i,"s120_",n,".data",sep=""), sep="\n", quiet=T))
  }

  cat("Ping at",i,"second intervals: mean (deviation) in ms\n")
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
  cat(" From",length(containerToTarget),"packets\n\n")
}
