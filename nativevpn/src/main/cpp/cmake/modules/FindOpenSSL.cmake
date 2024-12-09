include(ExternalProject)
set(OPENSSL_VERSION      $ENV{OPENSSL_VERSION})
set(OPENSSL_SHA_VER      "$ENV{OPENSSL_SHA}")
function(get_openssl_target out_var)
    if(ANDROID_ABI STREQUAL "armeabi-v7a")
        set(${out_var} "android-arm" PARENT_SCOPE)
    elseif(ANDROID_ABI STREQUAL "arm64-v8a")
        set(${out_var} "android-arm64" PARENT_SCOPE)
    elseif(ANDROID_ABI STREQUAL "x86")
        set(${out_var} "android-x86" PARENT_SCOPE)
    elseif(ANDROID_ABI STREQUAL "x86_64")
        set(${out_var} "android-x86_64" PARENT_SCOPE)
    endif()
endfunction()

function(get_autoconf_target autoconf_target)
    if (ANDROID_ABI STREQUAL "arm64-v8a")
        set(${autoconf_target} "aarch64-linux-android" PARENT_SCOPE)
    elseif (ANDROID_ABI STREQUAL "armeabi-v7a")
        set(${autoconf_target} "armv7a-linux-androideabi" PARENT_SCOPE)
    elseif (ANDROID_ABI STREQUAL "x86")
        set(${autoconf_target} "i686-linux-android" PARENT_SCOPE)
    elseif (ANDROID_ABI STREQUAL "x86_64")
        set(${autoconf_target} "x86_64-linux-android" PARENT_SCOPE)
    else()
        message(FATAL_ERROR "Unsupported ABI: ${ANDROID_ABI}")
    endif()
endfunction()

get_openssl_target(OPENSSL_TARGET)
get_autoconf_target(AUTOCONF_TARGET)

set(openssl_configure_flags
        ${OPENSSL_TARGET}
        -D__ANDROID_API__=${ANDROID_NATIVE_API_LEVEL}
        -fPIC shared no-ui no-ui-console no-engine no-filenames)

set(android_env "ANDROID_NDK_ROOT=${ANDROID_NDK}"
        "CC=${ANDROID_TOOLCHAIN_ROOT}/bin/${AUTOCONF_TARGET}${ANDROID_NATIVE_API_LEVEL}-clang"
        "AR=${ANDROID_TOOLCHAIN_ROOT}/bin/llvm-ar"
        "AS=${ANDROID_TOOLCHAIN_ROOT}/bin/${AUTOCONF_TARGET}${ANDROID_NATIVE_API_LEVEL}-clang"
        "CXX=${ANDROID_TOOLCHAIN_ROOT}/bin/${AUTOCONF_TARGET}${ANDROID_NATIVE_API_LEVEL}-clang++"
        "LD=${ANDROID_TOOLCHAIN_ROOT}/bin/ld"
        "RANLIB=${ANDROID_TOOLCHAIN_ROOT}/bin/llvm-ranlib"
        "STRIP=${ANDROID_TOOLCHAIN_ROOT}/bin/llvm-strip"
        "PATH=${ANDROID_TOOLCHAIN_ROOT}/bin:$ENV{PATH}")

set(OPENSSL_CONFIGURE_COMMAND
    cd "<SOURCE_DIR>" &&
    ${CMAKE_COMMAND} -E env ${android_env} "<SOURCE_DIR>/Configure" ${openssl_configure_flags}
                             "--prefix=<INSTALL_DIR>")
  set(OPENSSL_BUILD_COMMAND
    ${CMAKE_COMMAND} -E env ${android_env} $(MAKE) -sC "<SOURCE_DIR>" build_libs)
  set(OPENSSL_INSTALL_COMMAND
    ${CMAKE_COMMAND} -E env ${android_env} $(MAKE) -sC "<SOURCE_DIR>" install_dev install_runtime)


ExternalProject_Add(openssl
  URL https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz
  URL_HASH SHA256=${OPENSSL_SHA_VER}
  PREFIX ${CMAKE_CURRENT_BINARY_DIR}/openssl
  CONFIGURE_COMMAND ${OPENSSL_CONFIGURE_COMMAND}
  BUILD_COMMAND ${OPENSSL_BUILD_COMMAND}
  INSTALL_COMMAND ${OPENSSL_INSTALL_COMMAND}
  DOWNLOAD_EXTRACT_TIMESTAMP 0
)
ExternalProject_Get_Property(openssl INSTALL_DIR)

add_library(OpenSSL::Crypto SHARED IMPORTED GLOBAL)
add_library(OpenSSL::SSL SHARED IMPORTED GLOBAL)


add_dependencies(OpenSSL::Crypto openssl)
add_dependencies(OpenSSL::SSL openssl)

set_target_properties(OpenSSL::Crypto PROPERTIES
    IMPORTED_LOCATION "${INSTALL_DIR}/lib/libcrypto.so"
    INTERFACE_INCLUDE_DIRECTORIES "${INSTALL_DIR}/include"
)

set_target_properties(OpenSSL::SSL PROPERTIES
    IMPORTED_LOCATION "${INSTALL_DIR}/lib/libssl.so"
    INTERFACE_INCLUDE_DIRECTORIES "${INSTALL_DIR}/include"
    INTERFACE_LINK_LIBRARIES OpenSSL::Crypto
)
include_directories(${INSTALL_DIR}/include)
list(APPEND CMAKE_PREFIX_PATH ${INSTALL_DIR})



