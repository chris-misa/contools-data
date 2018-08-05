tests <- c("container_container", "container_host", "container_target", "host_host", "native_target")
intervals <- c("i0.1", "i0.3", "i0.5", "i1.0")
sizes <- c("s16", "s56", "s120")
numbers <- paste(seq(1,20),".data",sep="")

mbreaks <- seq(0,2,0.001)
xrange <- c(0,0.4)
measuredBias <- c()

for (i in intervals) {
  for (s in sizes) {
    cat("Interval:", i, "Payload Size:", s, "\n")
    means <- c()
    for (test in tests) {
      pings <- c()
      for (n in numbers) {
        filePath <- paste("rawFiles/", paste("v4",test,i,s,n,sep="_"), sep="")
        pings <- c(pings, scan(file=filePath, sep="\n", quiet=T))
      }
      means[test] <- mean(pings)
      cat(sprintf("%-20s mean: %f dev %f\n", test, means[test], sd(pings)))
    }
    mb <- means["container_target"] - means["native_target"]
    cat(sprintf("Measured Bias: %f\n", mb))
    measuredBias[paste(i,s,sep="_")] <- mb
    cat("\n")
  }
}
