args <- "i0.5s56"

n_seq <- c(100,200,300,400,500,600,700,800,900,1000)

# Sequence of breaks in histogram
mBinSize <- 0.001
mBreaks <- seq(0,2,mBinSize)
mYLabel <- paste("Count (",mBinSize,") ms bins",sep="")

# X-Boundary for graph
xBounds <- c(0.05, 0.15)

# Read in native and container data
native <- read.table(paste("nativeping_target_v4_",args,".data",sep=""), sep="\n")
container <- read.table(paste("containerping_target_v4_",args,".data",sep=""), sep="\n")

for (n in n_seq) {
  nativeHist <- hist(native[1:n,1], plot=F, breaks=mBreaks)
  containerHist <- hist(container[1:n,1], plot=F, breaks=mBreaks)

  pdf(file=paste("prog_native_container_",args,"_n",n,".pdf",sep=""), width=5, height=5)
  heading <- paste("First",n,"of",args)
  yMax <- max(nativeHist$counts, containerHist$counts)
  yBounds <- c(0,yMax)
  plot(nativeHist$breaks[-1], nativeHist$counts, type="l", main=heading, xlim=xBounds, ylim=yBounds)
  lines(containerHist$breaks[-1], containerHist$counts, type="l", col="blue", xlim=xBounds, ylim=yBounds)
  dev.off()
}
