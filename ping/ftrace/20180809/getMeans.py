"""
Import parseOutputs.py and use the results to
compute the mean time spent in syscalls and the
mean RTT reported by ping.
"""

import parseOutputs
from decimal import Decimal

def main():
  nativeStory, containerStory = parseOutputs.parse(parseOutputs.TARGETS)

  nativeSendToTimes = []
  nativeRecvMsgTimes = []
  nativePingRTTs = []

  containerSendToTimes = []
  containerRecvMsgTimes = []
  containerPingRTTs = []

  prevSend = None
  prevRecv = None
  for native in nativeStory:
    if native["gen"] == "ping":
      nativePingRTTs.append(native["RTT"])
    elif native["gen"] == "ftrace":
      if native["type"] == "enter_sendto":
        if prevSend == None:
          prevSend = native
        else:
          print("Doubled 'enter_sendto', aborting")
          return
      elif native["type"] == "exit_sendto":
        if prevSend != None:
          nativeSendToTimes.append(native["time"] - prevSend["time"])
          prevSend = None
      elif native["type"] == "enter_recvmsg":
        if prevRecv == None:
          prevRecv = native
        else:
          print("Doubled 'enter_recvmsg', aborting")
          return
      elif native["type"] == "exit_recvmsg":
        if prevRecv != None:
          if native["return"] >= 0:  # only count calls to recvmsg which return non-error status
            nativeRecvMsgTimes.append(native["time"] - prevRecv["time"])
          prevRecv = None

  prevSend = None
  prevRecv = None
  for container in containerStory:
    if container["gen"] == "ping":
      containerPingRTTs.append(container["RTT"])
    if container["gen"] == "ftrace":
      if container["type"] == "enter_sendto":
        if prevSend == None:
          prevSend = container
        else:
          print("Doubled 'enter_sendto', aborting")
          return
      elif container["type"] == "exit_sendto":
        if prevSend != None:
          containerSendToTimes.append(container["time"] - prevSend["time"])
          prevSend = None
      elif container["type"] == "enter_recvmsg":
        if prevRecv == None:
          prevRecv = container
        else:
          print("Doubled 'enter_recvmsg', aborting")
          return
      elif container["type"] == "exit_recvmsg":
        if prevRecv != None:
          if container["return"] >= 0:  # only count calls to recvmsg which return non-error status
            containerRecvMsgTimes.append(container["time"] - prevRecv["time"])
          prevRecv = None

  
  nativeSendToMean = 1000000 * sum(nativeSendToTimes) / Decimal(len(nativeSendToTimes))
  nativeRecvMsgMean = 1000000 * sum(nativeRecvMsgTimes) / Decimal(len(nativeRecvMsgTimes))
  nativePingRTTMean = 1000 * sum(nativePingRTTs) / Decimal(len(nativePingRTTs))

  containerSendToMean = 1000000 * sum(containerSendToTimes) / Decimal(len(containerSendToTimes))
  containerRecvMsgMean = 1000000 * sum(containerRecvMsgTimes) / Decimal(len(containerRecvMsgTimes))
  containerPingRTTMean = 1000 * sum(containerPingRTTs) / Decimal(len(containerPingRTTs))

  print("Native means (usec):")
  print("  sendto:   " + str(nativeSendToMean))
  print("  recvmsg:  " + str(nativeRecvMsgMean))
  print("  ping RTT: " + str(nativePingRTTMean))

  print("Container means (usec):")
  print("  sendto:   " + str(containerSendToMean))
  print("  recvmsg:  " + str(containerRecvMsgMean))
  print("  ping RTT: " + str(containerPingRTTMean))

  print("Container mean - Native mean (usec)")
  print("  sendto:   " + str(containerSendToMean - nativeSendToMean))
  print("  recvmsg:  " + str(containerRecvMsgMean - nativeRecvMsgMean))
  print("  both:     " + str((containerSendToMean - nativeSendToMean) + (containerRecvMsgMean - nativeRecvMsgMean)))
  print("  ping RTT: " + str(containerPingRTTMean - nativePingRTTMean))

  with open("native_sendto_times.data","w") as f:
    for line in nativeSendToTimes:
      f.write(str(line) + "\n")
  with open("native_recvmsg_times.data","w") as f:
    for line in nativeRecvMsgTimes:
      f.write(str(line) + "\n")
  with open("native_ping_rtts.data","w") as f:
    for line in nativePingRTTs:
      f.write(str(line) + "\n")


  with open("container_sendto_times.data","w") as f:
    for line in containerSendToTimes:
      f.write(str(line) + "\n")
  with open("container_recvmsg_times.data","w") as f:
    for line in containerRecvMsgTimes:
      f.write(str(line) + "\n")
  with open("container_ping_rtts.data","w") as f:
    for line in containerPingRTTs:
      f.write(str(line) + "\n")


if __name__ == "__main__":
  main()
