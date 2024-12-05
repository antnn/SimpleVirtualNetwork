cmake_minimum_required(VERSION 3.30)
# This script builds SoftEtherVPN for Android with OpenSSL and libsodium dependencies.
# It sets up the environment, downloads and patches the required libraries, and compiles them
# for multiple Android ABIs.

set(BUILD "$ENV{BUILD_TYPE}" CACHE STRING "Build type")
set(MIN_SDK_VERSION "$ENV{MIN_SDK_VERSION}" CACHE STRING "Minimum Android SDK version")
set(SOFTETHERVPN_VERSION "$ENV{SOFTETHERVPN_VERSION}" CACHE STRING "SoftEtherVPN version")
set(OPENSSL_VERSION "$ENV{OPENSSL_VERSION}" CACHE STRING "OpenSSL version")
set(SODIUM_VERSION "$ENV{SODIUM_VERSION}" CACHE STRING "libsodium version")

set(NDK "$ENV{ANDROID_NDK_ROOT}" CACHE PATH "Android NDK path")

# android_app_name/nativevpn/src/main/jniLibs/
set(JNI_LIBS_DIR "${CMAKE_SOURCE_DIR}/../../jniLibs")
set(EXTRA_ARGS "-DMY_JNI_LIBS_DIR=${JNI_LIBS_DIR}")



function(clone_if_not_exists repo_url branch target_dir)
    if(NOT EXISTS ${target_dir})
        execute_process(
                COMMAND git clone ${repo_url} --depth=1 -b ${branch} ${target_dir}
                RESULT_VARIABLE clone_result
        )
        if(NOT clone_result EQUAL "0")
            message(FATAL_ERROR "Failed to clone ${repo_url}")
        endif()
    endif()
endfunction()


set(SOFTETHER_THIRD_PARTY_DIR "${CMAKE_SOURCE_DIR}/softether_third_party")
file(MAKE_DIRECTORY ${SOFTETHER_THIRD_PARTY_DIR})
# Clone dependencies
clone_if_not_exists(
        "https://github.com/openssl/openssl.git"
        "openssl-${OPENSSL_VERSION}"
        "${SOFTETHER_THIRD_PARTY_DIR}/openssl"
)

clone_if_not_exists(
        "https://github.com/jedisct1/libsodium.git"
        "${SODIUM_VERSION}"
        "${SOFTETHER_THIRD_PARTY_DIR}/libsodium"
)

clone_if_not_exists(
        "https://github.com/SoftEtherVPN/SoftEtherVPN.git"
        "${SOFTETHERVPN_VERSION}"
        "${SOFTETHER_THIRD_PARTY_DIR}/SoftEtherVPN"
)

if(EXISTS "${SOFTETHER_THIRD_PARTY_DIR}/SoftEtherVPN")
    execute_process(
            COMMAND git submodule update --init --recursive
            WORKING_DIRECTORY "${SOFTETHER_THIRD_PARTY_DIR}/SoftEtherVPN"
    )
endif()

function(log_error error)
    message(FATAL_ERROR "Function Build_external command output:\n\
    ${error}")
endfunction()


function(build_hamcorebuilder_on_host OUTPUT_DIR)
    set(DIR "${CMAKE_SOURCE_DIR}/softether_third_party/SoftEtherVPN")

    # Build libhamcore on host
    file(MAKE_DIRECTORY "${OUTPUT_DIR}/libhamcore")
    execute_process(
            COMMAND ${CMAKE_COMMAND} -DCMAKE_BUILD_TYPE=${BUILD} "${DIR}/src/libhamcore"
            WORKING_DIRECTORY "${OUTPUT_DIR}/libhamcore"
    )
    execute_process(
            COMMAND ${CMAKE_COMMAND} --build .
            WORKING_DIRECTORY "${OUTPUT_DIR}/libhamcore"
    )

    # Build hamcorebuilder
    file(MAKE_DIRECTORY "${OUTPUT_DIR}/hb")
    string(REPLACE ";" " " COMP_FLAGS "-I${DIR}/src/libhamcore/include/ -I${DIR}/3rdparty/tinydir")
    string(REPLACE ";" " " LINK_FLAGS "-L${OUTPUT_DIR}/libhamcore -lz")
    execute_process(
            COMMAND ${CMAKE_COMMAND}
            -DCMAKE_BUILD_TYPE=${BUILD}
            -DCMAKE_C_FLAGS=${COMP_FLAGS}
            -DCMAKE_EXE_LINKER_FLAGS=${LINK_FLAGS}
            -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON
            -S "${DIR}/src/hamcorebuilder"
            -B "${OUTPUT_DIR}/hb"
    )
    execute_process(
            COMMAND ${CMAKE_COMMAND} --build .
            WORKING_DIRECTORY "${OUTPUT_DIR}/hb"
    )

    # Run hamcorebuilder to produce hamcore.se2
    execute_process(
            COMMAND "${OUTPUT_DIR}/hb/hamcorebuilder" "hamcore.se2" "${DIR}/src/bin/hamcore"
            WORKING_DIRECTORY "${OUTPUT_DIR}"
    )
endfunction()
build_hamcorebuilder_on_host("${CMAKE_SOURCE_DIR}/softether_third_party/build")



function(patch_softether DIR)
endfunction()
patch_softether(${CMAKE_SOURCE_DIR}/softether_third_party/SoftEtherVPN)



function(build_deps)
    message(STATUS "Building dependencies for SoftEtherVPN")
    set(ABIs "arm64-v8a" "armeabi-v7a" "x86" "x86_64")
    foreach (ANDROID_ABI ${ABIs})
        message("Configuring for ABI: ${ANDROID_ABI}")
        include(${CMAKE_SOURCE_DIR}/common.cmake)
        #set(A_PREFIX_PATH "${CMAKE_SOURCE_DIR}/softether_third_party/root/${ANDROID_ABI}" CACHE INTERNAL "" )

        set(BUILD_DIR "build/${ANDROID_ABI}")
        file(MAKE_DIRECTORY "${BUILD_DIR}")

        execute_process(
                COMMAND ${CMAKE_COMMAND}
                -DCMAKE_BUILD_TYPE=${BUILD}
                -DCMAKE_TOOLCHAIN_FILE=${NDK}/build/cmake/android.toolchain.cmake
                -DANDROID_ABI=${ANDROID_ABI}
                -DANDROID_PLATFORM=android-${MIN_SDK_VERSION}
                ${EXTRA_ARGS}
                -B ${BUILD_DIR}
                WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        )
        #WORKING_DIRECTORY ${BUILD_DIR}/../../

        message("Building for ABI: ${ANDROID_ABI}")
        execute_process(
                COMMAND ${CMAKE_COMMAND} --build .
                WORKING_DIRECTORY ${BUILD_DIR}
        )

        message(STATUS "Libraries are installed at: ${A_PREFIX_PATH}")

    endforeach ()
endfunction()

#build_deps()
