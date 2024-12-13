function(get_autoconf_target autoconf_target)
    if(ANDROID_ABI STREQUAL "arm64-v8a")
        set(${autoconf_target} "aarch64-linux-android" PARENT_SCOPE)
    elseif(ANDROID_ABI STREQUAL "armeabi-v7a")
        set(${autoconf_target} "armv7a-linux-androideabi" PARENT_SCOPE)
    elseif(ANDROID_ABI STREQUAL "x86")
        set(${autoconf_target} "i686-linux-android" PARENT_SCOPE)
    elseif(ANDROID_ABI STREQUAL "x86_64")
        set(${autoconf_target} "x86_64-linux-android" PARENT_SCOPE)
    else()
        message(FATAL_ERROR "Unsupported ABI: ${ANDROID_ABI}")
    endif()
endfunction()

get_autoconf_target(AUTOCONF_TARGET)

set(android_env "ANDROID_NDK_ROOT=${ANDROID_NDK}"
    "CC=${ANDROID_TOOLCHAIN_ROOT}/bin/${AUTOCONF_TARGET}${ANDROID_NATIVE_API_LEVEL}-clang"
    "AR=${ANDROID_TOOLCHAIN_ROOT}/bin/llvm-ar"
    "AS=${ANDROID_TOOLCHAIN_ROOT}/bin/${AUTOCONF_TARGET}${ANDROID_NATIVE_API_LEVEL}-clang"
    "CXX=${ANDROID_TOOLCHAIN_ROOT}/bin/${AUTOCONF_TARGET}${ANDROID_NATIVE_API_LEVEL}-clang++"
    "LD=${ANDROID_TOOLCHAIN_ROOT}/bin/ld"
    "RANLIB=${ANDROID_TOOLCHAIN_ROOT}/bin/llvm-ranlib"
    "STRIP=${ANDROID_TOOLCHAIN_ROOT}/bin/llvm-strip"
    "PATH=${ANDROID_TOOLCHAIN_ROOT}/bin:$ENV{PATH}")

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


function(build_autoconf_external_project project source_dir env configure_cmd build_args install_args cmake_args )
    set(AUTOCONF_CURRENT_BUILD_DIR "${CMAKE_CURRENT_SOURCE_DIR}/build/${ANDROID_ABI}/${project}")
    set(SUPER_BUILD_DIR "${CMAKE_CURRENT_SOURCE_DIR}/build/${ANDROID_ABI}/${project}" PARENT_SCOPE)
    message(STATUS "INFO: BUILD_IN_SOURCE 1. Copy ${project} sources to make by Superbuild ExternalProject to ${AUTOCONF_CURRENT_BUILD_DIR}")
    file(COPY "${source_dir}" DESTINATION "${AUTOCONF_CURRENT_BUILD_DIR}/..")
    build_external(
            "${project}_${ANDROID_ABI}"
            ${AUTOCONF_CURRENT_BUILD_DIR}
            " SOURCE_DIR ${AUTOCONF_CURRENT_BUILD_DIR} "
            " BUILD_IN_SOURCE 1 "
            " CONFIGURE_COMMAND ${CMAKE_COMMAND} -E env ${android_env} ${configure_cmd}"
            " BUILD_COMMAND ${CMAKE_COMMAND} -E env ${android_env} $(MAKE) -j${NPROC} ${build_args} "
            " INSTALL_COMMAND ${CMAKE_COMMAND} -E env ${android_env} $(MAKE) -j${NPROC} ${install_args} "
            " CMAKE_ARGS ${CMAKE_ARGS} "
    )
endfunction()