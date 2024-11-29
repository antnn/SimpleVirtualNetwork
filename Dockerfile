FROM ubuntu:22.04

ENV NDK_VERSION="27.0.12077973" \
    CMAKE_VERSION="3.30.5" \
    ANDROID_VERSION="35" \
    BUILD_TOOLS="35.0.0" \
    ANDROID_HOME=/opt/android-sdk \
    ANDROID_NDK_ROOT=/opt/android-sdk/ndk/${NDK_VERSION} \
    PATH=${PATH}:/opt/android-sdk/cmdline-tools/bin

RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    openjdk-17-jdk \
    python3 \
    git \
    perl \
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
