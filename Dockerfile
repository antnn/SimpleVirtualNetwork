FROM ubuntu:22.04


ENV NDK_VERSION="27.0.12077973" \
    CMAKE_VERSION="3.30.5" \
    ANDROID_VERSION="35" \
    BUILD_TOOLS="35.0.0" \
    BUILD_TYPE="Release" \
    MIN_SDK_VERSION="24" \
    SOFTETHERVPN_VERSION="5.02.5187" \
    OPENSSL_VERSION="3.4.0" \
    SODIUM_VERSION="1.0.20-RELEASE" \
    ANDROID_HOME="/opt/android-sdk" \
    ANDROID_NDK_ROOT="${ANDROID_HOME}/ndk/${NDK_VERSION}" \
    PATH="${ANDROID_HOME}/cmake/${CMAKE_VERSION}/bin:${ANDROID_HOME}/cmdline-tools/bin:${PATH}"


# Even though the host compiler is not used for the actual build process,
# CMake needs a functional host compiler and development libraries to perform its configuration tests
# before transitioning to the Android NDK toolchain for the actual build.
# This requirement arises because we utilize CMake's ExternalProject functionality,
# where the main project, which includes and initiates the external build, relies on the host configuration.
RUN apt-get update && apt-get install -y \
    wget unzip openjdk-17-jdk python3 git perl \
    build-essential pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Download and install Android Command Line Tools
RUN mkdir -p ${ANDROID_HOME} && \
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

WORKDIR /src

# Build script
COPY . /src
COPY build.sh /build.sh
RUN chmod +x /build.sh

ENTRYPOINT ["/build.sh"]
