tests <- c("container_container", "container_host", "container_target", "host_host", "native_target")
intervals <- c("i0.1", "i0.3", "i0.5", "i1.0")
sizes <- c("s16", "s56", "s120")
numbers <- paste(seq(1,20),".data",sep="")

mbreaks <- seq(0,2,0.001)
xrange <- c(0,0.4)

for (test in tests) {
  for (i in intervals) {
    for (s in sizes) {
      pings <- c()
      for (n in numbers) {
        filePath <- paste("rawFiles/", paste("v4",test,i,s,n,sep="_"), sep="")
        pings <- c(pings, scan(file=filePath, sep="\n", quiet=T))
      }
      pdf(paste("v4",test,i,s,".pdf",sep="_"), width=5, height=5)
      hist(pings, breaks=mbreaks, xlim=xrange)
      dev.off()
    }
  }
}
