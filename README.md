
```bash
#build is partially working (openssl, libsodium)
#docker build . -t buildcontainer
#docker run --rm -it buildcontainer
CMAKE_DIR="/opt/android-sdk/cmake"
LATEST_CMAKE=$(ls -d $CMAKE_DIR/*/ | sort -V | tail -n 1)
CMAKE_BIN="$LATEST_CMAKE/bin/cmake"
PROJECT_DIR="/src/"
MODULE_NAME="nativevpn"
WORK_DIR="$PROJECT_DIR/$MODULE_NAME/src/main/cpp/deps"

$CMAKE_BIN -H"$WORK_DIR" \
           -C "$WORK_DIR/build_deps.cmake" \
           -B "$WORk_DIR/build"

```
[build_deps.cmake](https://github.com/antnn/SimpleVirtualNetwork/blob/main/nativevpn/src/main/cpp/deps/build_deps.cmake#L129)


[CMakeLists.txt](https://github.com/antnn/SimpleVirtualNetwork/blob/main/nativevpn/src/main/cpp/deps/CMakeLists.txt#L35)


[SoftetherVPN patch](https://github.com/antnn/SimpleVirtualNetwork/blob/main/nativevpn/src/main/cpp/deps/softether.patch#L278)

# Build deps
```bash
# without container
cd SimpleVirtualNetwork/nativevpn/src/main/cpp/deps
```bash
# without container
PROJECTS_DIR="projects"
PNAME="SimpleVirtualNetwork"
MODULE_NAME="nativevpn"
WORK_DIR="$HOME/$PROJECTS_DIR/$PNAME/$MODULE_NAME/src/main/cpp/deps"

export NDK_VERSION="27.0.12077973"
export CMAKE_VERSION="3.30.5"
export ANDROID_VERSION="35"
export BUILD_TOOLS="35.0.0"
export BUILD_TYPE="Release"
export MIN_SDK_VERSION="24"
export SOFTETHERVPN_VERSION="5.02.5187"
export OPENSSL_VERSION="3.4.0"
export SODIUM_VERSION="1.0.20-RELEASE"
export ICONV_VERSION="1.17"
export ANDROID_HOME="$HOME/Android"
export ANDROID_NDK_ROOT="${ANDROID_HOME}/ndk/${NDK_VERSION}"
export PATH="${ANDROID_HOME}/cmake/${CMAKE_VERSION}/bin:${ANDROID_HOME}/cmdline-tools/bin:${PATH}"

CMAKE_DIR="$HOME/Android/cmake"
LATEST_CMAKE=$(ls -d $CMAKE_DIR/*/ | sort -V | tail -n 1)
CMAKE_BIN="$LATEST_CMAKE/bin/cmake"

$CMAKE_BIN -H"$WORK_DIR" \
           -C "$WORK_DIR/build_deps.cmake" \
           -B "$WORk_DIR/build"

```
# Open in Android Studio
