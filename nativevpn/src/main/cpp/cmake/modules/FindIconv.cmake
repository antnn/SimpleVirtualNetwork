include(ExternalProject)
set(ICONV_VERSION        $ENV{ICONV_VERSION})
set(ICONV_SHA            $ENV{ICONV_SHA})

include(${CMAKE_CURRENT_LIST_DIR}/CommonAndroidSetup.cmake)
get_autoconf_target(AUTOCONF_TARGET)

# Configure flags for Android build
set(configure_flags
    --host=${AUTOCONF_TARGET}
    --enable-shared)


set(CONFIGURE_COMMAND
    cd "<SOURCE_DIR>" &&
    ${CMAKE_COMMAND} -E env ${android_env} "<SOURCE_DIR>/configure" ${configure_flags}
                             "--prefix=<INSTALL_DIR>")
set(BUILD_COMMAND
    ${CMAKE_COMMAND} -E env ${android_env} $(MAKE) -sC "<SOURCE_DIR>" install)
set(INSTALL_COMMAND
    ${CMAKE_COMMAND} -E env ${android_env} $(MAKE) -sC "<SOURCE_DIR>" install)

if(DEFINED ICONV_SOURCE_DIR AND EXISTS ${ICONV_SOURCE_DIR})
    ExternalProject_Add(libiconv
        SOURCE_DIR ${ICONV_SOURCE_DIR}
        PREFIX ${CMAKE_CURRENT_BINARY_DIR}/libiconv
        CONFIGURE_COMMAND ${CONFIGURE_COMMAND}
        BUILD_COMMAND ${BUILD_COMMAND}
        INSTALL_COMMAND ${INSTALL_COMMAND}
        DOWNLOAD_COMMAND ""
    )
else()
    ExternalProject_Add(libiconv
        URL https://ftp.gnu.org/pub/gnu/libiconv/libiconv-${ICONV_VERSION}.tar.gz
        URL_HASH SHA256=${ICONV_SHA}
        PREFIX ${CMAKE_CURRENT_BINARY_DIR}/libiconv
        CONFIGURE_COMMAND ${CONFIGURE_COMMAND}
        BUILD_COMMAND ${BUILD_COMMAND}
        INSTALL_COMMAND ${INSTALL_COMMAND}
        DOWNLOAD_EXTRACT_TIMESTAMP 0
    )
endif()
ExternalProject_Get_Property(libiconv INSTALL_DIR)
list(APPEND CMAKE_PREFIX_PATH ${INSTALL_DIR})

# Set the variables
set(ICONV_INCLUDE_DIR ${INSTALL_DIR}/include)
set(ICONV_LIBRARY ${INSTALL_DIR}/lib/libiconv.so)
set(ICONV_FOUND TRUE)

# Create an imported target for libiconv
add_library(Iconv SHARED IMPORTED GLOBAL)
set_target_properties(Iconv PROPERTIES
    IMPORTED_LOCATION ${INSTALL_DIR}/lib/libiconv.so
    INTERFACE_INCLUDE_DIRECTORIES ${INSTALL_DIR}/include
)

# Export variables for find_package compatibility
set(Iconv_INCLUDE_DIRS ${ICONV_INCLUDE_DIR})
set(Iconv_LIBRARIES ${ICONV_LIBRARY})
set(Iconv_FOUND ${ICONV_FOUND})
include_directories(${INSTALL_DIR}/include)