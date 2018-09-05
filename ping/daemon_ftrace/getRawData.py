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


def main():
  if len(sys.argv) != 2:
    print(USAGE)
    return

  l = glob.glob(sys.argv[1] + "*.ping")
  for f in l:
    getRawPingData(f)


if __name__ == "__main__":
  main()
