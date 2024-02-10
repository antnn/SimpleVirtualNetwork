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

project("libexecvpnclient")

cmake_host_system_information(RESULT nproc
        QUERY NUMBER_OF_PHYSICAL_CORES)
set(NPROC ${nproc} CACHE INTERNAL "")

set(A_PREFIX_PATH "${CMAKE_SOURCE_DIR}/deps/external/root/${ANDROID_ABI}" CACHE INTERNAL "" )
set(DEPS_DIR "deps/external" CACHE INTERNAL "" )


#fix find_package
list(APPEND CMAKE_PREFIX_PATH "${A_PREFIX_PATH}")
set(CMAKE_FIND_ROOT_PATH "${CMAKE_FIND_ROOT_PATH}" "${A_PREFIX_PATH}" )
#

find_package(PkgConfig REQUIRED)

add_subdirectory(${DEPS_DIR}/..) # deps/external/..

find_package(OpenSSL)
if (NOT OPENSSL_FOUND)
    get_openssl_target(OPENSSL_TARGET)
    set(openssl_configure_command
            "./Configure ${OPENSSL_TARGET} --prefix=${A_PREFIX_PATH} \
            -D__ANDROID_API__=${ANDROID_NATIVE_API_LEVEL}\
            -fPIC no-ui no-ui-console no-engine no-filenames " )
    build_autoconf_external_project(openssl "" "${openssl_configure_command}" "" " install_dev install_runtime_libs " )
    find_package(OpenSSL REQUIRED)
endif ()

get_autoconf_target(AUTOCONF_TARGET)
set(common_configure_command
        "./configure --host=${AUTOCONF_TARGET}  --prefix=${A_PREFIX_PATH}"
        )
find_package(Iconv)
if (NOT Iconv_FOUND)
    build_autoconf_external_project(iconv "" "${common_configure_command}" "" " install-lib ")
    find_package(Iconv REQUIRED)
endif ()

pkg_search_module(SODIUM libsodium)
IF(NOT SODIUM_FOUND)
    if(ANDROID_ABI STREQUAL "arm64-v8a")
        build_autoconf_external_project(libsodium  CFLAGS=-march=armv8-a+crypto+aes
                " ${common_configure_command} " "" " install ")
    else ()
        build_autoconf_external_project(libsodium "" "${common_configure_command}" "" " install ")
    endif()
    pkg_search_module(SODIUM libsodium REQUIRED)
endif ()

find_library(LIB_READLINE readline)
IF (NOT LIB_READLINE)
    build_autoconf_external_project(readline "" "${common_configure_command}" "" " install-shared " )
    find_library(LIB_READLINE readline REQUIRED)
endif()
message(STATUS "Found Readline: ${LIB_READLINE}")


find_package(Curses)
IF (NOT CURSES_FOUND)
    build_autoconf_external_project(ncurses "" "${common_configure_command} \
        --with-shared --disable-stripping" "" "install")
    message(WARNING "Retry if fails, it may work. Cmake may have built curses already")
    find_package(Curses REQUIRED)
endif()


find_library(lib_Mayaqua mayaqua)
find_library(lib_Cedar cedar)
find_library(lib_Hamcore.se2.so hamcore.se2)
find_library(lib_Softethervpnclient.se2.so softethervpnclient)
if(NOT lib_Mayaqua AND NOT lib_Cedar AND NOT lib_Hamcore AND NOT lib_Softethervpnclient)
    message(STATUS "Building hamcorebuilder on host system and adding to PATH during vpnclient build")
    execute_process(COMMAND /bin/bash "${DEPS_DIR}/hamcorebuilder.sh"
            WORKING_DIRECTORY ${DEPS_DIR} )

    set(softether_cmake_args ${CMAKE_ARGS} )
    list(APPEND softether_cmake_args "-DCMAKE_PREFIX_PATH=${A_PREFIX_PATH}" )
    list(APPEND softether_cmake_args "-DCMAKE_FIND_ROOT_PATH=${A_PREFIX_PATH}" )
    message(STATUS "Replacing string 'hamcore.se' to 'hamcore.se.so'")
    execute_process(  COMMAND  bash -c "find . -type f -name \"*\" -exec sed -i 's/hamcore\\.se2\\([^.\\]\\|\\$\\)/hamcore.se2.so\\1/g' {} +"
            WORKING_DIRECTORY ${DEPS_DIR}/SoftEtherVPN)
    build_external_cmake(SoftEtherVPN
            "PATH=${DEPS_DIR}:$ENV{PATH}"
            ${softether_cmake_args} )

    file(RENAME "${DEPS_DIR}/build/${ANDROID_ABI}/SoftEtherVPN/vpnclient"
            "${DEPS_DIR}/build/${ANDROID_ABI}/SoftEtherVPN/libsoftethervpnclient.so"
            )
    file(GLOB SO_FILES "${DEPS_DIR}/../build/${ANDROID_ABI}/SoftEtherVPN/*.so")
    file(COPY ${SO_FILES} DESTINATION ${A_PREFIX_PATH}/lib)
    file(COPY ${SO_FILES} DESTINATION ${MY_ANDROID_MODULE_DIR}/src/main/jniLibs/${ANDROID_ABI})

    find_library(lib_Mayaqua mayaqua)
    find_library(lib_Cedar cedar)
endif()

#Keep it so Android Studio copies libraries automatically to APK's jniLibs
add_library(${CMAKE_PROJECT_NAME} SHARED
        libexecvpnclient.cpp)
target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE
        android
        log
        OpenSSL::SSL
        OpenSSL::Crypto
        Iconv::Iconv
        ${CURSES_LIBRARIES}
        ${LIB_READLINE}
        $<IF:$<BOOL:SODIUM_LINK_LIBRARIES>,${SODIUM_LINK_LIBRARIES},${SODIUM_LIBRARIES}>
        ${lib_Mayaqua}
        ${lib_Cedar}
        ${lib_Hamcore}
        )
