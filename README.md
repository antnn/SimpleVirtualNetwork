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
cd SimpleVirtualNetwork/nativevpn/src/main/cpp/
export NDK_VERSION="27.0.12077973"
export CMAKE_VERSION="3.30.5"
export ANDROID_VERSION="35"
export BUILD_TOOLS="35.0.0"
export BUILD_TYPE="Release"
export MIN_SDK_VERSION="24"
export SOFTETHERVPN_VERSION="5.02.5187"
export ANDROID_HOME="$HOME/Android"
export ANDROID_NDK_ROOT="${ANDROID_HOME}/ndk/${NDK_VERSION}"
export PATH="${ANDROID_HOME}/cmake/${CMAKE_VERSION}/bin:${ANDROID_HOME}/cmdline-tools/bin:${PATH}"

export OPENSSL_VERSION="3.4.0"
export SODIUM_VERSION="1.0.20-RELEASE"
export ICONV_VERSION="1.17"
export OPENSSL_SHA=e15dda82fe2fe8139dc2ac21a36d4ca01d5313c75f99f46c4e8a27709b7294bf
export SODIUM_SHA=8e5aeca07a723a27bbecc3beef14b0068d37e7fc0e97f51b3f1c82d2a58005c1
export ICONV_SHA=8f74213b56238c85a50a5329f77e06198771e70dd9a739779f4c02f65d971313
export SOFTETHERVPN_SHA="2add80f1a530389d54026f9a4d11005dc4b77e689ac4c4a0143c31c9121f7015"

export SODIUM_URL="https://github.com/jedisct1/libsodium/archive/refs/tags/${SODIUM_VERSION}.tar.gz"
export OPENSSL_URL="https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
export ICONV_URL="https://ftp.gnu.org/pub/gnu/libiconv/libiconv-${ICONV_VERSION}.tar.gz"
export SOFTETHERVPN_URL="https://codeload.github.com/SoftEtherVPN/SoftEtherVPN/tar.gz/refs/tags/${SOFTETHERVPN_VERSION}"


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
[build_deps.cmake](https://github.com/antnn/SimpleVirtualNetwork/blob/main/nativevpn/src/main/cpp/deps/build_deps.cmake#L129) <br>
[CMakeLists.txt](https://github.com/antnn/SimpleVirtualNetwork/blob/main/nativevpn/src/main/cpp/deps/CMakeLists.txt#L35) <br>
[SoftetherVPN patch](https://github.com/antnn/SimpleVirtualNetwork/blob/main/nativevpn/src/main/cpp/deps/softethervpn.patch) 

