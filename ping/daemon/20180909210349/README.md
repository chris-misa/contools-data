latency tracing `net:net_dev_queue` for outbound packets and
`net:netif_receive_skb` for inbound packets.

Outliers over 200 usec discarded.

Over estimates because on receive path, timestamp is added before `netif_receive_skb` on sandbox veth end. . .
