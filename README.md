# Install SDK
```bash
apt-get update && apt-get install -y \
    wget unzip openjdk-17-jdk python3 git perl \
    build-essential pkg-config;

export NDK_VERSION="27.0.12077973"
export CMAKE_VERSION="3.30.5"
export ANDROID_VERSION="35"
export BUILD_TOOLS="35.0.0"
export ANDROID_HOME="$HOME/Android"
export ANDROID_NDK_ROOT="${ANDROID_HOME}/ndk/${NDK_VERSION}"
export PATH="${ANDROID_HOME}/cmake/${CMAKE_VERSION}/bin:${ANDROID_HOME}/cmdline-tools/bin:${PATH}"

mkdir -p ${ANDROID_HOME} && \
    cd ${ANDROID_HOME} && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip && \
    unzip commandlinetools-linux*.zip && \
    rm commandlinetools-linux*.zip && \
    cd cmdline-tools/bin && \
    yes | ./sdkmanager --sdk_root=${ANDROID_HOME} --install \
        "platform-tools" \
        "platforms;android-${ANDROID_VERSION}" \
        "ndk;${NDK_VERSION}" \
        "build-tools;${BUILD_TOOLS}" \
        "cmake;${CMAKE_VERSION}"
```
# Build deps of sofrethervpn and build libvpnclient.so
```bash
# + previous exports
export BUILD_TYPE="Release"
export MIN_SDK_VERSION="24"
export SOFTETHERVPN_VERSION="5.02.5187"
export OPENSSL_VERSION="3.4.0"
export SODIUM_VERSION="1.0.20-RELEASE"
export ICONV_VERSION="1.17"

cd SimpleVirtualNetwork/nativevpn/src/main/cpp/deps
PROJECTS_DIR="projects"
PNAME="SimpleVirtualNetwork"
MODULE_NAME="nativevpn"
WORK_DIR="$HOME/$PROJECTS_DIR/$PNAME/$MODULE_NAME/src/main/cpp/deps"

CMAKE_DIR="$HOME/Android/cmake"
LATEST_CMAKE=$(ls -d $CMAKE_DIR/*/ | sort -V | tail -n 1)
CMAKE_BIN="$LATEST_CMAKE/bin/cmake"

$CMAKE_BIN -H"$WORK_DIR" \
           -C "$WORK_DIR/build_deps.cmake" \
           -B "$WORK_DIR/build"

```
Multicore build enabled by default
```cmake
cmake_host_system_information(RESULT nproc
        QUERY NUMBER_OF_PHYSICAL_CORES)
set(NPROC ${nproc} CACHE INTERNAL "")
execute_process(COMMAND ${CMAKE_COMMAND} --build . -j${NPROC} ... )
```
# Open in Android Studio

[build_deps.cmake](https://github.com/antnn/SimpleVirtualNetwork/blob/main/nativevpn/src/main/cpp/deps/build_deps.cmake#L129)
[CMakeLists.txt](https://github.com/antnn/SimpleVirtualNetwork/blob/main/nativevpn/src/main/cpp/deps/CMakeLists.txt#L35)
[SoftetherVPN patch](https://github.com/antnn/SimpleVirtualNetwork/blob/main/nativevpn/src/main/cpp/deps/softethervpn.patch)

