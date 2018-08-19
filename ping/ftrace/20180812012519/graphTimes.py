"""
Generate plotly graph of time spent in system calls
vs. RTT reported by ping for container and native
"""

# Unused
# SETTINGS = ["i0.5_s24",
#             "i0.5_s56",
#             "i0.5_s120",
#             "i0.5_s248",
#             "i0.5_s504",
#             "i0.5_s1016"]
SIZES = [24, 56, 120, 248, 504, 1016]

TARGET_IPV4 = "10.10.1.2"
CONTAINER_TARGETS_IPV4=[TARGET_IPV4, "172.17.0.1", "10.10.1.1"]

PREFIX="rawFiles/"

from plotly.offline import plot

import plotly.graph_objs as go

import getMeans as m

def main():
  nativeSyscallTimes = []
  nativePingRTTs = []
  containerSyscallTimes = []
  containerPingRTTs = []
  for size in SIZES:
    sendTo, stall, recvMsg, rtt = \
        m.getMeans(m.getTransactions( \
          PREFIX + "v4_native_" + TARGET_IPV4 + "_i0.5_s" + str(size)))
    nativeSyscallTimes.append(sendTo + stall + recvMsg)
    nativePingRTTs.append(rtt)

    sendTo, stall, recvMsg, rtt = \
        m.getMeans(m.getTransactions( \
          PREFIX + "v4_container_" + TARGET_IPV4 + "_i0.5_s" + str(size)))
    containerSyscallTimes.append(sendTo + stall + recvMsg)
    containerPingRTTs.append(rtt)

  trace0 = go.Scatter( \
      x = SIZES,
      y = nativeSyscallTimes,
      mode = 'lines+markers',
      name = 'Native Syscall Time',
      line = dict(
        color = ('rgb(0,0,0)'),
        dash = 'dash'
      )

  )
  trace1 = go.Scatter( \
      x = SIZES,
      y = nativePingRTTs,
      mode = 'lines+markers',
      name = 'Native Ping RTTs',
      line = dict(
        color = ('rgb(0,0,0)')
      )
  )
  trace2 = go.Scatter( \
      x = SIZES,
      y = containerSyscallTimes,
      mode = 'lines+markers',
      name = 'Container Syscall Times',
      line = dict(
        color = ('rgb(255,0,0)'),
        dash = 'dash'
      )
  )
  trace3 = go.Scatter( \
      x = SIZES,
      y = containerPingRTTs,
      mode = 'lines+markers',
      name = 'Container Ping RTTs',
      line = dict(
        color = ('rgb(255,0,0)')
      )
  )

  fig = dict(
      data = [trace0, trace1, trace2, trace3],
      layout = dict(
        title = 'Ping Times',
        xaxis = dict(title = 'Payload (bytes)'),
        yaxis = dict(title = 'Mean time (usec)')
      )
  )

  plot(fig, filename = 'times.html')

if __name__ == "__main__":
  main()
