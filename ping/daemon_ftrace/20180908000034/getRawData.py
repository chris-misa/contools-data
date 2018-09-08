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

def getRawTraceData(filepath):
  outFileName = filepath + "_raw"
  lats = []
  with open(filepath, "r") as fIn, open(outFileName, "w") as fOut:
    for line in fIn:
      m = re.match(r"send: ([0-9\.]+) seconds", line)
      if m is not None:
        fOut.write(m.group(1) + "\n")
        lats.append(1000*Decimal(m.group(1)))
  print("Mean: " + str(mean(lats)) + " (ms) from " + filepath)

def main():
  if len(sys.argv) != 2:
    print(USAGE)
    return

  l = glob.glob(sys.argv[1] + "*.ping")
  for f in l:
    getRawPingData(f)

  l = glob.glob(sys.argv[1] + "*.trace")
  for f in l:
    getRawTraceData(f)


if __name__ == "__main__":
  main()
