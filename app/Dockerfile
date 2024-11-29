FROM ubuntu:22.04

ENV NDK_VERSION="27.0.12077973" \
CMAKE_VERSION="3.30.5" \
ANDROID_SDK_ROOT=/opt/android-sdk \
ANDROID_NDK_ROOT=${ANDROID_SDK_ROOT}/ndk/$NDK_VERSION \
CMDTOOLS="commandlinetools-linux-11076708_latest.zip"


RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    openjdk-17-jdk \
    python3 \
    git \
    perl \
    && rm -rf /var/lib/apt/lists/*

# Download and install Android Command Line Tools
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    wget "https://dl.google.com/android/repository/${CMDTOOLS}" -O cmdline-tools.zip && \
    unzip cmdline-tools.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools && \
    rm cmdline-tools.zip && \
    yes | sdkmanager --licenses && \
    sdkmanager --install \
    "platform-tools" \
    "platforms;android-33" \
    "build-tools;33.0.2" \
    "cmake;${CMAKE_VERSION}" \
    "ndk;$NDK_VERSION"

WORKDIR /src

# Build script
COPY . /src
COPY build.sh /build.sh
RUN chmod +x /build.sh

ENTRYPOINT ["/build.sh"]
