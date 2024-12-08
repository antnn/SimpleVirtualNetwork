cmake_minimum_required(VERSION 3.22.1)

if(NOT ANDROID_ABI)
    return()
endif ()


project("deps_project")


#Keep in sync with ../CMakeLists.txt and ../build_deps.cmake
#set(A_PREFIX_PATH "${CMAKE_SOURCE_DIR}/softether_third_party/root/${ANDROID_ABI}" CACHE INTERNAL "" )
include(${CMAKE_CURRENT_SOURCE_DIR}/common.cmake)

#set(SOFTETHER_THIRD_PARTY_DIR "${CMAKE_SOURCE_DIR}/softether_third_party" CACHE INTERNAL "" )

#fix find_package
#list(APPEND CMAKE_PREFIX_PATH "${A_PREFIX_PATH}" )
#set(CMAKE_FIND_ROOT_PATH "${CMAKE_FIND_ROOT_PATH}" "${A_PREFIX_PATH}" )
#
set(DEPS_TARGET "deps_target")
add_custom_target(${DEPS_TARGET})


function(log_error error command args dir )
    string(REPLACE ";" "\\ " command_print "${command}")
    string(REPLACE ";" "\\ " args_print "${args}")
    message (SEND_ERROR "BUILD FAILED AT: ${dir}")
    message (SEND_ERROR "COMMAND: ${command_print}\n WITH ARGS: ${args_print}")
    message(FATAL_ERROR "Function Build_external command output:\n\
    ${error}")
endfunction()

function(build_external target src_dir)
    message(STATUS "Building external project: ${target} in: ${src_dir} ")
    set(trigger_build_dir "${src_dir}")

    set(CMAKE_LIST_CONTENT "
        cmake_minimum_required(VERSION 3.22.1)
        project(${target})
        include(ExternalProject)
        ExternalProject_add( ${target}
    ${ARGN} )
        add_custom_target(trigger_${target})
        add_dependencies(trigger_${target} ${target})
    ")
    file(WRITE "${trigger_build_dir}/CMakeLists.txt" "${CMAKE_LIST_CONTENT}")

    execute_process(COMMAND ${CMAKE_COMMAND} ${CMAKE_ARGS} .
            WORKING_DIRECTORY ${trigger_build_dir}
            RESULT_VARIABLE result
            ERROR_VARIABLE error
    )
    if(NOT result EQUAL "0")
        log_error("${error}" "${CMAKE_COMMAND}" "${CMAKE_ARGS}" "${trigger_build_dir}")
    endif()

    execute_process(COMMAND ${CMAKE_COMMAND} --build .
            WORKING_DIRECTORY ${trigger_build_dir}
            RESULT_VARIABLE result
            ERROR_VARIABLE error
    )
    if(NOT result EQUAL "0")
        log_error("${error}" "${CMAKE_COMMAND}" "--build ." "${trigger_build_dir}")
    endif()

endfunction()



function(get_openssl_target openssl_target)
    if (ANDROID_ABI STREQUAL "arm64-v8a")
        set(${openssl_target} "android-arm64" PARENT_SCOPE)
    elseif (ANDROID_ABI STREQUAL "armeabi-v7a")
        set(${openssl_target} "android-arm" PARENT_SCOPE)
    elseif (ANDROID_ABI STREQUAL "x86")
        set(${openssl_target} "android-x86" PARENT_SCOPE)
    elseif (ANDROID_ABI STREQUAL "x86_64")
        set(${openssl_target} "android-x86_64" PARENT_SCOPE)
    else()
        message(FATAL_ERROR "Unsupported ABI: ${ANDROID_ABI}")
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


function(build_autoconf_external_project project env configure_cmd build_args install_args)
    get_autoconf_target(AUTOCONF_TARGET)
    set(android_env "ANDROID_NDK_ROOT=${ANDROID_NDK} \
CC=${ANDROID_TOOLCHAIN_ROOT}/bin/${AUTOCONF_TARGET}${ANDROID_NATIVE_API_LEVEL}-clang \
AR=${ANDROID_TOOLCHAIN_ROOT}/bin/llvm-ar \
AS=${ANDROID_TOOLCHAIN_ROOT}/bin/${AUTOCONF_TARGET}${ANDROID_NATIVE_API_LEVEL}-clang \
CXX=${ANDROID_TOOLCHAIN_ROOT}/bin/${AUTOCONF_TARGET}${ANDROID_NATIVE_API_LEVEL}-clang++ \
LD=${ANDROID_TOOLCHAIN_ROOT}/bin/ld \
RANLIB=${ANDROID_TOOLCHAIN_ROOT}/bin/llvm-ranlib \
STRIP=${ANDROID_TOOLCHAIN_ROOT}/bin/llvm-strip \
PATH=${ANDROID_TOOLCHAIN_ROOT}/bin:$ENV{PATH} \
${env}")

    set(lib_SOURCE_DIR "${SOFTETHER_THIRD_PARTY_DIR}/${project}")
    set(ext_source_dir "${SOFTETHER_THIRD_PARTY_DIR}/build/${ANDROID_ABI}/${project}")
    message(STATUS "INFO: BUILD_IN_SOURCE 1. Copy ${project} sources to make by ExternalProject to ${ext_source_dir}")
    file(COPY "${lib_SOURCE_DIR}" DESTINATION "${ext_source_dir}/..")

    build_external(
            "${project}_${ANDROID_ABI}"
            ${ext_source_dir}
            " SOURCE_DIR ${ext_source_dir} "
            " BUILD_IN_SOURCE 1 "
            " CONFIGURE_COMMAND ${CMAKE_COMMAND} -E env ${android_env} ${configure_cmd}"
            " BUILD_COMMAND ${CMAKE_COMMAND} -E env ${android_env} $(MAKE) -j${NPROC} ${build_args} "
            " INSTALL_COMMAND ${CMAKE_COMMAND} -E env ${android_env} $(MAKE) -j${NPROC} ${install_args} "
            " CMAKE_ARGS ${CMAKE_ARGS} "
    )
endfunction()

function (add_external_cmake project)
    message(STATUS "Adding external cmake project: ${project}-${ANDROID_ABI}")
    set(lib_SOURCE_DIR "${SOFTETHER_THIRD_PARTY_DIR}/${project}")
    set(ext_source_dir "${SOFTETHER_THIRD_PARTY_DIR}/build/${ANDROID_ABI}/${project}")
    message(STATUS "Copying ${project}-${ANDROID_ABI} sources to ${ext_source_dir}")
    file(COPY "${lib_SOURCE_DIR}" DESTINATION "${ext_source_dir}/..")
    add_subdirectory("${ext_source_dir}")
endfunction()


get_autoconf_target(AUTOCONF_TARGET)
set(common_configure_command
        "./configure --host=${AUTOCONF_TARGET}  --prefix=${A_PREFIX_PATH}"
)

find_package(PkgConfig REQUIRED)
find_package(OpenSSL)
if (NOT OPENSSL_FOUND)
    get_openssl_target(OPENSSL_TARGET)
    set(openssl_configure_command
            "./Configure ${OPENSSL_TARGET} --prefix=${A_PREFIX_PATH} \
            -D__ANDROID_API__=${ANDROID_NATIVE_API_LEVEL}\
            -fPIC no-ui no-ui-console no-engine no-filenames " )
    build_autoconf_external_project(openssl "" "${openssl_configure_command}" "" " install_dev install_runtime_libs " )
endif ()


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

pkg_search_module(SODIUM libsodium)
IF(NOT SODIUM_FOUND)
    if(ANDROID_ABI STREQUAL "arm64-v8a")
        build_autoconf_external_project(libsodium  CFLAGS=-march=armv8-a+crypto+aes
                " ${common_configure_command} " "" " install ")
    else ()
        build_autoconf_external_project(libsodium "" "${common_configure_command}" "" " install ")
    endif()
endif ()

find_package(Iconv)
IF(NOT Iconv_FOUND)
    build_autoconf_external_project(libiconv "" " ${common_configure_command} " "" " install ")
    find_package(Iconv REQUIRED)
ENDIF()


find_library(lib_Mayaqua mayaqua)
find_library(lib_Cedar cedar)
find_library(lib_Vpnclient vpnclient)


if(NOT lib_Mayaqua OR NOT lib_Cedar OR NOT lib_Hamcore OR NOT lib_Vpnclient)
    set(CMAKE_MODULE_PATH "${SOFTETHER_THIRD_PARTY_DIR}/build/${ANDROID_ABI}/SoftEtherVPN/src/Mayaqua/3rdparty/")
    add_external_cmake(SoftEtherVPN)

endif()
