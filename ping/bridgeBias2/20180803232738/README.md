# Bridge Bias Strategy 2

Data collected from utah.cloudlab.us

Nodes were both type m510.

The hypothesis from reasoning about path types that the observed bias
should be approximately equal to the path from the container to host iface
minus the host pinging its own iface (to subtract out the time of reflection)
is clearly false.

It seems, rather, that the observed bias is between the path from the container to
the host iface and the path from the container bouncing of it's own sandbox.

Further analysis is needed here. . .

# Side note

First experiment where
1. each command has a smaller -c size
2. containers are not spun up / down during the experiment run as services

It is unclear as to whether these strategies cause the relative distributional
stability here because they were also followed in the next experiment (bridge bias1)
which yielded highly bi-modal results.

