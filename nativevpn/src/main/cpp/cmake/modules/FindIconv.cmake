include(ExternalProject)
set(ICONV_VERSION        $ENV{ICONV_VERSION})
set(ICONV_SHA            $ENV{ICONV_SHA})

if(NOT ICONV_VERSION)
    set(ICONV_VERSION "1.17")  # Set a default version if not specified
endif()

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


# Configure flags for Android build
set(configure_flags
    --host=${AUTOCONF_TARGET}
    --enable-shared)

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

ExternalProject_Add(libiconv
    URL https://ftp.gnu.org/pub/gnu/libiconv/libiconv-${ICONV_VERSION}.tar.gz
    URL_HASH SHA256=${ICONV_SHA}
    PREFIX ${CMAKE_CURRENT_BINARY_DIR}/libiconv
    CONFIGURE_COMMAND ${CONFIGURE_COMMAND}
    BUILD_COMMAND ${BUILD_COMMAND}
    INSTALL_COMMAND ${INSTALL_COMMAND}
    DOWNLOAD_EXTRACT_TIMESTAMP 0
)
ExternalProject_Get_Property(libiconv INSTALL_DIR)
list(APPEND CMAKE_PREFIX_PATH ${INSTALL_DIR})

# Set the variables
set(ICONV_INCLUDE_DIR ${INSTALL_DIR}/include)
set(ICONV_LIBRARY ${INSTALL_DIR}/lib/libiconv.so)
set(ICONV_FOUND TRUE)

# Create an imported target for libiconv
add_library(Iconv SHARED IMPORTED GLOBAL)
set_target_properties(Iconv PROPERTIES
    IMPORTED_LOCATION ${INSTALL_DIR}/lib/libiconv.so
    INTERFACE_INCLUDE_DIRECTORIES ${INSTALL_DIR}/include
)

# Export variables for find_package compatibility
set(Iconv_INCLUDE_DIRS ${ICONV_INCLUDE_DIR})
set(Iconv_LIBRARIES ${ICONV_LIBRARY})
set(Iconv_FOUND ${ICONV_FOUND})
include_directories(${INSTALL_DIR}/include)
