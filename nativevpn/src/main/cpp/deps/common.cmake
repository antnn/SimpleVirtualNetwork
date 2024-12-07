set(SOFTETHER_THIRD_PARTY_DIR "${CMAKE_SOURCE_DIR}/softether_third_party" CACHE INTERNAL "")
set(SOFTETHER_THIRD_PARTY_ROOT "${SOFTETHER_THIRD_PARTY_DIR}/root")
#fix findlibrary

set(A_PREFIX_PATH "${SOFTETHER_THIRD_PARTY_ROOT}/${ANDROID_ABI}" CACHE INTERNAL "")
list(APPEND CMAKE_PREFIX_PATH "${A_PREFIX_PATH}" )
list(APPEND CMAKE_FIND_ROOT_PATH "${A_PREFIX_PATH}" )

cmake_host_system_information(RESULT nproc
        QUERY NUMBER_OF_PHYSICAL_CORES)
set(NPROC ${nproc} CACHE INTERNAL "")

function(log_error error command args dir )
    string(REPLACE ";" "\\ " command_print "${command}")
    string(REPLACE ";" "\ " args_print "${args}")
    message (SEND_ERROR "FAILED AT: ${dir}")
    message (SEND_ERROR "COMMAND: ${command_print} \n WITH ARGS: ${args_print}")
    message(FATAL_ERROR "OUTPUT:\n\
    ${error}")
endfunction()
