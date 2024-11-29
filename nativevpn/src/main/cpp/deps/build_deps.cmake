cmake_minimum_required(VERSION 3.30)
# This script builds SoftEtherVPN for Android with OpenSSL and libsodium dependencies.
# It sets up the environment, downloads and patches the required libraries, and compiles them
# for multiple Android ABIs.

set(BUILD "Release" CACHE STRING "Build type")
set(MIN_SDK_VERSION 24 CACHE STRING "Minimum Android SDK version")
set(NDK_VERSION "27.0.12077973" CACHE STRING "Android NDK version")

# Library versions
set(SOFTETHERVPN_VERSION "5.02.5187" CACHE STRING "SoftEtherVPN version")
set(OPENSSL_VERSION "3.4.0" CACHE STRING "OpenSSL version")
set(SODIUM_VERSION "1.0.20-RELEASE" CACHE STRING "libsodium version")

set(NDK "$ENV{ANDROID_NDK_ROOT}/"$ENV{NDK_VERSION}" CACHE PATH "Android NDK path")
# android_app_name/nativevpn/src/main/jniLibs/
set(JNI_LIBS_DIR "${CMAKE_SOURCE_DIR}/../../jniLibs")
set(EXTRA_ARGS "-DMY_JNI_LIBS_DIR=${JNI_LIBS_DIR}")

#if(NOT EXISTS "${ANDROID_MODULE_DIR}")
#    message(FATAL_ERROR "Android module directory not found: ${ANDROID_MODULE_DIR}")
#endif()


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
    # hamcore.se2 is arch-independent file
    execute_process( COMMAND
            bash -c "find . -type f -name \"*\" -exec sed -i 's/hamcore\\.se2\\([^.\\]\\|\\$\\)/hamcore.se2.so\\1/g' {} +"
            WORKING_DIRECTORY "${SOFTETHER_THIRD_PARTY_DIR}/SoftEtherVPN")
    file(MAKE_DIRECTORY ${OUTPUT_DIR})

    file(COPY SoftEtherVPN DESTINATION ${OUTPUT_DIR})

    file(READ "${OUTPUTDIR}/SoftEtherVPN/src/CMakeLists.txt" CMAKELIST_CONTENT)

    string(REGEX REPLACE "(add_subdirectory\\(Mayaqua\\))" "#\\1" CMAKELIST_CONTENT "${CMAKELIST_CONTENT}")
    string(REGEX REPLACE "(add_subdirectory\\(Cedar\\))" "#\\1" CMAKELIST_CONTENT "${CMAKELIST_CONTENT}")
    string(REGEX REPLACE "(add_subdirectory\\(vpnserver\\))" "#\\1" CMAKELIST_CONTENT "${CMAKELIST_CONTENT}")
    string(REGEX REPLACE "(add_subdirectory\\(vpnclient\\))" "#\\1" CMAKELIST_CONTENT "${CMAKELIST_CONTENT}")
    string(REGEX REPLACE "(add_subdirectory\\(vpnbridge\\))" "#\\1" CMAKELIST_CONTENT "${CMAKELIST_CONTENT}")
    string(REGEX REPLACE "(add_subdirectory\\(vpncmd\\))" "#\\1" CMAKELIST_CONTENT "${CMAKELIST_CONTENT}")
    string(REGEX REPLACE "(add_subdirectory\\(vpntest\\))" "#\\1" CMAKELIST_CONTENT "${CMAKELIST_CONTENT}")

    string(REGEX REPLACE "(add_custom_target\\(hamcore-archive-build[\\s\\S]*?\\))" "#\\1" CMAKELIST_CONTENT "${CMAKE_CONTENT}")

    file(WRITE "${OUTPUTDIR}/SoftEtherVPN/src/CMakeLists.txt" "${CMAKELIST_CONTENT}")

    execute_process(
            COMMAND ./configure
            WORKING_DIRECTORY ${OUTPUT_DIR}/SoftEtherVPN
    )
    execute_process(
            COMMAND make -C build -j${NPROC}
            WORKING_DIRECTORY ${OUTPUTDIR}/SoftEtherVPN
    )

    # Copy the built hamcorebuilder to PATH
    file(COPY ${OUTPUT_DIR}/SoftEtherVPN/build/src/hamcorebuilder/hamcorebuilder
            DESTINATION ${OUTPUT_DIR})

endfunction()
build_hamcorebuilder_on_host()


function(patch_softether DIR)
    file(READ "${DIR}/src/CMakeLists.txt" CMAKELIST_CONTENT)
    string(REGEX REPLACE "(add_subdirectory\\(vpnserver\\))" "#\\1" CMAKELIST_CONTENT "${CMAKELIST_CONTENT}")
    string(REGEX REPLACE "(add_subdirectory\\(vpnbridge\\))" "#\\1" CMAKELIST_CONTENT "${CMAKELIST_CONTENT}")
    string(REGEX REPLACE "(add_subdirectory\\(vpncmd\\))" "#\\1" CMAKELIST_CONTENT "${CMAKELIST_CONTENT}")
    string(REGEX REPLACE "(add_subdirectory\\(vpntest\\))" "#\\1" CMAKELIST_CONTENT "${CMAKELIST_CONTENT}")
    string(REGEX REPLACE "(add_subdirectory\\(libhamcore\\))" "#\\1" CMAKELIST_CONTENT "${CMAKELIST_CONTENT}")
    string(REGEX REPLACE "(add_subdirectory\\(hamcorebuilder\\))" "#\\1" CMAKELIST_CONTENT "${CMAKELIST_CONTENT}")
    string(REGEX REPLACE "(add_custom_target\\(hamcore-archive-build[^)]*\\))" "#\\1" CMAKELIST_CONTENT "${CMAKELIST_CONTENT}")

    file(WRITE "${DIR}/src/CMakeLists.txt" "${CMAKELIST_CONTENT}")
endfunction()

patch_softether(${CMAKE_SOURCE_DIR}/softether_third_party/SoftEtherVPN)

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

