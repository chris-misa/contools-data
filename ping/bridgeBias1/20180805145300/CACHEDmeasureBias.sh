#!/bin/bash

#
# Experiment to compare a bias estimate from
# dind to actual observed bias.
#
# Updated to test different paths and
# to use measurement container as a service
# model rather then spinning containers
# from command line for each measurement.
#
# Run under sudo
#
# For the moment ipv6 seems to not be working in
# this version of docker in docker . . .
# Starting with ipv4 tests.
#

# Address to ping to
export TARGET_IPV4="10.10.1.2"
export TARGET_IPV6="fd41:98cb:a6ff:5a6a::"

# Argument sequence is an associative array
# between file suffixes and argument strings
declare -A ARG_SEQ=(
  ["i0.5s120_0.ping"]="-c 100 -i 0.5 -s 120"
  ["i0.5s120_1.ping"]="-c 100 -i 0.5 -s 120"
  ["i0.5s120_2.ping"]="-c 100 -i 0.5 -s 120"
  ["i0.5s120_3.ping"]="-c 100 -i 0.5 -s 120"
  ["i0.5s120_4.ping"]="-c 100 -i 0.5 -s 120"
  ["i0.5s120_5.ping"]="-c 100 -i 0.5 -s 120"
  ["i0.5s120_6.ping"]="-c 100 -i 0.5 -s 120"
  ["i0.5s120_7.ping"]="-c 100 -i 0.5 -s 120"
  ["i0.5s120_8.ping"]="-c 100 -i 0.5 -s 120"
  ["i0.5s120_9.ping"]="-c 100 -i 0.5 -s 120"
  ["i0.5s56_0.ping"]="-c 100 -i 0.5 -s 56"
  ["i0.5s56_1.ping"]="-c 100 -i 0.5 -s 56"
  ["i0.5s56_2.ping"]="-c 100 -i 0.5 -s 56"
  ["i0.5s56_3.ping"]="-c 100 -i 0.5 -s 56"
  ["i0.5s56_4.ping"]="-c 100 -i 0.5 -s 56"
  ["i0.5s56_5.ping"]="-c 100 -i 0.5 -s 56"
  ["i0.5s56_6.ping"]="-c 100 -i 0.5 -s 56"
  ["i0.5s56_7.ping"]="-c 100 -i 0.5 -s 56"
  ["i0.5s56_8.ping"]="-c 100 -i 0.5 -s 56"
  ["i0.5s56_9.ping"]="-c 100 -i 0.5 -s 56"
)

# Native (local) ping command
export NATIVE_PING_CMD="$(pwd)/iputils/ping"
export NATIVE_DEV="eno1d1"

# Info for docker in docker container
export DIND_IMAGE_NAME="chrismisa/contools:dind"
export DIND_CONTAINER_NAME="docker-in-docker"
export DIND_PING_CMD="/iputils/ping"

# Info for ping container
export PING_IMAGE_NAME="chrismisa/contools:ping"
export PING_CONTAINER_NAME="ping-container"

# Tag for data directory
export DATE_TAG=`date +%Y%m%d%H%M%S`
# File name for metadata
export META_DATA="Metadata"

# Sleep for putting time around measurment
export SLEEP_CMD="sleep 5"
# Cosmetics
export B="------------"

# Pull needed containers from docker hub
docker pull $PING_IMAGE_NAME
docker pull $DIND_IMAGE_NAME

if [ $? -ne 0 ]
then
  echo "Failed to pull images from dockerhub!"
  exit 1
fi

# Make a directory for results
echo $B Gathering system metadata . . . $B
mkdir $DATE_TAG
cd $DATE_TAG

# Get some basic meta-data
echo "uname -a -> $(uname -a)" >> $META_DATA
echo "docker -v -> $(docker -v)" >> $META_DATA
echo "sudo lshw -> $(sudo lshw)" >> $META_DATA

# Set up containers
echo $B Spinning up containers . . . $B

# Spin up docker in docker container
docker run --rm --privileged -itd \
  --name="$DIND_CONTAINER_NAME" \
  $DIND_IMAGE_NAME

# Spin up ping container in native docker
docker run --rm -itd \
  --name="$PING_CONTAINER_NAME" \
  --entrypoint="/bin/bash" \
  $PING_IMAGE_NAME

# Wait for them to be ready
until [ "`docker inspect -f {{.State.Running}} $DIND_CONTAINER_NAME`" \
        == "true" ] && \
      [ "`docker inspect -f {{.State.Running}} $PING_CONTAINER_NAME`" \
        == "true" ]
do
  sleep 1
done

# Get docker in docker container's ip addresses
DIND_IPV4=`docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $DIND_CONTAINER_NAME`
DIND_IPV6=`docker inspect -f '{{range .NetworkSettings.Networks}}{{.GlobalIPv6Address}}{{end}}' $DIND_CONTAINER_NAME`
echo "  docker in docker container up with"
echo "    ipv4: $DIND_IPV4"
echo "    ipv6: $DIND_IPV6"

# Get ping container's ip addresses
PING_IPV4=`docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $PING_CONTAINER_NAME`
PING_IPV6=`docker inspect -f '{{range .NetworkSettings.Networks}}{{.GlobalIPv6Address}}{{end}}' $PING_CONTAINER_NAME`
echo "  ping container up with"
echo "    ipv4: $PING_IPV4"
echo "    ipv6: $PING_IPV6"


# Spin up ping container in docker in docker
docker exec $DIND_CONTAINER_NAME \
  docker run --rm -itd \
    --name="$PING_CONTAINER_NAME" \
    --entrypoint="/bin/bash" \
    $PING_IMAGE_NAME

# Wait for it to be ready
until [ "`docker exec $DIND_CONTAINER_NAME \
            docker inspect -f {{.State.Running}} $PING_CONTAINER_NAME`" \
        == "true" ]
do
  sleep 1
done

# Get ping container in docker in docker's ip addresses
DIND_PING_IPV4=`docker exec $DIND_CONTAINER_NAME \
  docker inspect \
  -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' \
  $PING_CONTAINER_NAME`
DIND_PING_IPV6=`docker exec $DIND_CONTAINER_NAME \
  docker inspect \
  -f '{{range .NetworkSettings.Networks}}{{.GlobalIPv6Address}}{{end}}' \
  $PING_CONTAINER_NAME`
echo "  ping container in docker in docker up with"
echo "    ipv4: $DIND_PING_IPV4"
echo "    ipv6: $DIND_PING_IPV6"

# Run ipv4 measurements
echo $B Taking IPv4 measurements . . .$B

for i in ${!ARG_SEQ[@]}
do
  echo "  native -> target"
  $SLEEP_CMD
  $NATIVE_PING_CMD ${ARG_SEQ[$i]} $TARGET_IPV4 > v4_native_to_target_$i

  echo "  container -> target"
  $SLEEP_CMD
  docker exec $PING_CONTAINER_NAME ping ${ARG_SEQ[$i]} $TARGET_IPV4 > v4_container_to_target_$i

  echo "  dind -> container"
  $SLEEP_CMD
  docker exec $DIND_CONTAINER_NAME $DIND_PING_CMD ${ARG_SEQ[$i]} $PING_IPV4 > v4_dind_to_container_$i

  echo "  dind container -> container"
  $SLEEP_CMD
  docker exec $DIND_CONTAINER_NAME docker exec $PING_CONTAINER_NAME ping ${ARG_SEQ[$i]} $PING_IPV4 > v4_dind_container_to_container_$i
done

# Run ipv6 measurements

# Clean up
echo $B Spinning down containers $B
docker stop $DIND_CONTAINER_NAME $PING_CONTAINER_NAME
