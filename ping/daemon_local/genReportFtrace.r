args = commandArgs(trailingOnly=T)
USAGE <- "Usage: rscript genReport.r <directory containing _raw data files"

if (length(args) != 1) {
  stop(USAGE);
}

PREFIX <- args[1]
TARGET <- "10.0.0.1"

containerControl <- scan(file=paste(PREFIX, "container_control_", TARGET,
  ".ping_raw", sep=""), sep="\n", quiet=T)

nativeControl <- scan(file=paste(PREFIX, "native_control_", TARGET,
  ".ping_raw", sep=""), sep="\n", quiet=T)

containerMonitored <- scan(file=paste(PREFIX, "container_monitored_", TARGET,
  ".ping_raw", sep=""), sep="\n", quiet=T)

nativeMonitored <- scan(file=paste(PREFIX, "native_monitored_", TARGET,
  ".ping_raw", sep=""), sep="\n", quiet=T)

pcapLatencies <- scan(file=paste(PREFIX, "container_monitored_", TARGET,
  ".latency_raw", sep=""), sep="\n", quiet=T)

getStats <- function(d) {
  if (length(d) == 0) {
    c(0,0,0,0)
  } else {
    c(min(d), mean(d), max(d), sd(d))
  }
}

subStats <- function(a,b) {
  if (length(a) == 0) {
    b
  } else if (length(b) == 0) {
    a
  } else {
    # deviations add!
    c(a[1] - b[1], a[2] - b[2], a[3] - b[3], a[4] + b[4])
  }
}

stats2String <- function(s) {
  paste(s[1], "/", s[2], "/", s[3], "(", s[4], ")")
}

cat("ftrace latency results\n")
cat("for", PREFIX, "target:", TARGET)
cat("  control:\n")
cat("    native RTT:         ", stats2String(getStats(nativeControl)), "\n")
cat("    container RTT:      ", stats2String(getStats(containerControl)), "\n")
cat("    difference:         ", stats2String(subStats(getStats(containerControl), getStats(nativeControl))), "\n")
cat("  traced:\n")
cat("    native RTT:         ", stats2String(getStats(nativeMonitored)), "\n")
cat("    container RTT:      ", stats2String(getStats(containerMonitored)), "\n")
cat("    difference:         ", stats2String(subStats(getStats(containerMonitored), getStats(nativeMonitored))), "\n")

cat("\n")
cat("  estimated RTT latency:", stats2String(getStats(pcapLatencies)), "\n")
