#!/bin/bash

#
# Experiment to determine if host-networked containers
# impose any bias on latency.
#

# Address to ping to
export TARGET_IPV4="10.10.1.2"
export TARGET_IPV6="fd41:98cb:a6ff:5a6a::"

# Native (local) ping command
export NATIVE_PING="$(pwd)/iputils/ping"
export NATIVE_DEV="ens1f1"
# Container ping command
export PING_IMAGE_NAME="chrismisa/contools:ping"
export CONTAINER_PING="docker run --rm --network=host $PING_IMAGE_NAME"

# Argument sequence is an associative array
# between file suffixes and argument strings
declare -A ARG_SEQ=(
  ["i0.5s16.ping"]="-c 1500 -i 0.5 -s 16"
  ["i0.5s56.ping"]="-c 1500 -i 0.5 -s 56"
  ["i0.5s120.ping"]="-c 1500 -i 0.5 -s 120"
  ["i0.5s504.ping"]="-c 1500 -i 0.5 -s 504"
  ["i0.5s1472.ping"]="-c 1500 -i 0.5 -s 1472"
)

# Tag for data directory
export DATE_TAG=`date +%Y%m%d%H%M%S`
# File name for metadata
export META_DATA="Metadata"
# Sleep for putting time around measurment
export SLEEP_CMD="sleep 5"
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

# Run native
echo "$B Taking native (control) measurments $B"
for i in "${!ARG_SEQ[@]}"
do
  $SLEEP_CMD
  $NATIVE_PING ${ARG_SEQ[$i]} $TARGET_IPV4 > nativeping_target_v4_$i
  $SLEEP_CMD
  $NATIVE_PING -6 -I $NATIVE_DEV ${ARG_SEQ[$i]} $TARGET_IPV6 > nativeping_target_v6_$i
done

# Run first-level container
echo $B Taking first-level container measurements $B
for i in "${!ARG_SEQ[@]}"
do
  $SLEEP_CMD
  $CONTAINER_PING ${ARG_SEQ[$i]} $TARGET_IPV4 > containerping_target_v4_$i
  $SLEEP_CMD
  $CONTAINER_PING -6 ${ARG_SEQ[$i]} $TARGET_IPV6 > containerping_target_v6_$i
done
