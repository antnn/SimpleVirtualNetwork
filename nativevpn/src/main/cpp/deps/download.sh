#!/bin/bash
export SOFTETHERVPN_VERSION=5.02.5181
export OPENSSL_VERSION=3.2.1
export SODIUM_VERSION=1.0.19-RELEASE


mkdir -r external; cd external;
# Clone OpenSSL
if [ ! -d "openssl" ]; then
    git clone https://github.com/openssl/openssl.git --depth=1 -b openssl-$OPENSSL_VERSION openssl
else
    echo "Directory 'openssl' already exists, skipping clone."
fi


# Clone libsodium
if [ ! -d "libsodium" ]; then
    git clone --depth=1 https://github.com/jedisct1/libsodium.git -b $SODIUM_VERSION
else
    echo "Directory 'libsodium' already exists, skipping clone."
fi

# Clone SoftEtherVPN
if [ ! -d "SoftEtherVPN" ]; then
    git clone --depth=1 https://github.com/antnn/SoftEtherVPN.git 
    (cd SoftEtherVPN && git submodule update --init --recursive)
else
    echo "Directory 'SoftEtherVPN' already exists, skipping clone."
fi
