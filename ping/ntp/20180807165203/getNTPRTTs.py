"""
Get RTTs

Filter out extra text in files dumped from ntpPing
and add outbound and inbound delays to get an estimate RTT

Arguments:
  1. A file glob of input files
    (probably have to single quot this to avoid shell expansion)

"""

USAGE_STRING="Usage: python getRTTs.py <input files glob>"

import glob
import sys
import re

def main():
  if len(sys.argv) != 2:
    print(USAGE_STRING)
    return
  fileList = glob.glob(sys.argv[1])
  for fileName in fileList:
    outFileName = re.split(r"\.txt", fileName)[0] + ".data"
    with open(fileName, "r") as f, open(outFileName, "w") as outF:
      for nextLine in f:
        m = re.match(r".* Outbound Bias: +([0-9\.]+)",nextLine)
        if m is not None:
          outBound = float(m.group(1))
        else:
          m = re.match(r".* Inbound Bias: +([0-9\.]+)",nextLine)
          if m is not None:
            inBound = float(m.group(1))
            if outBound == None:
              print("in / out bound mis-match!")
              return
            outF.write(str(outBound+inBound)+"\n")
            inBound = None
            outBound = None

if __name__ == "__main__":
  main()
