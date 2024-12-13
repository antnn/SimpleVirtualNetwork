# Clone and open in Android Studio on Linux 
[Linux make tool is required](https://github.com/antnn/SimpleVirtualNetwork/blob/b2b660cf6ed07ee14527e375b763712a29600edd/nativevpn/src/main/cpp/cmake/modules/FindOpenSSL.cmake#L42)
# OR Install SDK
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
cd SimpleVirtualNetwork
source nativevpn/deps.txt
cd nativevpn/src/main/cpp/

CMAKE_DIR="$HOME/Android/cmake"
LATEST_CMAKE=$(ls -d $CMAKE_DIR/*/ | sort -V | tail -n 1)
CMAKE_BIN="$LATEST_CMAKE/bin/cmake"


ABIS=("arm64-v8a" "armeabi-v7a" "x86" "x86_64")
for ANDROID_ABI in "${ABIS[@]}"; do
    echo "Configuring for ABI: ${ANDROID_ABI}"
    mkdir -p "build_${ANDROID_ABI}"
    (cd "build_${ANDROID_ABI}"
        ${CMAKE_BIN} \
            -DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK_ROOT}/build/cmake/android.toolchain.cmake \
            -DANDROID_ABI=${ANDROID_ABI} \
            -DANDROID_PLATFORM=android-${MIN_SDK_VERSION} \
            ..
        ${CMAKE_BIN} --build . -j$(nproc)
    )
done
```

# Note: Files to look at
[SoftetherVPN patch](https://github.com/antnn/SimpleVirtualNetwork/blob/main/nativevpn/src/main/cpp/deps/softethervpn.patch) 

