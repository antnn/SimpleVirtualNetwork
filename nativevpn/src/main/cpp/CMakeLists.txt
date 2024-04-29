cmake_minimum_required(VERSION 3.22.1)

set(CMAKE_ARGS "" CACHE INTERNAL "")
get_cmake_property(vars CACHE_VARIABLES)
foreach(var ${vars})
    if("${var}" MATCHES "^(CMAKE_|BUILD_|INSTALL_|CPACK_|prefix_result|_|pkgcfg_lib_|Iconv_|OPENSSL_|CURSES_|NCURSES_|SODIUM_|FIND_PACKAGE_|PKG_CONFIG_)")
        if( NOT "${var}" MATCHES "^(CMAKE_TOOLCHAIN_)")
            continue()
        endif ()
    endif()
    list(APPEND CMAKE_ARGS "-D${var}=${${var}}")
endforeach()

project("nativevpn")

cmake_host_system_information(RESULT nproc
        QUERY NUMBER_OF_PHYSICAL_CORES)
set(NPROC ${nproc} CACHE INTERNAL "")

#Keep in sync with deps/CMakeLists.txt and deps/build_deps.cmake
set(A_PREFIX_PATH "${CMAKE_SOURCE_DIR}/deps/external/root/${ANDROID_ABI}" CACHE INTERNAL "" )
#
set(EXTERNAL_DIR "${CMAKE_SOURCE_DIR}/deps/external" CACHE INTERNAL "" )
set(DEPS_DIR "${CMAKE_SOURCE_DIR}/deps" CACHE INTERNAL "" )


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


