Ftrace latency between
`net_dev_queue` in the outbound path and
`netif_receive_skb` in the inbound path

using ping modified to not use socket timestamps:
converted to gettimeofday in receiving code. . .
