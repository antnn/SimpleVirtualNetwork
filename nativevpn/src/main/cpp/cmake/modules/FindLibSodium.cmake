include(ExternalProject)
set(SODIUM_SHA           $ENV{SODIUM_SHA})
set(SODIUM_VERSION       $ENV{SODIUM_VERSION})


include(${CMAKE_CURRENT_LIST_DIR}/CommonAndroidSetup.cmake)
get_autoconf_target(AUTOCONF_TARGET)

set(configure_flags
        --host=${AUTOCONF_TARGET})

    # Add ARM-specific flags if needed
if(ANDROID_ABI STREQUAL "arm64-v8a")
        list(APPEND configure_command ${configure_command} CFLAGS=-march=armv8-a+crypto+aes)
endif()

set(android_env "ANDROID_NDK_ROOT=${ANDROID_NDK}"
        "CC=${ANDROID_TOOLCHAIN_ROOT}/bin/${AUTOCONF_TARGET}${ANDROID_NATIVE_API_LEVEL}-clang"
        "AR=${ANDROID_TOOLCHAIN_ROOT}/bin/llvm-ar"
        "AS=${ANDROID_TOOLCHAIN_ROOT}/bin/${AUTOCONF_TARGET}${ANDROID_NATIVE_API_LEVEL}-clang"
        "CXX=${ANDROID_TOOLCHAIN_ROOT}/bin/${AUTOCONF_TARGET}${ANDROID_NATIVE_API_LEVEL}-clang++"
        "LD=${ANDROID_TOOLCHAIN_ROOT}/bin/ld"
        "RANLIB=${ANDROID_TOOLCHAIN_ROOT}/bin/llvm-ranlib"
        "STRIP=${ANDROID_TOOLCHAIN_ROOT}/bin/llvm-strip"
        "PATH=${ANDROID_TOOLCHAIN_ROOT}/bin:$ENV{PATH}")

set(CONFIGURE_COMMAND
    cd "<SOURCE_DIR>" &&
    ${CMAKE_COMMAND} -E env ${android_env} "<SOURCE_DIR>/configure" ${configure_flags}
                             "--prefix=<INSTALL_DIR>")
  set(BUILD_COMMAND
    ${CMAKE_COMMAND} -E env ${android_env} $(MAKE) -sC "<SOURCE_DIR>" install)
  set(INSTALL_COMMAND
    ${CMAKE_COMMAND} -E env ${android_env} $(MAKE) -sC "<SOURCE_DIR>" install)


ExternalProject_Add(libsodium
  URL https://github.com/jedisct1/libsodium/archive/refs/tags/${SODIUM_VERSION}.tar.gz
  URL_HASH SHA256=${SODIUM_SHA}
  PREFIX ${CMAKE_CURRENT_BINARY_DIR}/libsodium
  CONFIGURE_COMMAND ${CONFIGURE_COMMAND}
  BUILD_COMMAND ${BUILD_COMMAND}
  INSTALL_COMMAND ${INSTALL_COMMAND}
  DOWNLOAD_EXTRACT_TIMESTAMP 0
)
ExternalProject_Get_Property(libsodium INSTALL_DIR)
list(APPEND CMAKE_PREFIX_PATH ${INSTALL_DIR})

set(LIBSODIUM_INCLUDE_DIR ${INSTALL_DIR}/include)
set(LIBSODIUM_LIBRARY ${INSTALL_DIR}/lib/libsodium.so)
set(LIBSODIUM_FOUND TRUE)

# Set both SODIUM_LIBRARIES and SODIUM_LINK_LIBRARIES
set(SODIUM_LIBRARIES ${INSTALL_DIR}/lib/libsodium.so)
set(SODIUM_LINK_LIBRARIES ${INSTALL_DIR}/lib/libsodium.so)

# Create an imported target for libsodium
add_library(sodium SHARED IMPORTED GLOBAL)
set_target_properties(sodium PROPERTIES
    IMPORTED_LOCATION ${INSTALL_DIR}/lib/libsodium.so
    INTERFACE_INCLUDE_DIRECTORIES ${INSTALL_DIR}/include
)

include_directories(${INSTALL_DIR}/include)