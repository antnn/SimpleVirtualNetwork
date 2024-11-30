```bash
without container
export NDK_VERSION="27.0.12077973"
export CMAKE_VERSION="3.30.5"
export ANDROID_VERSION="35"
export BUILD_TOOLS="35.0.0"
export BUILD_TYPE="Release"
export MIN_SDK_VERSION="24"
export SOFTETHERVPN_VERSION="5.02.5187"
export OPENSSL_VERSION="3.4.0"
export SODIUM_VERSION="1.0.20-RELEASE"
export ANDROID_HOME="$HOME/Android"
export ANDROID_NDK_ROOT="${ANDROID_HOME}/ndk/${NDK_VERSION}"
export PATH="${ANDROID_HOME}/cmake/${CMAKE_VERSION}/bin:${ANDROID_HOME}/cmdline-tools/bin:${PATH}"

CMAKE_DIR="$HOME/Android/cmake"
LATEST_CMAKE=$(ls -d $CMAKE_DIR/*/ | sort -V | tail -n 1)
CMAKE_BIN="$LATEST_CMAKE/bin/cmake"
PROJECTS_DIR="projects"
PNAME="SimpleVirtualNetwork"
MODULE_NAME="nativevpn"
WORK_DIR="$HOME/$PROJECTS_DIR/$PNAME/$MODULE_NAME/src/main/cpp/deps"

$CMAKE_BIN -H"$WORK_DIR" \
           -C "$WORK_DIR/build_deps.cmake" \
           -B "$WORk_DIR/build"

```
