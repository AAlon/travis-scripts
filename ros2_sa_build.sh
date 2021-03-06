#!/bin/bash
set -xe

export SCRIPT_DIR=$(dirname ${DOCKER_BUILD_SCRIPT})

# install dependencies
apt-get update && apt-get install -q -y dirmngr curl gnupg2 lsb-release zip python3-pip python3-apt dpkg
pip3 install -U setuptools

curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -
sh -c 'echo "deb [arch=amd64,arm64] http://packages.ros.org/ros2/ubuntu `lsb_release -cs` main" > /etc/apt/sources.list.d/ros2-latest.list'
apt-get update && apt-get install --no-install-recommends -y python3-rosdep python3-rosinstall python3-colcon-common-extensions ros-$ROS_DISTRO-ros-base
apt list --upgradable 2>/dev/null | awk {'print $1'} | sed 's/\/.*//g' | grep $ROS_DISTRO | xargs apt install -y
pip3 install colcon-bundle colcon-ros-bundle

# Get latest colcon bundle
COLCON_BUNDLE_INSTALL_PATH="${HOME}/colcon-bundle"
rm -rf "${COLCON_BUNDLE_INSTALL_PATH}"
COLCON_ROS_BUNDLE_INSTALL_PATH="${HOME}/colcon-ros-bundle"
rm -rf "${COLCON_ROS_BUNDLE_INSTALL_PATH}"
git clone https://github.com/colcon/colcon-bundle "${COLCON_BUNDLE_INSTALL_PATH}"
git clone https://github.com/colcon/colcon-ros-bundle "${COLCON_ROS_BUNDLE_INSTALL_PATH}"

pip3 install --upgrade pip
pip install -U --editable "${COLCON_BUNDLE_INSTALL_PATH}"
pip install -U --editable "${COLCON_ROS_BUNDLE_INSTALL_PATH}"

# Remove the old rosdep sources.list
rm -rf /etc/ros/rosdep/sources.list.d/*
rosdep init && rosdep update

. /opt/ros/$ROS_DISTRO/setup.sh

BUILD_DIR_NAME=`basename $TRAVIS_BUILD_DIR`

if [ -z "$WORKSPACES" ]; then
  WORKSPACES="robot_ws simulation_ws"
fi

# Run ROSWS update in each workspace before creating archive
for WS in $WORKSPACES
do
  WS_DIR="/${ROS_DISTRO}_ws/src/${BUILD_DIR_NAME}/${WS}"
  echo "looking for ${WS}, $WS_DIR"
  if [ -d "${WS_DIR}" ]; then
    echo "WS ${WS_DIR} found, running rosws update"
    rosws update -t "${WS_DIR}"
  fi
done

# Create archive of all sources files
SOURCES_INCLUDES="${WORKSPACES} LICENSE* NOTICE* README* roboMakerSettings.json"
cd /${ROS_DISTRO}_ws/src/${BUILD_DIR_NAME}/
/usr/bin/zip -r /shared/sources.zip $SOURCES_INCLUDES
tar cvzf /shared/sources.tar.gz $SOURCES_INCLUDES

for WS in $WORKSPACES
do
  # use colcon as build tool to build the workspace if it exists
  WS_DIR="/${ROS_DISTRO}_ws/src/${BUILD_DIR_NAME}/${WS}"
  WS_BUILD_SCRIPT="/shared/$(basename ${SCRIPT_DIR})/ws_builds/${WS}.sh"
  if [ -f "${WS_BUILD_SCRIPT}" ]; then
    cd "${WS_DIR}"
    bash "${WS_BUILD_SCRIPT}"
    mv ./bundle/output.tar /shared/"${WS}".tar
  else
    echo "Unable to find build script ${WS_BUILD_SCRIPT}, build failed"
    exit 1
  fi
done
