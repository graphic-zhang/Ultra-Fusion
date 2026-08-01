#!/usr/bin/env bash
#
# Print ros2 bag play options inside the runtime image.
#
set -euo pipefail

docker run --rm ultrafusion-ros2:0.2.2-local bash -c 'source /opt/ros/humble/setup.bash && ros2 bag play --help'
