"""
Get raw data from textual output of experiment

"""

import glob
import sys
import re
from decimal import Decimal

USAGE="getRawData <path to files>"

def mean(a):
  return sum(a) / Decimal(len(a)) if len(a) != 0 else 0

# Parse lines from ping report
def getRawPingData(filepath):
  outFileName = filepath + "_raw"
  rtts = []
  with open(filepath, "r") as fIn, open(outFileName, "w") as fOut:
    for line in fIn:
      m = re.match(r".* time=([0-9\.]+) ms", line)
      if m is not None:
        fOut.write(m.group(1) + "\n")
        rtts.append(Decimal(m.group(1)))
  print("Mean: " + str(mean(rtts)) + " (ms) from " + filepath)

# Parse lines from libpcap report
def getRawLatData(filepath):
  outFileName = filepath + "_raw"
  lats = []
  with open(filepath, "r") as fIn, open(outFileName, "w") as fOut:
    for line in fIn:
      m = re.match(r".* outbound: ([0-9\.]+), inbound: ([0-9\.]+)", line)
      if m is not None:
        lat = Decimal(m.group(1)) + Decimal(m.group(2))
        lat *= 1000 # convert seconds to ms for comparison with ping rtts
        lats.append(lat)
        fOut.write(str(lat) + "\n")
  print("Mean: " + str(mean(lats)) + " (ms) from " + filepath)

# Parse lines from ftrace report
def getRawLatencyData(filepath):
  outFileName = filepath + "_raw"
  lats = []
  with open(filepath, "r") as fIn, open(outFileName, "w") as fOut:
    sendTime = None
    lineNo = 1
    for line in fIn:
      m = re.match(r"send latency: ([0-9\.]+)", line)
      if m is not None:
        if sendTime is not None: # this shouldn't happen
          print("DOUBLE SEND in line " + str(lineNo))
        sendTime = Decimal(m.group(1))
      else:
        m = re.match(r"recv latency: ([0-9\.]+)", line)
        if m is not None and sendTime is not None:
          lat = sendTime + Decimal(m.group(1))
          lat *= 1000 # convert seconds to ms
          fOut.write(str(lat) + "\n")
          lats.append(lat)
          sendTime = None
        else:
          # If we expect a recv and there is a discarded recv,
          # take it so long as it is reasonable (<1000 usec)
          m = re.match(r"discarded recv: ([0-9\.]+)", line)
          if m is not None and sendTime is not None:
            recvTime = Decimal(m.group(1))
            if recvTime < 0.001:
              lat = sendTime + recvTime
              lat *= 1000 # convert seconds to ms
              fOut.write(str(lat) + "\n")
              lats.append(lat)
              sendTime = None
      lineNo += 1
  print("Mean: " + str(mean(lats)) + " (ms) from " + filepath)

def main():
  if len(sys.argv) != 2:
    print(USAGE)
    return

  l = glob.glob(sys.argv[1] + "*.ping")
  for f in l:
    getRawPingData(f)

  l = glob.glob(sys.argv[1] + "*.lat")
  for f in l:
    getRawLatData(f)

  l = glob.glob(sys.argv[1] + "*.latency")
  for f in l:
    getRawLatencyData(f)

if __name__ == "__main__":
  main()
