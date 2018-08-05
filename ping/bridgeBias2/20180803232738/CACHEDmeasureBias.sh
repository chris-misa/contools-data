#!/bin/bash

#
# Bridge Bias Strategy 2.
#
# Runs ping container on the default bridge network
# and takes a bunch of measurements.
#

# Address to ping to
export TARGET_IPV4="10.10.1.2"
export TARGET_IPV6="fd41:98cb:a6ff:5a6a::2"

# Address of hosts' network-facing interface
export HOST_IPV4="10.10.1.1"
export HOST_IPV6="fd41:98cb:a6ff:5a6a::1"

# Address assigned to container's end of the veth
export CONTAINER_IPV4
export CONTAINER_IPV6


# Native (local) ping command
export NATIVE_PING="$(pwd)/iputils/ping"
export NATIVE_DEV="eno1d1"

# Container ping command
export PING_IMAGE_NAME="chrismisa/contools:ping"
export CONTAINER_NAME="ping-container"
export CONTAINER_PING="docker exec $CONTAINER_NAME ping"

# Argument sequence is an associative array
# between file suffixes and argument strings
declare -a INTERVALS=(0.1 0.3 0.5 1.0)
declare -a SIZES=(16 56 120)
declare -A ARG_SEQ
for i in ${INTERVALS[@]}
do
  for s in ${SIZES[@]}
  do
    for n in {1..20}
    do
      ARG_SEQ["i${i}_s${s}_${n}.ping"]="-c 30 -i $i -s $s"
    done
  done
done

# Tag for data directory
export DATE_TAG=`date +%Y%m%d%H%M%S`
# File name for metadata
export META_DATA="Metadata"
# Sleep for putting time around measurment
export LITTLE_SLEEP="sleep 3"
export BIG_SLEEP="sleep 10"
# Cosmetics
export B="------------"

# Make a directory for results
echo $B Starting Experiment: creating data directory $B
mkdir $DATE_TAG
cd $DATE_TAG

# Get some basic meta-data
echo "uname -a -> $(uname -a)" >> $META_DATA
echo "docker -v -> $(docker -v)" >> $META_DATA
echo "sudo lshw -> $(sudo lshw)" >> $META_DATA

# Start ping container as service
echo $B Spinning up the ping container $B
docker run --rm -itd --name=$CONTAINER_NAME \
                     --entrypoint="/bin/bash" \
                     $PING_IMAGE_NAME

# Wait for container to be ready
until [ "`docker inspect -f '{{.State.Running}}' $CONTAINER_NAME`" \
        == "true" ]
do
  sleep 1
done

# Get its ip addresses
CONTAINER_IPV4=`docker inspect -f \
  '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' \
  $CONTAINER_NAME`
CONTAINER_IPV6=`docker inspect -f \
  '{{range .NetworkSettings.Networks}}{{.GlobalIPv6Address}}{{end}}' \
  $CONTAINER_NAME`
echo "Container is up with addresses:"
echo "  IPv4: $CONTAINER_IPV4"
echo "  IPv6: $CONTAINER_IPV6"

# Go through tests
for i in "${!ARG_SEQ[@]}"
do
  # IPv4 Tests
  echo $B Running IPv4 measurements for $i $B
  $BIG_SLEEP

  # host -> target
  echo "  host -> target"
  $LITTLE_SLEEP
  $NATIVE_PING ${ARG_SEQ[$i]} $TARGET_IPV4 \
    > v4_native_target_$i

  # container -> target
  echo "  container -> target"
  $LITTLE_SLEEP
  $CONTAINER_PING ${ARG_SEQ[$i]} $TARGET_IPV4 \
    > v4_container_target_$i

  # container -> host
  echo "  container -> host"
  $LITTLE_SLEEP
  $CONTAINER_PING ${ARG_SEQ[$i]} $HOST_IPV4 \
    > v4_container_host_$i
   
  # container -> container
  echo "  container -> container"
  $LITTLE_SLEEP
  $CONTAINER_PING ${ARG_SEQ[$i]} $CONTAINER_IPV4 \
    > v4_container_container_$i

  # host -> host
  echo "  host -> host"
  $LITTLE_SLEEP
  $NATIVE_PING ${ARG_SEQ[$i]} $HOST_IPV4 \
    > v4_host_host_$i

  # IPv6 Tests
  echo $B Running IPv6 measurements for $i $B
  $BIG_SLEEP

  # host -> target
  echo "  host -> target"
  $LITTLE_SLEEP
  $NATIVE_PING -6 ${ARG_SEQ[$i]} $TARGET_IPV6 \
    > v6_native_target_$i

  # container -> target
  echo "  container -> target"
  $LITTLE_SLEEP
  $CONTAINER_PING -6 ${ARG_SEQ[$i]} $TARGET_IPV6 \
    > v6_container_target_$i

  # container -> host
  echo "  container -> host"
  $LITTLE_SLEEP
  $CONTAINER_PING -6 ${ARG_SEQ[$i]} $HOST_IPV6 \
    > v6_container_host_$i
   
  # container -> container
  echo "  container -> container"
  $LITTLE_SLEEP
  $CONTAINER_PING -6 ${ARG_SEQ[$i]} $CONTAINER_IPV6 \
    > v6_container_container_$i

  # host -> host
  echo "  host -> host"
  $LITTLE_SLEEP
  $NATIVE_PING -6 ${ARG_SEQ[$i]} $HOST_IPV6 \
    > v6_host_host_$i
done

# Clean up
$BIG_SLEEP
docker stop $CONTAINER_NAME

echo Done.
