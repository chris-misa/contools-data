Ftrace latency between
`net_dev_queue` in the outbound path and
`netif_receive_skb` in the inbound path

using ping modified to not use socket timestamps:
converted to gettimeofday in receiving code. . .

outliers over 200 usec discarded which might lead to under-estimation.
there seem to be some ca 500 usec latencies which may have been legit. . .
