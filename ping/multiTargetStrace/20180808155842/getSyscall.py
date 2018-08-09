"""
Get RTTs

Filter out extra text in files dumped from strace
Produces a .data file with sum of corresponding sendto and recvmsg times on each line

Arguments:
  1. A file glob of input files
    (probably have to single quot this to avoid shell expansion)

"""

USAGE_STRING="Usage: python getSyscall.py <input files glob>"

import glob
import sys
import re

DEBUG = False

def main():
  if len(sys.argv) != 2:
    print(USAGE_STRING)
    return
  fileList = glob.glob(sys.argv[1])
  for fileName in fileList:
    outFileName = re.split(r"\.strace", fileName)[0] + ".data"
    with open(fileName, "r") as f, open(outFileName, "w") as outF:
      curAddr = None
      sendTime = None
      for nextLine in f:
        if curAddr == None:
          m = re.match(r".* sendto.* \= (-*[0-9]+).+<([0-9\.]+)>",nextLine)
        else:
          m = re.match(r".* recvmsg.* \= (-*[0-9]+).+<([0-9\.]+)>",nextLine)

        if m is not None and m.group(1) != "-1":
          addr = re.match(r".*sin_addr\=inet_addr\(\"([0-9\.]+)\"\).*",nextLine)
          if addr is not None:
            if curAddr is None:
              curAddr = addr.group(1)
              sendTime = m.group(2)
            else:
              if curAddr == addr.group(1):
                if DEBUG:
                  print("send " + sendTime + " recv " + m.group(2) + " from " +curAddr)
                outF.write(str(1000*(float(sendTime)+float(m.group(2)))) + "\n")
                curAddr = None
              else:
                if DEBUG:
                  print("Got different address: " + addr.group(1))
          else:
            if DEBUG:
              print("can't find addr")
        else:
          if DEBUG:
            print("unmatched: " + nextLine)
          #outF.write(m.group(2) + "\n")

if __name__ == "__main__":
  main()
