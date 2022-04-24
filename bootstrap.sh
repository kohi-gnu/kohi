#!/bin/sh

source ./env.sh
source ./utils.sh

export PATH="$KOHI_PATH:$PATH"


BINUTILS_VERSION=2.38
BINUTILS_ARCHIVE="binutils-${BINUTILS_VERSION}.tar.gz"
BINUTILS_URL="https://ftp.gnu.org/gnu/binutils/${BINUTILS_ARCHIVE}"
BINUTILS_SHA256="b3f1dc5b17e75328f19bd88250bee2ef9f91fc8cbb7bd48bdb31390338636052"

GCC_VERSION=12.1.0
GCC_ARCHIVE="gcc-${GCC_VERSION}.tar.gz"
GCC_URL="https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/${GCC_ARCHIVE}"
GCC_SHA256="e88a004a14697bbbaba311f38a938c716d9a652fd151aaaa4cf1b5b99b90e2de"

LINUX_LIBRE_VERSION=5.15.35
LINUX_LIBRE_ARCHIVE="linux-libre-${LINUX_LIBRE_VERSION}-gnu.tar.xz"
LINUX_LIBRE_URL="http://linux-libre.fsfla.org/pub/linux-libre/releases/${LINUX_LIBRE_VERSION}-gnu/${LINUX_LIBRE_ARCHIVE}"
LINUX_LIBRE_SHA256="dca48608695a1950bef81214a7f10b699aa06f85f3b12297e13ebc09562f15c2"

MUSL_VERSION=1.2.3
MUSL_ARCHIVE="musl-${MUSL_VERSION}.tar.gz"
MUSL_URL="https://musl.libc.org/releases/${MUSL_ARCHIVE}"
MUSL_SHA256="7d5b0b6062521e4627e099e4c9dc8248d32a30285e959b7eecaa780cf8cfd4a4"

MPFR_VERSION=4.1.0
MPFR_ARCHIVE="mpfr-${MPFR_VERSION}.tar.gz"
MPFR_URL="https://ftp.gnu.org/gnu/mpfr/${MPFR_ARCHIVE}"
MPFR_SHA256="3127fe813218f3a1f0adf4e8899de23df33b4cf4b4b3831a5314f78e65ffa2d6"

MPC_VERSION=1.2.1
MPC_ARCHIVE="mpc-${MPC_VERSION}.tar.gz"
MPC_URL="https://ftp.gnu.org/gnu/mpc/${MPC_ARCHIVE}"
MPC_SHA256="17503d2c395dfcf106b622dc142683c1199431d095367c6aacba6eec30340459"

GMP_VERSION=6.2.1
GMP_ARCHIVE="gmp-${GMP_VERSION}.tar.xz"
GMP_URL="https://ftp.gnu.org/gnu/gmp/${GMP_ARCHIVE}"
GMP_SHA256="fd4829912cddd12f84181c3451cc752be224643e87fac497b69edddadc49b4f2"

unset CFLAGS
unset CXXFLAGS


export MAKEFLAGS="-j$(nproc)"

mkdir -p "$KOHI_SYSROOT"
mkdir -p "$KOHI_PATH"
mkdir -p "$KOHI_SOURCES"

pushd "$KOHI_SOURCES"

# ============================================================================
#  Linux Libre Header
# ============================================================================
if [ ! -d "linux-${LINUX_LIBRE_VERSION}" ]
then
	download "$LINUX_LIBRE_URL" "$LINUX_LIBRE_ARCHIVE" "$LINUX_LIBRE_SHA256"
	tar -xf "$LINUX_LIBRE_ARCHIVE"
fi

pushd "linux-${LINUX_LIBRE_VERSION}"
	make mrproper
	make ARCH="$KOHI_ARCH" headers_check
	make ARCH="$KOHI_ARCH" INSTALL_HDR_PATH="$KOHI_CROSS/usr/" headers_install
popd # linux-libre

# ============================================================================
#  Binutils
# ============================================================================
if ! command -v "${KOHI_TARGET}-ld"
then 
	if [ ! -d "binutils-${BINUTILS_VERSION}" ]
	then
		download "$BINUTILS_URL" "$BINUTILS_ARCHIVE" "$BINUTILS_SHA256"
		tar -xf "$BINUTILS_ARCHIVE"
	fi

	pushd "binutils-${BINUTILS_VERSION}"
	if [ -d build ]
	then
		rm -rf build
	fi
	mkdir build
	pushd build
	../configure --prefix="$KOHI_CROSS" --with-sysroot="${KOHI_CROSS}/${KOHI_TARGET}" \
	             --target="$KOHI_TARGET" --disable-nls --disable-werror
	make
	make install
	popd # build
	popd # binutils 
fi

# ============================================================================
#  GCC
# ============================================================================
if ! command -v "${KOHI_TARGET}-gcc"
then
	if [ ! -d "gcc-${GCC_VERSION}" ]
	then
		download "$GCC_URL" "$GCC_ARCHIVE" "$GCC_SHA256"
		tar -xf "$GCC_ARCHIVE"
	fi

	pushd "gcc-${GCC_VERSION}"
	if [ ! -d mpfr ]
	then
		download "$MPFR_URL" "$MPFR_ARCHIVE" "$MPFR_SHA256"
		tar -xf "$MPFR_ARCHIVE"
		mv "mpfr-${MPFR_VERSION}" mpfr
	fi

	if [ ! -d gmp ]
	then
		download "$GMP_URL" "$GMP_ARCHIVE" "$GMP_SHA256"
		tar -xf "$GMP_ARCHIVE"
		mv "gmp-${GMP_VERSION}" gmp
	fi

	if [ ! -d mpc ]
	then
		download "$MPC_URL" "$MPC_ARCHIVE" "$MPC_SHA256"
		tar -xf "$MPC_ARCHIVE"
		mv "mpc-${MPC_VERSION}" mpc
	fi

	if [ -d build ]
	then
		rm -rf build
	fi

	mkdir build
	pushd build
	../configure --target="$KOHI_TARGET" --prefix="$KOHI_CROSS" --host="$KOHI_HOST" \
		--with-sysroot="${KOHI_CROSS}/${KOHI_TARGET}" --with-newlib --without-headers \
		--enable-initfini-array --disable-nls --disable-shared --disable-multilib \
		--disable-decimal-float --disable-threads --disable-libatomic \
		--disable-libgomp --disable-libquadmath --disable-libssp --disable-libvtv \
		--disable-libstdcxx --enable-languages=c

	make all-gcc all-target-libgcc
	make install-gcc install-target-libgcc
	popd # build
	popd # gcc
fi

# ============================================================================
#  musl
# ============================================================================
if [ ! -d "musl-${MUSL_VERSION}" ]
then
	download "$MUSL_URL" "$MUSL_ARCHIVE" "$MUSL_SHA256"
	tar -xf "$MUSL_ARCHIVE"
fi

pushd "musl-${MUSL_VERSION}"

if [ -d build ]
then
	rm -rf build
fi
mkdir build
pushd build
../configure CROSS_COMPILE="${KOHI_TARGET}-" --prefix=/ --target=$KOHI_TARGET 
make
make DESTDIR="${KOHI_CROSS}/${KOHI_TARGET}" install
popd # build
popd # musl

# ============================================================================
#  final GCC
# ============================================================================
pushd "gcc-${GCC_VERSION}"

rm -rf build
mkdir build

pushd build
../configure --prefix=${KOHI_CROSS} --build=${KOHI_HOST} --host=${KOHI_HOST} \
	--target=${KOHI_TARGET} --disable-multilib --with-sysroot=${KOHI_CROSS}/${CLFS_TARGET} \
	--disable-nls --disable-shared --enable-languages=c --disable-libmudflap \
	--enable-threads=posix --enable-clocale=generic --enable-libstdcxx-time \
    --disable-symvers --disable-libsanitizer --disable-lto-plugin \
	--disable-libssp 
make AS_FOR_TARGET="${KOHI_TARGET}-as" LD_FOR_TARGET="${KOHI_TARGET}-ld"
make install
popd # build

popd # gcc

popd # source

