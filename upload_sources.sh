#!/bin/bash
# This script is meant to be run from Travis directly, outside of a docker container.
set -xe

apt-get update
if [ "${ROS_VERSION}" == "1" ]; then
  apt-get install -y python-rosinstall
elif [ "${ROS_VERSION}" == "2" ]; then
  apt-get install -y python3-rosinstall
else
  echo "ROS_VERSION not defined or recognized"
  exit 1
fi

for WS in $WORKSPACES
do
  WS_DIR="${TRAVIS_BUILD_DIR}/${WS}"
  echo "looking for ${WS}, ${WS_DIR}"
  if [ -d "${WS_DIR}" ]; then
    echo "WS ${WS_DIR} found, running rosws update"
    rosws update -t "${WS_DIR}"
  fi
done

SOURCES_INCLUDES="${WORKSPACES} LICENSE* NOTICE* README* roboMakerSettings.json"
/usr/bin/zip -r shared/sources.zip $SOURCES_INCLUDES
tar cvzf shared/sources.tar.gz $SOURCES_INCLUDES
