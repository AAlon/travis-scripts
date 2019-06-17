#!/bin/bash

COLCON_BUNDLE_INSTALL_PATH="${HOME}/colcon-bundle"
rm -rf "${COLCON_BUNDLE_INSTALL_PATH}"
git clone https://github.com/colcon/colcon-bundle "${COLCON_BUNDLE_INSTALL_PATH}"
pip3 install --upgrade pip
pip install -U --editable "${COLCON_BUNDLE_INSTALL_PATH}"

rosws update
rosdep install --from-paths src --ignore-src -r -y
colcon build --build-base build --install-base install
colcon bundle --build-base build --install-base install --bundle-base bundle
