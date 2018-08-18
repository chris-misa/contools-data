"""
Computes mean values of all interesting time for each
setting.
"""
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

import parseOutputs as po
from decimal import Decimal

"""
Split the story into sendto, recvmsg, and ping RTT durations

Arguments:
  A list of events as returned by parse.

Return:
  Tuple with sendto list, recvmsg list, ping RTT list
"""
def getTimes(story):
  sendToTimes = []
  recvMsgTimes = []
  pingRTTs = []
  prevSend = None
  prevRecv = None
  firstFtrace = False
  for event in story:
    if event["gen"] == "ping" and firstFtrace:
      pingRTTs.append(event["RTT"])
    elif event["gen"] == "ftrace":
      firstFtrace = True
      if event["type"] == "enter_sendto":
        if prevSend == None:
          prevSend = event
        else:
          print("Doubled 'enter_sendto' aborting getMeans()")
          return
      elif event["type"] == "exit_sendto":
        if prevSend != None:
          sendToTimes.append(event["time"] - prevSend["time"])
          prevSend = None
      elif event["type"] == "enter_recvmsg":
        if prevRecv == None:
          prevRecv = event
        else:
          print("Doubled 'enter_recvmsg' aborting getMeans()")
          return
      elif event["type"] == "exit_recvmsg":
        if prevRecv != None:
          if event["return"] >= 0: # only count calls to recvmgs which return ok
            recvMsgTimes.append(event["time"] - prevRecv["time"])
          prevRecv = None
  return (sendToTimes, recvMsgTimes, pingRTTs)

"""
Returns the mean of a list of Decimal objects (numbers)
"""
def mean(elems):
  return sum(elems) / Decimal(len(elems))

"""
Uses getTimes to extract times then return the means in the same order
Converts seconds and ms to us.
"""
def getMeans(story):
  sendToTimes, recvMsgTimes, pingRTTs = getTimes(story)
  return 1000000 * mean(sendToTimes), \
         1000000 * mean(recvMsgTimes), \
         1000 * mean(pingRTTs)


def main():
  print("System call time vs reported RTT time in ping")
  print("all numbers are mean micro-seconds")
  for setting in SETTINGS:
    print("Ping flags: " + setting)
    print("  Native at " + TARGET_IPV4)
    native = po.parse(PREFIX + "v4_native_" + TARGET_IPV4 + "_" + setting)
    nativeSendToMean, nativeRecvMsgMean, nativePingRTTMean \
        = getMeans(native)
    print("    sendto:   " + str(nativeSendToMean))
    print("    recvmsg:  " + str(nativeRecvMsgMean))
    print("    ping RTT: " + str(nativePingRTTMean))

    print("  Container at " + TARGET_IPV4)
    container = po.parse(PREFIX + "v4_container_" + TARGET_IPV4 + "_" + setting)
    containerSendToMean, containerRecvMsgMean, containerPingRTTMean \
        = getMeans(container)
    print("    sendto:   " + str(containerSendToMean))
    print("    recvmsg:  " + str(containerRecvMsgMean))
    print("    ping RTT: " + str(containerPingRTTMean))

    print("  Container, native differences:")
    sendToDiff = containerSendToMean - nativeSendToMean
    recvMsgDiff = containerRecvMsgMean - nativeRecvMsgMean
    pingRTTDiff = containerPingRTTMean - nativePingRTTMean
    print("  / sendto:           " + str(sendToDiff))
    print("  / recvmsg:          " + str(recvMsgDiff))
    print("  / ping RTT:         " + str(pingRTTDiff))
    print("  / sendto + recvmsg: " + str(sendToDiff + recvMsgDiff))


    print("  Other container targets:")
    for target in CONTAINER_TARGETS_IPV4[1:]:
      print("    Container at " + target)
      container = po.parse(PREFIX + "v4_container_" + target + "_" + setting)
      containerSendToMean, containerRecvMsgMean, containerPingRTTMean \
          = getMeans(container)
      print("      sendto:   " + str(containerSendToMean))
      print("      recvmsg:  " + str(containerRecvMsgMean))
      print("      ping RTT: " + str(containerPingRTTMean))

if __name__ == "__main__":
  main()
