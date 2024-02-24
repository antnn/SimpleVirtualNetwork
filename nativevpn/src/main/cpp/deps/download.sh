#!/bin/bash
export SOFTETHERVPN_VERSION=5.02.5181
export OPENSSL_VERSION=3.2.1
export LIBICONV_VERSION=1.17
export SODIUM_VERSION=1.0.19-RELEASE
#export NCURSES_VERSION_TAG=34cc24447dc9e5700110580c784d9606f6cff5f0
#export READLINE_VERSION=8.1

mkdir -r external; cd external;
# Clone OpenSSL
if [ ! -d "openssl" ]; then
    git clone https://github.com/openssl/openssl.git --depth=1 -b openssl-$OPENSSL_VERSION openssl
else
    echo "Directory 'openssl' already exists, skipping clone."
fi

# Download and extract libiconv
if [ ! -d "iconv" ]; then
    wget https://ftp.gnu.org/pub/gnu/libiconv/libiconv-$LIBICONV_VERSION.tar.gz -O libiconv.tar.gz
    mkdir -p iconv
    tar -xzvf libiconv.tar.gz -C iconv
    (cd iconv && mv libiconv*/* .)
    rm -f libiconv.tar.gz
else
    echo "Directory 'iconv' already exists, skipping extract."
fi


# Clone libsodium
if [ ! -d "libsodium" ]; then
    git clone --depth=1 https://github.com/jedisct1/libsodium.git -b $SODIUM_VERSION
else
    echo "Directory 'libsodium' already exists, skipping clone."
fi

# Clone ncurses
#if [ ! -d "ncurses" ]; then
#    git clone https://android.googlesource.com/platform/external/ncurses
#    (cd ncurses && git checkout $NCURSES_VERSION_TAG)
#else
#    echo "Directory 'ncurses' already exists, skipping clone."
#fi

# Download and extract readline
#if [ ! -d "readline" ]; then
#    wget https://ftp.gnu.org/gnu/readline/readline-$READLINE_VERSION.tar.gz -O readline.tar.gz
#    mkdir -p readline
#    tar -xzvf readline.tar.gz -C readline
#    (cd readline && mv readline*/* .)
#    rm -f readline.tar.gz
#else
#    echo "Directory 'readline' already exists, skipping extract."
#fi
#rm -f readline.tar.gz

# Clone SoftEtherVPN
if [ ! -d "SoftEtherVPN" ]; then
    git clone --depth=1 https://github.com/SoftEtherVPN/SoftEtherVPN.git -b $SOFTETHERVPN_VERSION
    (cd SoftEtherVPN && git submodule update --init --recursive)
else
    echo "Directory 'SoftEtherVPN' already exists, skipping clone."
fi
