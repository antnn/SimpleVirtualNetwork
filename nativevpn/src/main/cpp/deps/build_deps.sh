#!/bin/bash
export BUILD="Release"
export MIN_SDK_VERSION="24"
export NDK_VERSION="26.2.11394342"
export NDK="$HOME/Android/Sdk/ndk/$NDK_VERSION"
export CMAKE_BIN="$HOME/Android/Sdk/cmake/3.22.1/bin/cmake"

export APP_NAME="VpnOverHttps"
export NATIVE_MODULE_NAME="nativevpn"
export ANDROID_MODULE_DIR="$HOME/AndroidStudioProjects/$APP_NAME/$NATIVE_MODULE_NAME"
export EXTRA_ARGS="-DMY_ANDROID_MODULE_DIR=$ANDROID_MODULE_DIR"

if [[ ! -d "$ANDROID_MODULE_DIR" ]]
then
  echo "Error: Could not find dir: $ANDROID_MODULE_DIR"
  exit 1
fi

abis=("arm64-v8a" "armeabi-v7a" "x86" "x86_64")
for ABI in "${abis[@]}"
do
  echo "Processing ABI: $ABI"
   mkdir -p "builds/build-$ABI"
   ( cd "builds/build-$ABI"
     "$CMAKE_BIN" \
       -DCMAKE_BUILD_TYPE="$BUILD" \
       -DCMAKE_TOOLCHAIN_FILE="$NDK/build/cmake/android.toolchain.cmake" \
       -DANDROID_ABI="$ABI" \
       -DANDROID_PLATFORM="android-$MIN_SDK_VERSION" \
       "$EXTRA_ARGS" \
       -B"$PWD" ../../
     "$CMAKE_BIN" --build .
     echo -e "Libs to be used with root CMakeLists.txt installed at:\n \
     \${CMAKE_SOURCE_DIR}/deps/external/root/\${ANDROID_ABI}"
   )
done
