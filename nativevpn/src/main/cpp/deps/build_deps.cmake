cmake_minimum_required(VERSION 3.30)
# This script builds SoftEtherVPN for Android with OpenSSL and libsodium dependencies.
# It sets up the environment, downloads and patches the required libraries, and compiles them
# for multiple Android ABIs.
set(SOFTETHERVPN_VERSION "$ENV{SOFTETHERVPN_VERSION}" CACHE STRING "SoftEtherVPN version")
set(BUILD                "$ENV{BUILD_TYPE}"           CACHE STRING "Build type")
set(MIN_SDK_VERSION      "$ENV{MIN_SDK_VERSION}"      CACHE STRING "Minimum Android SDK version")
set(OPENSSL_VERSION      "$ENV{OPENSSL_VERSION}"      CACHE STRING "OpenSSL version")
set(SODIUM_VERSION       "$ENV{SODIUM_VERSION}"       CACHE STRING "libsodium version")
set(SODIUM_VERSION       "$ENV{SODIUM_VERSION}"       CACHE STRING "libsodium version")
set(ICONV_VERSION        "$ENV{ICONV_VERSION}"        CACHE STRING "libiconv version")
set(NDK                  "$ENV{ANDROID_NDK_ROOT}"     CACHE PATH   "Android NDK path")

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

function(download_and_extract_if_not_exists url filename target_dir)
    if(NOT EXISTS ${target_dir})
        set(download_path "${CMAKE_CURRENT_SOURCE_DIR}/${CMAKE_CURRENT_BINARY_DIR}/${filename}")

        # Download the file if it doesn't exist
        if(NOT EXISTS ${download_path})
            message(STATUS "Downloading ${url}")
            file(DOWNLOAD ${url} ${download_path}
                    SHOW_PROGRESS
                    STATUS download_status
                    TLS_VERIFY ON)
            list(GET download_status 0 status_code)
            if(NOT status_code EQUAL 0)
                message(FATAL_ERROR "Failed to download ${url}")
            endif()
        endif()

        message(STATUS "Extracting ${filename}")
        execute_process(
                COMMAND ${CMAKE_COMMAND} -E tar xzf ${download_path}
                WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/${CMAKE_CURRENT_BINARY_DIR}"
                RESULT_VARIABLE extract_result
        )
        if(NOT extract_result EQUAL 0)
            message(FATAL_ERROR "Failed to extract ${filename}")
        endif()

        file(RENAME
                "${CMAKE_CURRENT_SOURCE_DIR}/${CMAKE_CURRENT_BINARY_DIR}/libiconv-1.17"
                ${target_dir}
        )
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

download_and_extract_if_not_exists(
        "https://ftp.gnu.org/pub/gnu/libiconv/libiconv-${ICONV_VERSION}.tar.gz"
        "libiconv-${ICONV_VERSION}.tar.gz"
        "${SOFTETHER_THIRD_PARTY_DIR}/libiconv"
)


#NO-ARCH
function(build_hamcorebuilder_on_host OUTPUT_DIR)
    set(DIR "${CMAKE_SOURCE_DIR}/softether_third_party/SoftEtherVPN")

    # Build libhamcore on host
    file(MAKE_DIRECTORY "${OUTPUT_DIR}/libhamcore")
    execute_process(
            COMMAND ${CMAKE_COMMAND} -DCMAKE_BUILD_TYPE=${BUILD} "${DIR}/src/libhamcore"
            WORKING_DIRECTORY "${OUTPUT_DIR}/libhamcore"
            RESULT_VARIABLE result
            ERROR_VARIABLE error
    )
    if(NOT result EQUAL "0")
        log_error("${error}" "${CMAKE_COMMAND}" -DCMAKE_BUILD_TYPE=${BUILD} "${OUTPUT_DIR}/libhamcore")
    endif()
    execute_process(
            COMMAND ${CMAKE_COMMAND} --build .
            WORKING_DIRECTORY "${OUTPUT_DIR}/libhamcore"
            RESULT_VARIABLE result
            ERROR_VARIABLE error
    )
    if(NOT result EQUAL "0")
        log_error("${error}" "${CMAKE_COMMAND}" "--build ."  "${OUTPUT_DIR}/libhamcore")
    endif()

    # Build hamcorebuilder
    file(MAKE_DIRECTORY "${OUTPUT_DIR}/hb")
    string(REPLACE ";" " " MY_COMP_FLAGS "-I${DIR}/src/libhamcore/include/ -I${DIR}/3rdparty/tinydir")
    string(REPLACE ";" " " MY_LINK_FLAGS "-L${OUTPUT_DIR}/libhamcore -lz")
    execute_process(COMMAND ${CMAKE_COMMAND}
            -DCMAKE_BUILD_TYPE=${BUILD}
            -DCMAKE_C_FLAGS=${MY_COMP_FLAGS}
            -DCMAKE_EXE_LINKER_FLAGS=${MY_LINK_FLAGS}
            -S "${DIR}/src/hamcorebuilder"
            -B "${OUTPUT_DIR}/hb"
            RESULT_VARIABLE result
            ERROR_VARIABLE error
    )
    if(NOT result EQUAL "0")
        log_error("${error}" "${CMAKE_COMMAND}" "-DCMAKE_BUILD_TYPE=${BUILD}
            -DCMAKE_C_FLAGS=${MY_COMP_FLAGS}
            -DCMAKE_EXE_LINKER_FLAGS=${MY_LINK_FLAGS}
            -S \"${DIR}/src/hamcorebuilder\"
            -B \"${OUTPUT_DIR}/hb\"" "${DIR}/src/hamcorebuilder" )
    endif()
    execute_process(
            COMMAND ${CMAKE_COMMAND} --build .
            WORKING_DIRECTORY "${OUTPUT_DIR}/hb"
            RESULT_VARIABLE result
            ERROR_VARIABLE error
    )
    if(NOT result EQUAL "0")
        log_error("${error}" "${CMAKE_COMMAND}" "--build ." "${OUTPUT_DIR}/hb")
    endif()

    # Run hamcorebuilder to produce hamcore.se2 (no-arch)
    execute_process(
            COMMAND "${OUTPUT_DIR}/hb/hamcorebuilder" "hamcore.se2" "${DIR}/src/bin/hamcore"
            WORKING_DIRECTORY "${OUTPUT_DIR}"
            RESULT_VARIABLE result
    )
    if (NOT result EQUAL "0")
        message(FATAL_ERROR "Failed to compile hamcore.se2 \n CMD: \"${OUTPUT_DIR}/hb/hamcorebuilder\" \"hamcore.se2\" \"${DIR}/src/bin/hamcore\"")
    endif ()
endfunction()

include(${CMAKE_SOURCE_DIR}/common.cmake)

set(HAMCORE_SE2 "${CMAKE_SOURCE_DIR}/softether_third_party/build")
build_hamcorebuilder_on_host(${HAMCORE_SE2})

function(patch_softether DIR)
execute_process(
        COMMAND git apply  ${CMAKE_SOURCE_DIR}/softethervpn2.patch
        WORKING_DIRECTORY ${DIR}
)
endfunction()
patch_softether(${CMAKE_SOURCE_DIR}/softether_third_party/SoftEtherVPN)


function(build_deps)
    message(STATUS "Building dependencies for SoftEtherVPN")
    set(ABIs "arm64-v8a" "armeabi-v7a" "x86" "x86_64")
    foreach (ANDROID_ABI ${ABIs})
        message("Configuring for ABI: ${ANDROID_ABI}")
        include(${CMAKE_SOURCE_DIR}/common.cmake)

        set(BUILD_DIR "build/${ANDROID_ABI}")
        file(MAKE_DIRECTORY "${BUILD_DIR}")
        # Suppress NCurses not found: -DCURSES_LIBRARY="${A_PREFIX_PATH}" -DCURSES_INCLUDE_PATH="${A_PREFIX_PATH}"
        execute_process(
                COMMAND ${CMAKE_COMMAND} -E env HAMCORE_SE2=${HAMCORE_SE2} ${CMAKE_COMMAND}
                -DCMAKE_BUILD_TYPE=${BUILD}
                -DCMAKE_TOOLCHAIN_FILE=${NDK}/build/cmake/android.toolchain.cmake
                -DANDROID_ABI=${ANDROID_ABI}
                -DANDROID_PLATFORM=android-${MIN_SDK_VERSION}
                -DCMAKE_INSTALL_PREFIX=${A_PREFIX_PATH}
                -DCMAKE_PREFIX_PATH=${A_PREFIX_PATH} -DCMAKE_FIND_ROOT_PATH=${A_PREFIX_PATH}
                -DCURSES_LIBRARY=${A_PREFIX_PATH} -DCURSES_INCLUDE_PATH=${A_PREFIX_PATH}
                -DLIB_READLINE=${A_PREFIX_PATH}
                -DCMAKE_C_FLAGS=-I${CMAKE_CURRENT_SOURCE_DIR}/../include
                ${EXTRA_ARGS}
                -B ${BUILD_DIR}
                WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        )

        message("Building for ABI: ${ANDROID_ABI}")
        execute_process(
                COMMAND ${CMAKE_COMMAND} --build . -j${NPROC}
                WORKING_DIRECTORY ${BUILD_DIR}
        )

        message(STATUS "Libraries are installed at: ${A_PREFIX_PATH}")

    endforeach ()
endfunction()

build_deps()
