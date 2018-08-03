#!/bin/bash

#
# Experiment to compare a bias estimate from
# dind to actual observed bias.
#
# Probably run under sudo
#

# Address to ping to
export TARGET_IPV4="10.10.1.2"
export TARGET_IPV6="fd41:98cb:a6ff:5a6a::"

# Name of dind container
export DIND_NAME="docker-in-docker"
# Repo path to dind image
export DIND_LOC="docker:stable-dind"
# ipv6 subnet for dind's dockerd
export DIND_IPV6_SUBNET="fd41:98cb:a6ff:5a6a:eeee::/80"

# Native (local) ping command
export NATIVE_PING="$(pwd)/iputils/ping"
export NATIVE_DEV="eno1d1"
# Container ping command
export PING_IMAGE_NAME="chrismisa/contools:ping"
export CONTAINER_PING="docker run --rm $PING_IMAGE_NAME"

# Argument sequence is an associative array
# between file suffixes and argument strings
declare -A ARG_SEQ=(
  ["i0.5s16"]="-c 1500 -i 0.5 -s 16"
  ["i0.5s56"]="-c 1500 -i 0.5 -s 56"
  ["i0.5s120"]="-c 1500 -i 0.5 -s 120"
  ["i0.5s504"]="-c 1500 -i 0.5 -s 504"
  ["i0.5s1472"]="-c 1500 -i 0.5 -s 1472"
)

# Tag for data directory
export DATE_TAG=`date +%Y%m%d%H%M%S`
# Sleep for putting time around measurment
export SLEEP_CMD="sleep 5"
# Cosmetics
export B="------------"

# Make a directory for results
echo $B Starting Experiment: creating data directory $B
mkdir $DATE_TAG
cd $DATE_TAG

# Get some basic meta-data
echo "uname -a -> $(uname -a)" >> metadata
echo "docker -v -> $(docker -v)" >> metadata
echo "sudo lshw -> $(sudo lshw)" >> metadata

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

# Run second-level container
echo $B . . . Spinning up docker in docker $B

# Start the dind container in background
docker run --privileged -d  \
  --name=$DIND_NAME \
  $DIND_LOC \
  --ipv6 \
  --fixed-cidr-v6="$DIND_IPV6_SUBNET"


# Wait for it to start
until [ "`docker inspect -f {{.State.Running}} $DIND_NAME`" == "true" ]
do
  sleep 1
done

# Get its ip addresses
DIND_IPV4=`docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $DIND_NAME`
DIND_IPV6=`docker inspect -f '{{range .NetworkSettings.Networks}}{{.GlobalIPv6Address}}{{end}}' $DIND_NAME`
echo Got dind ipv4: $DIND_IPV4 ipv6: $DIND_IPV6

# Pull the ping container
echo Pulling the container in dind
docker exec $DIND_NAME docker pull $PING_IMAGE_NAME

echo $B Taking second-level container measurements $B
# Run measurement from container in dind to dind's interface
for i in "${!ARG_SEQ[@]}"
do
  $SLEEP_CMD
  docker exec $DIND_NAME $CONTAINER_PING ${ARG_SEQ[$i]} $DIND_IPV4 > dindcontainerping_dind_v4_$i
  $SLEEP_CMD
  docker exec $DIND_NAME $CONTAINER_PING -6 ${ARG_SEQ[$i]} $DIND_IPV6 > dindcontainerping_dind_v6_$i
done

# Clean up
docker stop $DIND_NAME
docker rm $DIND_NAME
