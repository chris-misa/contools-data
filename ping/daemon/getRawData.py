"""
Get raw data from textual output of experiment

"""

import glob
import sys
import re
from decimal import Decimal

USAGE="getRawData <path to files>"

def mean(a):
  return sum(a) / Decimal(len(a))

def getRawPingData(filepath):
  outFileName = filepath + "_raw"
  rtts = []
  with open(filepath, "r") as fIn, open(outFileName, "w") as fOut:
    for line in fIn:
      m = re.match(r".* time=([0-9\.]+) ms", line)
      if m is not None:
        fOut.write(m.group(1) + "\n")
        rtts.append(Decimal(m.group(1)))
  print("Mean: " + str(mean(rtts)) + " from " + filepath)


def getRawLatData(filepath):
  outFileName = filepath + "_raw"
  lats = []
  with open(filepath, "r") as fIn, open(outFileName, "w") as fOut:
    for line in fIn:
      m = re.match(r".* outbound: ([0-9\.]+), inbound: ([0-9\.]+)", line)
      if m is not None:
        lat = Decimal(m.group(1)) + Decimal(m.group(2))
        lat *= 1000 # convert to ms for comparison with ping rtts
        lats.append(lat)
        fOut.write(str(lat) + "\n")
  print("Mean: " + str(mean(lats)) + " from " + filepath)

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


if __name__ == "__main__":
  main()
