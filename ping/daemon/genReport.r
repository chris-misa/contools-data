PREFIX <- "20180904173619/"
TARGET <- "10.10.1.2"

containerControl <- scan(file=paste(PREFIX, "container_control_", TARGET,
  ".ping_raw", sep=""), sep="\n", quiet=T)

nativeControl <- scan(file=paste(PREFIX, "native_control_", TARGET,
  ".ping_raw", sep=""), sep="\n", quiet=T)

containerMonitored <- scan(file=paste(PREFIX, "container_monitored_", TARGET,
  ".ping_raw", sep=""), sep="\n", quiet=T)

nativeMonitored <- scan(file=paste(PREFIX, "native_monitored_", TARGET,
  ".ping_raw", sep=""), sep="\n", quiet=T)

pcapLatencies <- scan(file=paste(PREFIX, "container_monitored_", TARGET,
  ".lat_raw", sep=""), sep="\n", quiet=T)

getStats <- function(d) {
  c(min(d), mean(d), max(d), sd(d))
}

stats2String <- function(s) {
  paste(s[1], "/", s[2], "/", s[3], "(", s[4], ")")
}

cat("pcap trace latency results\n")
cat("for", PREFIX, "target:", TARGET)
cat("  control:\n")
cat("    native RTT:         ", stats2String(getStats(nativeControl)), "\n")
cat("    container RTT:      ", stats2String(getStats(containerControl)), "\n")
cat("    difference:         ", stats2String(getStats(containerControl)
    - getStats(nativeControl)), "\n")
cat("  traced:\n")
cat("    native RTT:         ", stats2String(getStats(nativeMonitored)), "\n")
cat("    container RTT:      ", stats2String(getStats(containerMonitored)), "\n")
cat("    difference:         ", stats2String(getStats(containerMonitored)
    - getStats(nativeMonitored)), "\n")

cat("\n")
cat("  estimated RTT latency:", stats2String(getStats(pcapLatencies)), "\n")
