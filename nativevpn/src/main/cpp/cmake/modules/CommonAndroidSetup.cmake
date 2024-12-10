function(get_autoconf_target autoconf_target)
    if(ANDROID_ABI STREQUAL "arm64-v8a")
        set(${autoconf_target} "aarch64-linux-android" PARENT_SCOPE)
    elseif(ANDROID_ABI STREQUAL "armeabi-v7a")
        set(${autoconf_target} "armv7a-linux-androideabi" PARENT_SCOPE)
    elseif(ANDROID_ABI STREQUAL "x86")
        set(${autoconf_target} "i686-linux-android" PARENT_SCOPE)
    elseif(ANDROID_ABI STREQUAL "x86_64")
        set(${autoconf_target} "x86_64-linux-android" PARENT_SCOPE)
    else()
        message(FATAL_ERROR "Unsupported ABI: ${ANDROID_ABI}")
    endif()
endfunction()

get_autoconf_target(AUTOCONF_TARGET)

set(android_env "ANDROID_NDK_ROOT=${ANDROID_NDK}"
    "CC=${ANDROID_TOOLCHAIN_ROOT}/bin/${AUTOCONF_TARGET}${ANDROID_NATIVE_API_LEVEL}-clang"
    "AR=${ANDROID_TOOLCHAIN_ROOT}/bin/llvm-ar"
    "AS=${ANDROID_TOOLCHAIN_ROOT}/bin/${AUTOCONF_TARGET}${ANDROID_NATIVE_API_LEVEL}-clang"
    "CXX=${ANDROID_TOOLCHAIN_ROOT}/bin/${AUTOCONF_TARGET}${ANDROID_NATIVE_API_LEVEL}-clang++"
    "LD=${ANDROID_TOOLCHAIN_ROOT}/bin/ld"
    "RANLIB=${ANDROID_TOOLCHAIN_ROOT}/bin/llvm-ranlib"
    "STRIP=${ANDROID_TOOLCHAIN_ROOT}/bin/llvm-strip"
    "PATH=${ANDROID_TOOLCHAIN_ROOT}/bin:$ENV{PATH}")
