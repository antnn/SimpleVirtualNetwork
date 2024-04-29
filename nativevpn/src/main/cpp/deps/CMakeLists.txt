cmake_minimum_required(VERSION 3.22.1)

if(NOT ANDROID_ABI)
    return()
endif ()

project("deps_project")
cmake_host_system_information(RESULT nproc
        QUERY NUMBER_OF_PHYSICAL_CORES)
set(NPROC ${nproc} CACHE INTERNAL "")

#Keep in sync with ../CMakeLists.txt and ../build_deps.cmake
set(A_PREFIX_PATH "${CMAKE_SOURCE_DIR}/external/root/${ANDROID_ABI}" CACHE INTERNAL "" )
set(EXTERNAL_DIR "${CMAKE_SOURCE_DIR}/external" CACHE INTERNAL "" )


#fix find_package
list(APPEND CMAKE_PREFIX_PATH "${A_PREFIX_PATH}" )
set(CMAKE_FIND_ROOT_PATH "${CMAKE_FIND_ROOT_PATH}" "${A_PREFIX_PATH}" )
#
add_custom_target("deps_target")


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
        add_dependencies(deps_target ${target})
    ")

    file(WRITE "${trigger_build_dir}/CMakeLists.txt" "${CMAKE_LIST_CONTENT}")
    add_subdirectory("${trigger_build_dir}")

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

    set(lib_SOURCE_DIR "${EXTERNAL_DIR}/${project}")
    set(ext_source_dir "${EXTERNAL_DIR}/build/${ANDROID_ABI}/${project}")
    message(STATUS "INFO: BUILD_IN_SOURCE 1. Copy ${project} sources to make by ExternalProject\
${ext_source_dir}")
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

function (build_external_cmake project env)
    message(STATUS "Building external cmake project: ${project}")
    set(lib_SOURCE_DIR "${EXTERNAL_DIR}/${project}")
    set(ext_source_dir "${EXTERNAL_DIR}/build/${ANDROID_ABI}/${project}")
    message(STATUS "INFO: BUILD_IN_SOURCE 1. Copy ${project} sources to make by ExternalProject \
${ext_source_dir}")
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


pkg_search_module(SODIUM libsodium)
IF(NOT SODIUM_FOUND)
    if(ANDROID_ABI STREQUAL "arm64-v8a")
        build_autoconf_external_project(libsodium  CFLAGS=-march=armv8-a+crypto+aes
                " ${common_configure_command} " "" " install ")
    else ()
        build_autoconf_external_project(libsodium "" "${common_configure_command}" "" " install ")
    endif()
endif ()



function(build_hamcorebuilder_on_host)
    # workdir is output dir
    message(STATUS "Building hamcorebuilder on host system and to add to PATH during vpnclient build")
    execute_process(COMMAND /bin/bash "${DEPS_DIR}/hamcorebuilder.sh"
            WORKING_DIRECTORY ${DEPS_DIR} )
endfunction()


find_library(lib_Mayaqua mayaqua)
find_library(lib_Cedar cedar)
find_library(lib_Hamcore hamcore.se2)
find_library(lib_Vpnclient androidvpnclient)

if(NOT lib_Mayaqua OR NOT lib_Cedar OR NOT lib_Hamcore OR NOT lib_Vpnclient)
    build_hamcorebuilder_on_host()
    message(STATUS "Replacing string 'hamcore.se' to 'hamcore.se.so'")
    execute_process(  COMMAND  bash -c "find . -type f -name \"*\" -exec sed -i 's/hamcore\\.se2\\([^.\\]\\|\\$\\)/hamcore.se2.so\\1/g' {} +"
            WORKING_DIRECTORY ${EXTERNAL_DIR}/SoftEtherVPN)
    set(softether_cmake_args ${CMAKE_ARGS} )
    list(APPEND softether_cmake_args "-DCMAKE_PREFIX_PATH=${A_PREFIX_PATH}"
            "-DCMAKE_FIND_ROOT_PATH=${A_PREFIX_PATH}" )
    #list(APPEND softether_cmake_args "-DCMAKE_FIND_ROOT_PATH=${A_PREFIX_PATH}" )

    #path to hamcorebuilder
    #name of a project is a child source dir
    build_external_cmake(SoftEtherVPN
            "PATH=${DEPS_DIR}:$ENV{PATH}"
            ${softether_cmake_args} )

    #file(RENAME "${EXTERNAL_DIR}/build/${ANDROID_ABI}/SoftEtherVPN/vpnclient"
    #        "${EXTERNAL_DIR}/build/${ANDROID_ABI}/SoftEtherVPN/libsoftethervpnclient.so"
    #        )
    file(GLOB SO_FILES "${EXTERNAL_DIR}/build/${ANDROID_ABI}/SoftEtherVPN/*.so")
    file(COPY ${SO_FILES} DESTINATION ${A_PREFIX_PATH}/lib)
    file(COPY ${SO_FILES} DESTINATION ${MY_ANDROID_MODULE_DIR}/src/main/jniLibs/${ANDROID_ABI})

    find_library(lib_Mayaqua libmayaqua)
    #find_library(lib_Hamcore hamcore.se2)
    find_library(lib_Cedar libcedar)
    find_library(lib_vpnclient androidvpnclient)
endif()

#Keep it so Android Studio copies libraries automatically to APK's jniLibs
add_library(${CMAKE_PROJECT_NAME} SHARED
        nativevpn.c)
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
        #${lib_Hamcore}
        ${lib_vpnclient}
)
