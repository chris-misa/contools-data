nums <- seq(0,9)
filePathPrefix <- "v4_native_to_target_i1.0s56_"

pings <- c()
for (n in nums) {
  filePath <- paste(filePathPrefix,n,".data",sep="")
  pings <- c(pings,scan(file=filePath,sep="\n",quiet=T))
}

pdf(file=paste("series_", filePathPrefix, ".pdf",sep=""), width=100, height=5)
plot(seq(1,length(pings)),pings,type="l")
dev.off()
