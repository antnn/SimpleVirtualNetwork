 ```bash
 (cd deps;
    bash download.sh
    bash hamcorebuilder.sh
    cd external;
    git apply ../../softether.patch
 )
 /var/home/$USER/Android/Sdk/cmake/3.22.1/bin/cmake \
      -H/var/home/$USER/AndroidStudioProjects/SimpleVPN/libexecvpnclient/src/main/cpp \
      -DCMAKE_SYSTEM_NAME=Android \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
      -DCMAKE_SYSTEM_VERSION=24 \
      -DANDROID_PLATFORM=android-24 \
      -DANDROID_ABI=arm64-v8a \
      -DCMAKE_ANDROID_ARCH_ABI=arm64-v8a \
      -DANDROID_NDK=/var/home/$USER/Android/Sdk/ndk/26.1.10909125 \
      -DCMAKE_ANDROID_NDK=/var/home/$USER/Android/Sdk/ndk/26.1.10909125 \
      -DCMAKE_TOOLCHAIN_FILE=/var/home/$USER/Android/Sdk/ndk/26.1.10909125/build/cmake/android.toolchain.cmake \
      -DCMAKE_MAKE_PROGRAM=/var/home/$USER/Android/Sdk/cmake/3.22.1/bin/ninja \
      -DCMAKE_LIBRARY_OUTPUT_DIRECTORY=/var/home/$USER/AndroidStudioProjects/SimpleVPN/libexecvpnclient/build/intermediates/cxx/Debug/3z11343i/obj/arm64-v8a \
      -DCMAKE_RUNTIME_OUTPUT_DIRECTORY=/var/home/$USER/AndroidStudioProjects/SimpleVPN/libexecvpnclient/build/intermediates/cxx/Debug/3z11343i/obj/arm64-v8a \
      -DCMAKE_BUILD_TYPE=Debug \
      -B/var/home/$USER/AndroidStudioProjects/SimpleVPN/libexecvpnclient/.cxx/Debug/3z11343i/arm64-v8a \
      -GNinja \
      -DMY_ANDROID_MODULE_DIR=/var/home/$USER/AndroidStudioProjects/SimpleVPN/libexecvpnclient
```
