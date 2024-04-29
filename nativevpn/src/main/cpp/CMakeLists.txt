cmake_minimum_required(VERSION 3.22.1)

project("nativevpn")

#Keep in sync with deps/CMakeLists.txt and deps/build_deps.cmake
set(A_PREFIX_PATH "${CMAKE_SOURCE_DIR}/deps/external/root/${ANDROID_ABI}" CACHE INTERNAL "" )
#fix find_package
list(APPEND CMAKE_PREFIX_PATH "${A_PREFIX_PATH}" )
set(CMAKE_FIND_ROOT_PATH "${CMAKE_FIND_ROOT_PATH}" "${A_PREFIX_PATH}" )
#


find_package(PkgConfig REQUIRED)
find_package(OpenSSL REQUIRED)
pkg_search_module(SODIUM libsodium REQUIRED)
find_library(lib_Mayaqua mayaqua REQUIRED)
find_library(lib_Cedar cedar REQUIRED)
find_library(lib_Hamcore hamcore.se2 REQUIRED)
find_library(lib_Vpnclient androidvpnclient REQUIRED)


add_library(${CMAKE_PROJECT_NAME} SHARED
        nativevpn.c)
target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE
        android
        log
        OpenSSL::SSL
        OpenSSL::Crypto
        $<IF:$<BOOL:SODIUM_LINK_LIBRARIES>,${SODIUM_LINK_LIBRARIES},${SODIUM_LIBRARIES}>
        ${lib_Mayaqua}
        ${lib_Cedar}
        #${lib_Hamcore}
        ${lib_vpnclient}
)
