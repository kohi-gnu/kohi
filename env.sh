export KOHI_KERNEL="linux"
export KOHI_LIBC="musl"
export KOHI_ARCH=i386

export KOHI_CROSS="$(pwd)/crosstools"
export KOHI_PATH="${KOHI_CROSS}/bin"

export KOHI_SOURCES="$(pwd)/sources"
export KOHI_HOST=$MACHTYPE

export KOHI_TARGET="${KOHI_ARCH}-kohi-${KOHI_KERNEL}-${KOHI_LIBC}"
export KOHI_SYSROOT="${KOHI_CROSS}/${KOHI_TARGET}"