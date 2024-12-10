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


get_openssl_target(OPENSSL_TARGET)
include(${CMAKE_CURRENT_LIST_DIR}/CommonAndroidSetup.cmake)
get_autoconf_target(AUTOCONF_TARGET)


set(openssl_configure_flags
        ${OPENSSL_TARGET}
        -D__ANDROID_API__=${ANDROID_NATIVE_API_LEVEL}
        -fPIC shared no-ui no-ui-console no-engine no-filenames)


set(OPENSSL_CONFIGURE_COMMAND
    cd "<SOURCE_DIR>" &&
    ${CMAKE_COMMAND} -E env ${android_env} "<SOURCE_DIR>/Configure" ${openssl_configure_flags}
                             "--prefix=<INSTALL_DIR>")
  set(OPENSSL_BUILD_COMMAND
    ${CMAKE_COMMAND} -E env ${android_env} $(MAKE) -sC "<SOURCE_DIR>" build_libs)
  set(OPENSSL_INSTALL_COMMAND
    ${CMAKE_COMMAND} -E env ${android_env} $(MAKE) -sC "<SOURCE_DIR>" install_dev install_runtime)

if(DEFINED OPENSSL_SOURCE_DIR AND EXISTS ${OPENSSL_SOURCE_DIR})
ExternalProject_Add(openssl
SOURCE_DIR ${OPENSSL_SOURCE_DIR}
PREFIX ${CMAKE_CURRENT_BINARY_DIR}/openssl
CONFIGURE_COMMAND ${OPENSSL_CONFIGURE_COMMAND}
BUILD_COMMAND ${OPENSSL_BUILD_COMMAND}
INSTALL_COMMAND ${OPENSSL_INSTALL_COMMAND}
DOWNLOAD_COMMAND ""
)
else()
ExternalProject_Add(openssl
  URL https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz
  URL_HASH SHA256=${OPENSSL_SHA_VER}
  PREFIX ${CMAKE_CURRENT_BINARY_DIR}/openssl
  CONFIGURE_COMMAND ${OPENSSL_CONFIGURE_COMMAND}
  BUILD_COMMAND ${OPENSSL_BUILD_COMMAND}
  INSTALL_COMMAND ${OPENSSL_INSTALL_COMMAND}
  DOWNLOAD_EXTRACT_TIMESTAMP 0
)
endif()
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