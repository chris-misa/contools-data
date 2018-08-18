"""
Parse the event stream into logical
transactions.
"""

import parseOutputs as po
from pprint import pprint
from decimal import Decimal

NEVENTS = 0

# Omit the first run (-s 8) because it is too small for RTT data
SETTINGS = ["i0.5_s24",
            "i0.5_s56",
            "i0.5_s120",
            "i0.5_s248",
            "i0.5_s504",
            "i0.5_s1016"]

TARGET_IPV4 = "10.10.1.2"
CONTAINER_TARGETS_IPV4=[TARGET_IPV4, "172.17.0.1", "10.10.1.1"]

PREFIX="rawFiles/"

"""
Parse the sendto events
"""
def getSendTo(x):
  e, i, d = x
  while e[i]["gen"] != "ftrace" \
      or e[i]["type"] != "enter_sendto":
    i += 1
  d["enter_sendto"] = e[i]["time"]
  i += 1
  while i < NEVENTS \
      and e[i]["gen"] != "ftrace" \
      or e[i]["type"] != "exit_sendto":
    i += 1
  d["exit_sendto"] = e[i]["time"]
  i += 1
  return (e, i, d)

"""
Parse the recvmsg events
"""
def getRecvMsg(x):
  e, i, d = x
  while i < NEVENTS \
      and e[i]["gen"] != "ftrace" \
      or e[i]["type"] != "enter_recvmsg":
    i += 1
  d["enter_recvmsg"] = e[i]["time"]
  i += 1
  while i < NEVENTS \
      and e[i]["gen"] != "ftrace" \
      or e[i]["type"] != "exit_recvmsg":
    i += 1
    # Make sure the recvmsg didn't fail
    # If it did, look for the next one
    if e[i]["return"] < 0:
      print("First recvmsg after send failed, looking further")
      return getRecvMsg((e, i, d))
  d["exit_recvmsg"] = e[i]["time"]
  i += 1
  return (e, i, d)

"""
Parse the ping event
and convert to microseconds
"""
def getPing(x):
  e, i, d = x
  while i < NEVENTS \
      and e[i]["gen"] != "ping":
    i += 1
  d["ping_rtt"] = Decimal(e[i]["RTT"]) * 1000
  i += 1
  return (e, i, d)

"""
Compute durations between events in a given ping transaction
and convert into micro seconds.
"""
def computeDiffs(event):
  event["sendto_time"] = (event["exit_sendto"] - event["enter_sendto"]) * 1000000
  event["stall_time"] = (event["enter_recvmsg"] - event["exit_sendto"]) * 1000000
  event["recvmsg_time"] = (event["exit_recvmsg"] - event["enter_recvmsg"]) * 1000000

"""
Print a human-readable formated event
"""
def printEvent(event):
  print("sendto_time:  " + str(event["sendto_time"]))
  print("stall_time:   " + str(event["stall_time"]))
  print("recvmsg_time: " + str(event["recvmsg_time"]))
  print("  sum:        " + str(event["sendto_time"] + event["stall_time"] + event["recvmsg_time"]))
  print("Ping RTT:     " + str(event["ping_rtt"]))

"""
Call parse in parseOutputs module to get data from all files
then parse into transactions.
"""
def getTransactions(fileName):
  global NEVENTS
  events = po.parse(fileName)
  NEVENTS = len(events)
  transactions = []
  i = 0
  while i < NEVENTS - 10: # slopppppy bounds checking needs to be replaced
    _, i, trans = getPing(getRecvMsg(getSendTo((events, i, {}))))
    transactions.append(trans)
  return transactions

"""
Pick a file and pprint it's events
"""
def main():
  fileName = PREFIX + "v4_native_" + TARGET_IPV4 + "_" + SETTINGS[0]
  print("Reading: " + fileName)
  transactions = getTransactions(fileName)
  print("Got " + str(len(transactions)) + " pings")
  map(computeDiffs, transactions)
  for trans in transactions:
    printEvent(trans)
    print(" ")

if __name__ == "__main__":
  main()
