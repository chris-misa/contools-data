"""
Get Bias

Reads pcap dumps from container iface
and host iface and determines delta time
for each packer.

Writes a list of estimated biases (in ms),
one for each transaction,
to stdout.

"""

USAGE_STRING="Usage: python getBias.py"

# Set base paths as globals
CONT_PATH_BASE_V4 = "rawFiles/v4_containeri0.5_s56_"
HOST_PATH_BASE_V4 = "rawFiles/v4_hosti0.5_s56_"
CONT_PATH_BASE_V6 = "rawFiles/v6_containeri0.5_s56_"
HOST_PATH_BASE_V6 = "rawFiles/v6_hosti0.5_s56_"

import glob
import sys
import re
import pprint
from scapy.all import *

"""
Read in data from container iface and host iface dumps.
Returns a list where each element represents a single ICMP transaction as
seen by the container and host ifaces. The assumption is that the container
is sending ICMP echo requests, and something else on the network is returning
ICMP echo replies.

The fields of each entry in returned list are:
  "seq"              : the ICMP seq value of this transcation
  "id"               : the ICMP id associated with this transaction
  "cont_send_time"    : time stamp when request packet is seen on container's iface
  "host_send_time"   : time stamp when request packet is seen on host's iface
  "host_return_time" : time stamp when host iface see's ICMP reply
  "cont_return_time"  : time stamp when container's iface see's ICMP reply
  "outbound_bias"    : host_send_time - cont_send_time
  "inbound_bias"     : cont_return_time - host_return_time

The hypothesis is that outbound_bias + inbound_bias approximates the RTT overhead.
"""
def getBias(containerPcap, hostPcap):
  # Read in container packets
  contPkts = rdpcap(containerPcap)
  # Read in host packets
  hostPkts = rdpcap(hostPcap)
   
  result = []

  # Go from last to first since there's probably an extra sample at beginning of host's capture (for control purposes)
  while len(contPkts) != 0 and len(hostPkts) != 0:
    contPkt = contPkts.pop()
    hostPkt = hostPkts.pop()
    # Sanity check
    if contPkt[ICMP].seq != hostPkt[ICMP].seq or contPkt[ICMP].id != hostPkt[ICMP].id:
      print("Packet mis-match!")
      return None
    # Packet zipping logic
    if len(result) != 0 and result[-1]["seq"] == contPkt[ICMP].seq:
      result[-1]["cont_send_time"] = contPkt.time
      result[-1]["host_send_time"] = hostPkt.time
      result[-1]["outbound_bias"] = hostPkt.time - contPkt.time
    else:
      result.append({
          "cont_return_time": contPkt.time,
          "host_return_time": hostPkt.time,
          "inbound_bias": contPkt.time - hostPkt.time,
          "seq": contPkt[ICMP].seq,
          "id": contPkt[ICMP].id
      })
  return result


def getBias6(containerPcap, hostPcap):
  # Read in container packets and filter
  contPkts = [p for p in rdpcap(containerPcap) \
      if p.haslayer(ICMPv6EchoRequest) \
      or p.haslayer(ICMPv6EchoReply)]
  # Read in host packets and filter
  hostPkts = [p for p in rdpcap(hostPcap) \
      if p.haslayer(ICMPv6EchoRequest) \
      or p.haslayer(ICMPv6EchoReply)]

   
  result = []

  # Go from last to first since there's probably an extra sample at beginning of host's capture (for control purposes)
  while len(contPkts) != 0 and len(hostPkts) != 0:
    contPkt = contPkts.pop()
    hostPkt = hostPkts.pop()

    # Since we're going from the end, process responses first, the requests . . .
    if contPkt.haslayer(ICMPv6EchoReply):
      if not hostPkt.haslayer(ICMPv6EchoReply) \
      or contPkt[ICMPv6EchoReply].id != hostPkt[ICMPv6EchoReply].id \
      or contPkt[ICMPv6EchoReply].seq != hostPkt[ICMPv6EchoReply].seq:
        print("Packet mismatch!")
        return None
      result.append({
        "cont_return_time": contPkt.time,
        "host_return_time": hostPkt.time,
        "inbound_bias": contPkt.time - hostPkt.time,
        "seq": contPkt[ICMPv6EchoReply].seq,
        "id":  contPkt[ICMPv6EchoReply].id
      })
    elif contPkt.haslayer(ICMPv6EchoRequest):
      if not hostPkt.haslayer(ICMPv6EchoRequest) \
      or contPkt[ICMPv6EchoRequest].id != hostPkt[ICMPv6EchoRequest].id \
      or contPkt[ICMPv6EchoRequest].seq != hostPkt[ICMPv6EchoRequest].seq \
      or contPkt[ICMPv6EchoRequest].seq != result[-1]["seq"]:
        print("Packet mismatch!")
        return None
      result[-1]["cont_send_time"] = contPkt.time
      result[-1]["host_send_time"] = hostPkt.time
      result[-1]["outbound_bias"] = hostPkt.time - contPkt.time
  return result

def main():
  biasList = []
  for i in range(10):
    biasList += getBias(CONT_PATH_BASE_V4 + str(i) + ".pcap", \
                        HOST_PATH_BASE_V4 + str(i) + ".pcap")
  # Extract RTT biases for now (original time samps were in second so move to ms)
  biases = [1000 * (b["outbound_bias"]+b["inbound_bias"]) for b in biasList]
  with open("v4_biases.data","w") as f:
    for b in biases:
      f.write("%.6f\n" % b)
  print("Wrote IPv4 Biases")
  biasList = []
  for i in range(10):
    biasList += getBias6(CONT_PATH_BASE_V6 + str(i) + ".pcap", \
                        HOST_PATH_BASE_V6 + str(i) + ".pcap")
  # Extract RTT biases for now (original time samps were in second so move to ms)
  biases = [1000 * (b["outbound_bias"]+b["inbound_bias"]) for b in biasList]
  with open("v6_biases.data","w") as f:
    for b in biases:
      f.write("%.6f\n" % b)
  print("Wrote IPv6 Biases")


if __name__ == "__main__":
  main()
