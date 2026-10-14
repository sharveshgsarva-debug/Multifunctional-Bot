#!/usr/bin/env bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ROBOT_PROJECT_DIR="$PROJECT_DIR"

ROBOT_MODE="arm"
USE_WEB=false

for arg in "$@"; do
  case $arg in
    --quard|quard|-q)
      ROBOT_MODE="quard"
      ;;
    --dual|dual|-d)
      ROBOT_MODE="dual"
      ;;
    --web|web|-w)
      USE_WEB=true
      ;;
  esac
done

if [ "$USE_WEB" = true ]; then
  exec "$PROJECT_DIR/launch_web_dashboard.sh"
fi

source "/opt/ros/${ROS_DISTRO:-jazzy}/setup.bash"
source "$PROJECT_DIR/ros2_ws/install/setup.bash"
export QT_QPA_PLATFORM=xcb

pkill -9 -f calibrated_joint_gui 2>/dev/null || true
pkill -9 -f robot_state_publisher 2>/dev/null || true
pkill -9 -f rviz2 2>/dev/null || true
pkill -9 -f servo_serial_commander 2>/dev/null || true

# Stop background helpers when the dashboard exits or Ctrl+C is pressed.
CHILD_PIDS=()
cleanup() {
  for pid in "${CHILD_PIDS[@]}"; do
    kill "$pid" 2>/dev/null || true
  done
}
trap cleanup EXIT INT TERM

if [ "$ROBOT_MODE" = "arm" ] || [ "$ROBOT_MODE" = "dual" ]; then
  ros2 run servo_joint_publisher servo_serial_commander &
  CHILD_PIDS+=($!)
fi

echo "🤖 Launching Desktop Dashboard for $ROBOT_MODE ..."
ros2 launch "$PROJECT_DIR/urdf/unnamed/display_ros2.launch.py" simulate:=false robot:="$ROBOT_MODE"
