"""
Parse Outputs From Ftrace experiment

Looks for files in rawFile/ for each given target value.

"""

TARGETS=["10.10.1.2"]
PREFIX="rawFiles/"

import sys
import re
import pprint
from decimal import Decimal

"""
Parse a single line from a ping dump file

Returns a dictionary with
  "time": timeofday style time stamp (float) in seconds
  "RTT":  round trip time reported by ping (float) in ms
or None if the line does not contain this information.
"""
def parsePingLine(l):
  m = re.match(r"\[([0-9\.]+)\] .* time=([0-9\.]+) ms", l)
  return {"time": Decimal(m.group(1)), "RTT": Decimal(m.group(2))} \
      if m != None else None

"""
Parse a single line from a tcpdump translated pcap file

Returns a dictionary with
  "time": timeofday style time stamp (float) in seconds
  "type": "request" | "reply"
or None if the line does not contain this information.
"""
def parseTcpdumpLine(l):
  m = re.match(r"([0-9\.]+) .* ICMP echo (request|reply).*", l)
  return {"time": Decimal(m.group(1)), "type": m.group(2)} \
      if m != None else None

"""
Parse a single line from an ftrace translated .dat file

Returns a dictionary with
  "time": timeofday style time stamp (float) in seconds
  "type": "enter_sendto" | "exit_sendto" | "enter_recvmsg"
          | "exit_recvmsg"
  ["return": if type is "exit_*" this field contains the return value]
or None if the line does not contain this information.

Notes:
  only returns lines starting with "ping-*"
  assumes we're using 64 byte ints for return values
"""
def parseFtraceLine(l):
  m = re.match(r" +ping-[0-9]+ \[[0-9]+\] ([0-9\.]+): sys_(enter_sendto|exit_sendto|enter_recvmsg|exit_recvmsg):(.*)", l)
  if m != None:
    n = re.match(r" *(0x[0-9a-fA-F]+)", m.group(3))
    if m.group(2) == "exit_recvmsg" and n != None:
      retVal = int(n.group(1),0)
      retVal = (retVal & 0x7fffffffffffffff) \
          - (retVal & 0x8000000000000000)
      return {"time": Decimal(m.group(1)), "type": m.group(2), \
              "return": retVal}
    else:
      return {"time": Decimal(m.group(1)), "type": m.group(2) }
  else:
    return None

"""
Main function for parseOutputs.py
"""
def main():
  for target in TARGETS:
    nativeEvents = []
    with open(PREFIX+"v4_native_"+target+".ping") as nativePings:
      for line in nativePings:
        prsLine = parsePingLine(line)
        if prsLine != None:
          nativeEvents.append(prsLine)
    with open(PREFIX+"v4_native_"+target+".tcpdump") as nativeDump:
      for line in nativeDump:
        prsLine = parseTcpdumpLine(line)
        if prsLine != None:
          nativeEvents.append(prsLine)
    with open(PREFIX+"v4_native_"+target+".ftrace") as nativeTrace:
      for line in nativeTrace:
        prsLine = parseFtraceLine(line)
        if prsLine != None:
          nativeEvents.append(prsLine)
    nativeEvents.sort(key=lambda(e): e["time"])
    pprint.pprint(nativeEvents)

if __name__ == "__main__":
  main()
