nums <- seq(0,9)

# Read in data
containerToTarget <- c()
nativeToTarget <- c()
dindContainerToContainer <- c()
dindToContainer <- c()

for (n in nums) {
  containerToTarget <- c(containerToTarget,scan(file=paste("v4_container_to_target_i1.0s56_",n,".data",sep=""), sep="\n", quiet=T))
  nativeToTarget <- c(nativeToTarget,scan(file=paste("v4_native_to_target_i1.0s56_",n,".data",sep=""), sep="\n", quiet=T))
  dindContainerToContainer <- c(dindContainerToContainer,scan(file=paste("v4_dind_container_to_container_i1.0s56_",n,".data",sep=""), sep="\n", quiet=T))
  dindToContainer <- c(dindToContainer,scan(file=paste("v4_dind_to_container_i1.0s56_",n,".data",sep=""), sep="\n", quiet=T))
}

meanContainerToTarget <- mean(containerToTarget)
meanNativeToTarget <- mean(nativeToTarget)
cat("Container to Target:", meanContainerToTarget,"(",sd(containerToTarget),")\n")
cat("Native to Target:   ", meanNativeToTarget,"(",sd(nativeToTarget),")\n")
cat("Difference:         ", meanContainerToTarget-meanNativeToTarget,"\n")
cat("Fraction:           ", meanContainerToTarget / meanNativeToTarget,"\n\n")

meanDindContainerToContainer <- mean(dindContainerToContainer)
meanDindToContainer <- mean(dindToContainer)
cat("Dind Container to Container:", meanDindContainerToContainer, "(",sd(dindContainerToContainer),")\n")
cat("Dind to Container:          ", meanDindToContainer,"(",sd(dindToContainer),")\n")
cat("Difference:                 ", meanDindContainerToContainer-meanDindToContainer,"\n")
cat("Fraction:                   ", meanDindContainerToContainer/meanDindToContainer,"\n\n")
