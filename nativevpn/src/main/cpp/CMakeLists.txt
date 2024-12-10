cmake_minimum_required(VERSION 3.22.1)

project("nativevpn")

set(OPENSSL_VERSION      "$ENV{OPENSSL_VERSION}"      CACHE STRING "OpenSSL version")
set(OPENSSL_URL          "$ENV{OPENSSL_URL}"          CACHE STRING "OpenSSL version")
set(OPENSSL_SHA          "$ENV{OPENSSL_SHA}"          CACHE STRING "openssl sha256sum")
set(SODIUM_VERSION       "$ENV{SODIUM_VERSION}"       CACHE STRING "libsodium version")
set(SODIUM_URL           "$ENV{SODIUM_URL}"           CACHE STRING "libsodium sha256sum")
set(SODIUM_SHA           "$ENV{SODIUM_SHA}"           CACHE STRING "libsodium sha256sum")
set(ICONV_VERSION        "$ENV{ICONV_VERSION}"        CACHE STRING "libiconv version")
set(ICONV_SHA            "$ENV{ICONV_SHA}"            CACHE STRING "libiconv sha256")
set(ICONV_URL            "$ENV{ICONV_URL}"            CACHE STRING "libiconv sha256")
set(SOFTETHERVPN_VERSION "$ENV{SOFTETHERVPN_VERSION}"  CACHE STRING "OpenSSL version")
set(SOFTETHERVPN_URL     "$ENV{SOFTETHERVPN_URL}"          CACHE STRING "OpenSSL version")
set(SOFTETHERVPN_SHA     "$ENV{SOFTETHERVPN_SHA}"     CACHE STRING "openssl sha256sum")

function(download_and_extract URL SHA256 SOURCE_DIR)
    if("${URL}" STREQUAL "")
        message(FATAL_ERROR "URL parameter is empty")
    elseif ("${SHA256}" STREQUAL "")
        message(FATAL_ERROR "SHA256 parameter is empty")
    elseif ("${SOURCE_DIR}" STREQUAL "")
        message(FATAL_ERROR "SOURCE_DIR parameter is empty")
    elseif (EXISTS "${SOURCE_DIR}")
        return()
    endif ()

    get_filename_component(filename "${URL}" NAME)
    set(download_path "${CMAKE_BINARY_DIR}/downloads/${filename}")

    file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/downloads")
    set(do_download TRUE)
    if(EXISTS "${download_path}")
    file(SHA256 "${download_path}" existing_hash)
                if("${existing_hash}" STREQUAL "${SHA256}")
                    set(do_download FALSE)
                endif()
            endif()

            if(do_download)
                message(STATUS "Downloading ${URL}")
                file(DOWNLOAD "${URL}" "${download_path}"
                        SHOW_PROGRESS
                        STATUS download_status
                        EXPECTED_HASH SHA256=${SHA256}
                        TLS_VERIFY ON
                )
                list(GET download_status 0 status_code)
                if(NOT status_code EQUAL 0)
                    file(REMOVE "${download_path}")
                    message(FATAL_ERROR "Failed to download ${URL}")
                endif()
            endif()
            if(NOT EXISTS "${SOURCE_DIR}")
                message(STATUS "Extracting ${download_path} to ${SOURCE_DIR}")
                file(ARCHIVE_EXTRACT
                        INPUT "${download_path}"
                        DESTINATION "${SOURCE_DIR}"
                )
    endif()

    # Find the first directory within SOURCE_DIR
    file(GLOB directories "${SOURCE_DIR}/*")
    set(FIRST_DIR "")

    foreach(dir_path ${directories})
        if(IS_DIRECTORY ${dir_path})
            set(FIRST_DIR ${dir_path})
            break()
        endif()
    endforeach()
    if(NOT FIRST_DIR STREQUAL "")
        file(GLOB files_to_move "${FIRST_DIR}/*")
        foreach(file_path ${files_to_move})
            get_filename_component(file_name ${file_path} NAME)
            file(RENAME ${file_path} "${SOURCE_DIR}/${file_name}")
        endforeach()
        file(REMOVE_RECURSE "${FIRST_DIR}")
    endif()
endfunction()


set(OPENSSL_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/deps/openssl)
download_and_extract("${OPENSSL_URL}" "${OPENSSL_SHA}" "${OPENSSL_SOURCE_DIR}" )

set(SODIUM_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/deps/libsodium)
download_and_extract("${SODIUM_URL}" "${SODIUM_SHA}" "${SODIUM_SOURCE_DIR}" )

set(ICONV_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/deps/iconv)
download_and_extract("${ICONV_URL}" "${ICONV_SHA}" "${ICONV_SOURCE_DIR}" )

set(SOFTETHERVPN_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/deps/softethervpn)
download_and_extract("${SOFTETHERVPN_URL}" "${SOFTETHERVPN_SHA}" "${SOFTETHERVPN_SOURCE_DIR}" )

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake/modules")

find_package(PkgConfig REQUIRED)
find_package(OpenSSL REQUIRED)
find_package(LibSodium REQUIRED)
find_package(Iconv REQUIRED)



add_library(${CMAKE_PROJECT_NAME} SHARED
        nativevpn.c
        androidhelpers.c)
target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE
        android
        log
        OpenSSL::SSL
        OpenSSL::Crypto
        $<IF:$<BOOL:SODIUM_LINK_LIBRARIES>,${SODIUM_LINK_LIBRARIES},${SODIUM_LIBRARIES}>
        #${lib_Mayaqua}
        #${lib_Cedar}
        #${lib_Hamcore}
        #${lib_Vpnclient}
)
