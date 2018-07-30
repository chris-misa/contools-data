"""
Get RTTs

Filter out extra text in files dumped from ping.
Produces a .data file with each ping's RTT printed
on a new line.

Arguments:
  1. A file glob of input files

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
    outFileName = re.split(r"\.ping", fileName)[0] + ".data"
    with open(fileName, "r") as f, open(outFileName, "w") as outF:
      for nextLine in f:
        m = re.match(r".* time=([0-9\.]+) ms",nextLine)
        if m is not None:
          rtt = m.group(1)
          outF.write(rtt + "\n")

if __name__ == "__main__":
  main()
