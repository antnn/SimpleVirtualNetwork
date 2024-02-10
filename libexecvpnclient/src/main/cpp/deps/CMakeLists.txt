cmake_minimum_required(VERSION 3.22.1)

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
            )
    if(NOT result EQUAL "0")
        message(FATAL_ERROR "Build_external command failed with result: ${result}}")
    endif()

    execute_process(COMMAND ${CMAKE_COMMAND} --build .
            WORKING_DIRECTORY ${trigger_build_dir}
            RESULT_VARIABLE result
            )
    if(NOT result EQUAL "0")
        message(FATAL_ERROR "Build_external command failed with result: ${result}}")
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

    set(lib_SOURCE_DIR "${DEPS_DIR}/${project}")
    set(ext_source_dir "${DEPS_DIR}/build/${ANDROID_ABI}/${project}")
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
    set(lib_SOURCE_DIR "${DEPS_DIR}/${project}")
    set(ext_source_dir "${DEPS_DIR}/build/${ANDROID_ABI}/${project}")
    message(STATUS "INFO: BUILD_IN_SOURCE 1. Copy ${project} sources to make by ExternalProject \
${ext_source_dir}")
    file(COPY "${lib_SOURCE_DIR}" DESTINATION "${ext_source_dir}/..")
    if(env)
        set(env env ${env} )
    endif ()
    execute_process(COMMAND ${env} ${CMAKE_COMMAND} ${ARGN} .
            WORKING_DIRECTORY ${ext_source_dir}
            RESULT_VARIABLE result
            )
    if(NOT result EQUAL "0")
        message(FATAL_ERROR "Build_external_cmake command failed with result: ${result}}")
    endif()
    execute_process(COMMAND ${env} ${CMAKE_COMMAND} --build . -j${NPROC}
            WORKING_DIRECTORY ${ext_source_dir}
            RESULT_VARIABLE result
            )
    if(NOT result EQUAL "0")
        message(FATAL_ERROR "Build_external_cmake command failed with result: ${result}}")
    endif()
endfunction()