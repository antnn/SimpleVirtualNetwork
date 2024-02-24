#!/bin/bash
export CC=""
OUTPUT=$PWD
(cd external
    mkdir -p hamcorebuilder-src
    cp -Rf SoftEtherVPN hamcorebuilder-src/
    cd  hamcorebuilder-src/SoftEtherVPN
    sed -i -e '/add_subdirectory(Mayaqua)/s/^/#/' \
-e '/add_subdirectory(Cedar)/s/^/#/' \
-e '/add_subdirectory(vpnserver)/s/^/#/' \
-e '/add_subdirectory(vpnclient)/s/^/#/' \
-e '/add_subdirectory(vpnbridge)/s/^/#/' \
-e '/add_subdirectory(vpncmd)/s/^/#/' \
-e '/add_subdirectory(vpntest)/s/^/#/' \
-e '/add_custom_target(hamcore-archive-build/,/)/s/^/#/' src/CMakeLists.txt ; \
    mkdir -p build ;   ./configure ; make -C build -j$(nproc) ; \
    cp build/src/hamcorebuilder/hamcorebuilder $OUTPUT  ;
)
