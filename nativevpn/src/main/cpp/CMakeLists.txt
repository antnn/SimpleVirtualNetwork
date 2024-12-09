cmake_minimum_required(VERSION 3.22.1)

project("nativevpn")
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake/modules")
include(${CMAKE_CURRENT_LIST_DIR}/cmake/modules/download.cmake)

set(OPENSSL_VERSION      "$ENV{OPENSSL_VERSION}"      CACHE STRING "OpenSSL version")
set(OPENSSL_URL          "$ENV{OPENSSL_URL}"          CACHE STRING "OpenSSL URL")
set(OPENSSL_SHA          "$ENV{OPENSSL_SHA}"          CACHE STRING "openssl sha256sum")
set(SODIUM_VERSION       "$ENV{SODIUM_VERSION}"       CACHE STRING "libsodium version")
set(SODIUM_URL           "$ENV{SODIUM_URL}"           CACHE STRING "libsodium URL")
set(SODIUM_SHA           "$ENV{SODIUM_SHA}"           CACHE STRING "libsodium sha256sum")
set(ICONV_VERSION        "$ENV{ICONV_VERSION}"        CACHE STRING "libiconv version")
set(ICONV_SHA            "$ENV{ICONV_SHA}"            CACHE STRING "libiconv sha256")
set(ICONV_URL            "$ENV{ICONV_URL}"            CACHE STRING "libiconv URL")
set(SOFTETHERVPN_VERSION "$ENV{SOFTETHERVPN_VERSION}" CACHE STRING "SoftetherVPN version")
set(SOFTETHERVPN_REPO    "$ENV{SOFTETHERVPN_REPO}"     CACHE STRING "SoftetherVPN repo")



set(OPENSSL_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/deps/openssl)
download_and_extract("${OPENSSL_URL}" "${OPENSSL_SHA}" "${OPENSSL_SOURCE_DIR}" )

set(SODIUM_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/deps/libsodium)
download_and_extract("${SODIUM_URL}" "${SODIUM_SHA}" "${SODIUM_SOURCE_DIR}" )

set(ICONV_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/deps/iconv)
download_and_extract("${ICONV_URL}" "${ICONV_SHA}" "${ICONV_SOURCE_DIR}" )

set(SOFTETHERVPN_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/deps/softethervpn)



find_package(Git REQUIRED)
clone_if_not_exists(
        "${SOFTETHERVPN_REPO}"
        "${SOFTETHERVPN_VERSION}"
        "${SOFTETHERVPN_SOURCE_DIR}"
)

find_package(PkgConfig REQUIRED)
find_package(OpenSSL REQUIRED)
find_package(LibSodium REQUIRED)
find_package(Iconv REQUIRED)


include(${CMAKE_CURRENT_LIST_DIR}/cmake/modules/hamcore_builder.cmake)
build_hamcore_se2(
        "${SOFTETHERVPN_SOURCE_DIR}"  # Path to SoftEtherVPN source
        "${CMAKE_SOURCE_DIR}/../res/raw"                # Where to place hamcore.se2
)



add_subdirectory("${SOFTETHERVPN_SOURCE_DIR}"/Cedar)
add_subdirectory(Mayaqua)

add_library(${CMAKE_PROJECT_NAME} SHARED
        nativevpn.c
        androidhelpers.c)
target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE
        android
        log
        OpenSSL::SSL
        OpenSSL::Crypto
        $<IF:$<BOOL:SODIUM_LINK_LIBRARIES>,${SODIUM_LINK_LIBRARIES},${SODIUM_LIBRARIES}>
        #${lib_Mayaqua}
        #${lib_Cedar}
        #${lib_Hamcore}
        #${lib_Vpnclient}
)
