# Second Run of dind strategy 1.2 experiment

With varying interval.

First run gave bad distribution.  Lets see about this one. . .
Apparently not!

Both nodes are on utah.cloudlab.us, type xl170, same as in previous run.
Experiment script is also same as previous with difference parameters.

# Notes

It looks like the emulated network stack goes consistently faster than
the network stack connected to the physical wire. Perhaps we can
use the ratios to estimate the bias based on results comming out of the
container, but since larger-scale fluctuations in RTT form the external
network will dominate in the real world, this doesn't really seem like
it would work.


Giving up on emulation?
