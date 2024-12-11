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

function(clone_if_not_exists repo_url branch target_dir)
    if(NOT EXISTS ${target_dir})
        execute_process(
                COMMAND git clone --recurse-submodules ${repo_url} --depth=1 -b ${branch} ${target_dir}
                RESULT_VARIABLE clone_result
        )
        if(NOT clone_result EQUAL "0")
            message(FATAL_ERROR "Failed to clone ${repo_url}")
        endif()
    endif()
endfunction()