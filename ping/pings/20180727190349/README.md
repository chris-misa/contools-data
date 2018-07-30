# Ping Distribution Experiment

Pings with varying parameters between two m510 node at Utah.

Value after i is interval in seconds.
value after s is packet payload size in bytes.
Both of these reflect values handed to -i and -s flags of iputil's ping.

Network between hosts was otherwise silent.
IPv6 Connectivity by using private subnet for docker daemon and ndppd
forwarding from eno1d1 to docker0.


# R Scripts

## generateHistograms.r

Generate histograms comparing container and native rtts at each flag setting.


## generateMeanDifference.r

Generate a graph of the mean difference between container an native measurements as a function of packet size.
