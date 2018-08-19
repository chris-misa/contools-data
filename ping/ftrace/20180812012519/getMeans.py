"""
Get mean time values from a list of transactions
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

from events import getTransactions, computeDiffs
from decimal import Decimal

"""
Returns a tuple with interesting means computed accross the given
transactions.
"""
def getMeans(transactions):
  sendToSum = Decimal(0)
  recvMsgSum = Decimal(0)
  rttSum = Decimal(0)
  n = Decimal(len(transactions))
  # Compute time differences and convert to usec from events.py
  map(computeDiffs, transactions)
  for trans in transactions:
    sendToSum += trans["sendto_time"]
    recvMsgSum += trans["recvmsg_time"]
    rttSum += trans["ping_rtt"]
  return (sendToSum / n, recvMsgSum / n, rttSum / n)


def main():
  print("System call time line vs. Ping reported RTT")
  print("all numbers are mean micro-seconds")
  for setting in SETTINGS:
    print("Ping flags: " + setting)
    print("  Native at " + TARGET_IPV4)
    native = getTransactions(PREFIX + "v4_native_" + TARGET_IPV4 + "_" + setting)
    nativeSendToMean, nativeRecvMsgMean, nativePingRTTMean \
        = getMeans(native)
    print("    sendto:   " + str(nativeSendToMean))
    print("    recvmsg:  " + str(nativeRecvMsgMean))
    print("    ping RTT: " + str(nativePingRTTMean))

    print("  Container at " + TARGET_IPV4)
    container = getTransactions(PREFIX + "v4_container_" + TARGET_IPV4 + "_" + setting)
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
      container = getTransactions(PREFIX + "v4_container_" + target + "_" + setting)
      containerSendToMean, containerRecvMsgMean, containerPingRTTMean \
          = getMeans(container)
      print("      sendto:   " + str(containerSendToMean))
      print("      recvmsg:  " + str(containerRecvMsgMean))
      print("      ping RTT: " + str(containerPingRTTMean))

if __name__ == "__main__":
  main()
