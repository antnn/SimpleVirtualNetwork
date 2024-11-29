#!/bin/bash
CMAKE_DIR="/opt/android-sdk/cmake"
LATEST_CMAKE=$(ls -d $CMAKE_DIR/*/ | sort -V | tail -n 1)
CMAKE_BIN="$LATEST_CMAKE/bin/cmake"
PROJECT_DIR="/src/"
MODULE_NAME="nativevpn"
WORK_DIR="$PROJECT_DIR/$MODULE_NAME/src/main/cpp/deps"

$CMAKE_BIN -H"$WORK_DIR" \
           -C "$WORK_DIR/build_deps.cmake" \
           -B "$WORk_DIR/build"
