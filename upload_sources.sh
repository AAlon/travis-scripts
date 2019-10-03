!/bin/bash
# This is a standalone script that is meant to be run from Travis directly, outside of a docker container.
set -xe

sudo apt-get update && sudo apt-get install -q -y dirmngr curl gnupg2 lsb-release zip python3-pip python3-apt dpkg

if [ "${ROS_VERSION}" == "1" ]; then
  sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
  sudo apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654
  sudo apt-get update && sudo apt-get install -y python-rosdep python-rosinstall
elif [ "${ROS_VERSION}" == "2" ]; then
  sudo curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add -
  sudo sh -c 'echo "deb [arch=amd64,arm64] http://packages.ros.org/ros2/ubuntu `lsb_release -cs` main" > /etc/apt/sources.list.d/ros2-latest.list'
  sudo apt-get update && sudo apt-get install -y python3-rosdep python3-rosinstall
else
  echo "ROS_VERSION not defined or recognized"
  exit 1
fi



if [ -z "$WORKSPACES" ]; then
  WORKSPACES="robot_ws simulation_ws"
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
mkdir shared 2>/dev/null
/usr/bin/zip -r shared/sources.zip $SOURCES_INCLUDES
tar cvzf shared/sources.tar.gz $SOURCES_INCLUDES
