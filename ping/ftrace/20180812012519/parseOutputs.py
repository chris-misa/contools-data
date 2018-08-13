"""
Parse Outputs From Ftrace experiment

Looks for files in rawFile/ for each given target value.

"""

# Following structure of contools-ftrace/run.sh
TARGET_IPV4="10.10.1.2"
CONTAINER_TARGETS_IPV4=[TARGET_IPV4, "172.17.0.1", "10.10.1.1"]

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
  "gen": "ping"
or None if the line does not contain this information.
"""
def parsePingLine(l):
  m = re.match(r"\[([0-9\.]+)\] .* time=([0-9\.]+) ms", l)
  return {"time": Decimal(m.group(1)), \
          "RTT": Decimal(m.group(2)), \
          "gen": "ping"} \
      if m != None else None

"""
Parse a single line from an ftrace translated .dat file

Returns a dictionary with
  "time": timeofday style time stamp (float) in seconds
  "type": "enter_sendto" | "exit_sendto" | "enter_recvmsg"
          | "exit_recvmsg"
  ["return": if type is "exit_*" this field contains the return value]
  "gen": "ftrace"
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
      return {"time": Decimal(m.group(1)), \
              "type": m.group(2), \
              "return": retVal, \
              "gen": "ftrace"}
    else:
      return {"time": Decimal(m.group(1)), \
              "type": m.group(2), \
              "gen": "ftrace"}
  else:
    return None

"""
Parse the files for the given target.

Arguments:
  target: file path for this target up to the extentions (.ping or .ftrace)

Returns:
  A list of events in chronological order.

"""
def parse(target):
  events = []
  with open(target+".ping") as pings:
    for line in pings:
      prsLine = parsePingLine(line)
      if prsLine != None:
        events.append(prsLine)
  with open(target+".ftrace") as trace:
    for line in trace:
      prsLine = parseFtraceLine(line)
      if prsLine != None:
        events.append(prsLine)
  events.sort(key=lambda(e): e["time"])

  # Return
  return events


"""
A temporary main to check that parse is working
"""
def main():
  nativeStory = parse("rawFiles/v4_native_"+TARGET_IPV4+"_i0.5_s56")
  print("Native Story:")
  pprint.pprint(nativeStory)
  containerStory = parse("rawFiles/v4_container_"+TARGET_IPV4+"_i0.5_s56")
  print("\n\nContainer Story:")
  pprint.pprint(containerStory)

if __name__ == "__main__":
  main()
