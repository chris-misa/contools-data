"""
Renders histograms of raw time information to check on distributions.
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
# import plotly.plotly as py
# import plotly.graph_objs as go
from getMeans import getTimes

"""
Generate three plots from the given events list:
  1) sendto time distribution
  2) recvmsg time distribution
  3) ping RTT distribution

Actually just dump for R. ..
"""
def plotEvents(events, filePath):
  # Separate into three sets
  sendToTimes, recvMsgTimes, pingRTTs = getTimes(events)
  with open(filePath + "_sendto", "w") as f:
    for t in sendToTimes:
      f.write(str(t) + "\n")
  with open(filePath + "_recvmsg", "w") as f:
    for t in recvMsgTimes:
      f.write(str(t) + "\n")
  with open(filePath + "_ping", "w") as f:
    for t in pingRTTs:
      f.write(str(t) + "\n")


def main():
  for setting in SETTINGS:
    native = po.parse(PREFIX + "v4_native_" + TARGET_IPV4 + "_" + setting)
    plotEvents(native, "v4_native_" + TARGET_IPV4 + "_" + setting)

  #   for target in CONTAINER_TARGETS_IPV4:
  #     container = po.parse(PREFIX + "v4_container_" + target + "_" + setting)
  #     printRaw(container, "v4_container_" + target + "_" + setting)

if __name__ == "__main__":
  main()
