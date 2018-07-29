# Series of intervals and sizes determine file names to load
intervalsStr <- c(0.2, 0.3, 0.5, 1.0)
sizesStr <- c(16, 56, 120, 504, 1472)

# Graph bounds
xBounds <- range(sizesStr)
yBounds <- c(0.04,0.1)

# Colors
colors <- c("red","blue","green","black")
colI <- 1

# Set up the plot
pdf(file="meanDifferences.pdf", width=5, height=5)
plot(xBounds, yBounds, type="n", main="RTT Mean Differences", ylab="Mean Difference (sec)",xlab="Payload Size (bytes)")

# Add legend
legend(0, yBounds[2], legend=intervalsStr, col=colors, lwd=2, title="Ping Interval (sec)")

# Loop through data files
for (i in intervalsStr) {

  # Create line for this interval
  differences <- c()
  for (s in sizesStr) {
    # Read in native and container data
    native <- read.table(paste("native_v4_i", format(i,nsmall=1), "_s", s, ".data",sep=""), sep="\n")
    container <- read.table(paste("container_v4_i", format(i,nsmall=1), "_s", s, ".data",sep=""), sep="\n")

    # Compute means
    nativeMean <- mean(native[,1])
    containerMean <- mean(container[,1])
    differences <- c(differences, containerMean - nativeMean)
  }
  # Add line to plot
  lines(sizesStr, differences, type="l",col=colors[colI])
  colI <- colI + 1
}


dev.off()
