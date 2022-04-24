#!/bin/bash

source ./env.sh
source ./utils.sh

# nginx
LIBRESSL_VERSION=3.5.2
LIBRESSL_ARCHIVE="libressl-${LIBRESSL_VERSION}.tar.gz"
LIBRESSL_URL="https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/${LIBRESSL_ARCHIVE}"
LIBRESSL_SHA256="56feab8e21c3fa6549f8b7d7511658b8e98518162838a795314732654adf3e5f"

# ksh (XXX: remove the need for libbsd)
LIBBSD_VERSION=0.11.6
LIBBSD_ARCHIVE="libbsd-${LIBBSD_VERSION}.tar.xz"
LIBBSD_URL="https://libbsd.freedesktop.org/releases/${LIBBSD_ARCHIVE}"
LIBBSD_SHA256="19b38f3172eaf693e6e1c68714636190c7e48851e45224d720b3b5bc0499b5df"

# nginx
PCRE2_VERSION=10.40
PCRE2_ARCHIVE="pcre2-${PCRE2_VERSION}.tar.gz"
PCRE2_URL="https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${PCRE2_VERSION}/${PCRE2_ARCHIVE}"
PCRE2_SHA256="ded42661cab30ada2e72ebff9e725e745b4b16ce831993635136f2ef86177724"

# nginx
ZLIB_VERSION=1.2.12
ZLIB_ARCHIVE="zlib-${ZLIB_VERSION}.tar.xz"
ZLIB_URL="https://zlib.net/${ZLIB_ARCHIVE}"
ZLIB_SHA256="7db46b8d7726232a621befaab4a1c870f00a90805511c0e0090441dac57def18"

# tor
LIBEVENT_VERSION=2.1.12-stable
LIBEVENT_ARCHIVE="libevent-${LIBEVENT_VERSION}.tar.gz"
LIBEVENT_URL="https://github.com/libevent/libevent/releases/download/release-${LIBEVENT_VERSION}/${LIBEVENT_ARCHIVE}"
LIBEVENT_SHA256="92e6de1be9ec176428fd2367677e61ceffc2ee1cb119035037a27d346b0403bb"

export CFLAGS="-fPIE -fstack-clash-protection -fstack-protector-strong -fcf-protection=full -O2 -D_FORTIFY_SOURCE=2"
export LDFLAGS="-Wl,-z,now -Wl,-z,relro"

pushd "$KOHI_SOURCES"

# ============================================================================
#  LibreSSL
# ============================================================================
if [ ! -d "libressl-${LIBRESSL_VERSION}" ]
then
	download "$LIBRESSL_URL" "$LIBRESSL_ARCHIVE" "$LIBRESSL_SHA256"
	tar -xf "${LIBRESSL_ARCHIVE}"
fi

pushd "libressl-${LIBRESSL_VERSION}"
if [ -d build ]
then
	rm -rf build
fi

./autogen.sh

mkdir build
pushd build
../configure --prefix=/ --target=$KOHI_TARGET --disable-shared
make
make DESTDIR="${KOHI_SYSROOT}" install
popd # build
popd # libressl

# ============================================================================
#  LibBSD
# ============================================================================
if [ ! -d "libbsd-${LIBBSD_VERSION}" ]
then
	download "$LIBBSD_URL" "$LIBBSD_ARCHIVE" "$LIBBSD_SHA256"
	tar -xf "${LIBBSD_ARCHIVE}"
fi

pushd "libbsd-${LIBBSD_VERSION}"
if [ -d build ]
then
	rm -rf build
fi

mkdir build
pushd build
../configure --prefix=/ --target="$KOHI_TARGET" --disable-shared
make
make DESTDIR="$KOHI_SYSROOT" install
popd # build
popd # libbsd

# ============================================================================
#  PCRE2
# ============================================================================
if [ ! -d "pcre2-${PCRE2_VERSION}" ]
then
	download "$PCRE2_URL" "$PCRE2_ARCHIVE" "$PCRE2_SHA256"
	tar -xf "$PCRE2_ARCHIVE"
fi

pushd "pcre2-${PCRE2_VERSION}"
if [ -d build ]
then
	rm -rf build
fi

mkdir build
pushd build
../configure --prefix=/ --target="$KOHI_TARGET" --disable-shared
make
make DESTDIR="$KOHI_SYSROOT" install
popd # build
popd # pcre2

# ============================================================================
#  zlib
# ============================================================================
if [ ! -d "zlib-${ZLIB_VERSION}" ]
then
	download "$ZLIB_URL" "$ZLIB_ARCHIVE" "$ZLIB_SHA256"
	tar -xf "$ZLIB_ARCHIVE"
fi

pushd "zlib-${ZLIB_VERSION}"
if [ -d build ]
then
	rm -rf build
fi

mkdir build
pushd build
CHOST="$KOHI_TARGET" ../configure --prefix=/  --static
make
make DESTDIR="$KOHI_SYSROOT" install
popd # build
popd # zlib

# ============================================================================
#  libevent
# ============================================================================
if [ ! -d "libevent-${LIBEVENT_VERSION}" ]
then
	download "$LIBEVENT_URL" "$LIBEVENT_ARCHIVE" "$LIBEVENT_SHA256"
	tar -xf "$LIBEVENT_ARCHIVE"
fi

pushd "libevent-${LIBEVENT_VERSION}"
if [ -d build ]
then
	rm -rf build
fi

mkdir build
pushd build
../configure --prefix=/ --target="$KOHI_TARGET" --disable-shared
make
make DESTDIR="$KOHI_SYSROOT" install
popd # build
popd # libevent

popd
