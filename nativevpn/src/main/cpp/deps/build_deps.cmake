cmake_minimum_required(VERSION 3.4.1)

set(BUILD "Release")
set(MIN_SDK_VERSION 24)
set(NDK_VERSION "26.2.11394342")
set(NDK "$ENV{HOME}/Android/Sdk/ndk/${NDK_VERSION}")

set(APP_NAME "VpnOverHttps")
set(NATIVE_MODULE_NAME "nativevpn")
set(ANDROID_MODULE_DIR "$ENV{HOME}/AndroidStudioProjects/${APP_NAME}/${NATIVE_MODULE_NAME}")
set(EXTRA_ARGS "-DMY_ANDROID_MODULE_DIR=${ANDROID_MODULE_DIR}")

set(SOFTETHERVPN_VERSION 5.02.5181)
set(OPENSSL_VERSION 3.2.1)
set(SODIUM_VERSION 1.0.19-RELEASE)


if (NOT EXISTS "${ANDROID_MODULE_DIR}")
    message(FATAL_ERROR "Could not find dir: ${ANDROID_MODULE_DIR}")
endif ()



# Create external directory
file(MAKE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/external)
# Clone OpenSSL
if(NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/external/openssl)
    execute_process(
            COMMAND git clone https://github.com/openssl/openssl.git --depth=1 -b openssl-${OPENSSL_VERSION} ${CMAKE_CURRENT_SOURCE_DIR}/external/openssl
    )
endif()
# Clone libsodium
if(NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/external/libsodium)
    execute_process(
            COMMAND git clone --depth=1 https://github.com/jedisct1/libsodium.git -b ${SODIUM_VERSION} ${CMAKE_CURRENT_SOURCE_DIR}/external/libsodium
    )
endif()
# Clone SoftEtherVPN
if(NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/external/SoftEtherVPN)
    execute_process(
            COMMAND git clone --depth=1 https://github.com/SoftEtherVPN/SoftEtherVPN.git ${CMAKE_CURRENT_SOURCE_DIR}/external/SoftEtherVPN
    )
    execute_process(
            COMMAND git submodule update --init --recursive
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/external/SoftEtherVPN
    )
endif()



function(log_error error)
    message(FATAL_ERROR "Function Build_external command output:\n\
    ${error}")
endfunction()


function(patch_softether DIR)
    if (UNIX)
        set(sed_script_linux [[
  /add_subdirectory (Mayaqua) /s/^/#/
  /add_subdirectory (Cedar) /s/^/#/
  /add_subdirectory (vpnserver) /s/^/#/
  /add_subdirectory (vpnclient) /s/^/#/
  /add_subdirectory (vpnbridge) /s/^/#/
  /add_subdirectory (vpncmd) /s/^/#/
  /add_subdirectory (vpntest) /s/^/#/
  /add_custom_target (hamcore-archive-build/,/) /s/^/#/
]])
        execute_process(
                COMMAND sed -i ${sed_script_linux} src/CMakeLists.txt
                WORKING_DIRECTORY ${DIR}
        )
    elseif (WIN32)
        set(hamcore_win_cmd [[
  $content = Get-Content ${SOURCE_DIR}/CMakeLists.txt
  $content = $content -replace 'add_subdirectory(Mayaqua)', '#add_subdirectory(Mayaqua)'
  $content = $content -replace 'add_subdirectory(Cedar)', '#add_subdirectory(Cedar)'
  $content = $content -replace 'add_subdirectory(vpnserver)', '#add_subdirectory(vpnserver)'
  $content = $content -replace 'add_subdirectory(vpnclient)', '#add_subdirectory(vpnclient)'
  $content = $content -replace 'add_subdirectory(vpnbridge)', '#add_subdirectory(vpnbridge)'
  $content = $content -replace 'add_subdirectory(vpncmd)', '#add_subdirectory(vpncmd)'
  $content = $content -replace 'add_subdirectory(vpntest)', '#add_subdirectory(vpntest)'
  $content = $content -replace 'add_custom_target(hamcore-archive-build.*?\)', '#$&'
  Set-Content ${SOURCE_DIR}/CMakeLists.txt $content
]])

        execute_process(
                COMMAND powershell -Command ${hamcore_win_cmd}
                WORKING_DIRECTORY ${DIR}
        )
    endif ()
endfunction()


message(STATUS "Building dependencies for SoftEtherVPN")
set(abis "arm64-v8a" "armeabi-v7a" "x86" "x86_64")
foreach (ANDROID_ABI ${abis})
    message("Building for ABI: ${ANDROID_ABI}")
    #Keep in sync with ../CMakeLists.txt and ../build_deps.cmake
    set(A_PREFIX_PATH "${CMAKE_SOURCE_DIR}/external/root/${ANDROID_ABI}" CACHE INTERNAL "" )

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
            WORKING_DIRECTORY ${BUILD_DIR}/../../
            RESULT_VARIABLE result
    )
    if (NOT result EQUAL "0")
        log_error("${error}")
    endif ()

    execute_process(
            COMMAND ${CMAKE_COMMAND} --build .
            WORKING_DIRECTORY ${BUILD_DIR}
            RESULT_VARIABLE result
    )
    if (NOT result EQUAL "0")
        log_error("${error}")
    endif ()

    message(STATUS "Libraries are installed at:
${A_PREFIX_PATH}")

    patch_softether(${CMAKE_SOURCE_DIR}/external/SoftEtherVPN)

endforeach ()

