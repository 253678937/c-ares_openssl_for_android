#!/bin/sh
CARES_PREFIX="c-ares-"
CARES_VER="1.13.0"
ANDROID_PLATFORM="android-14"
if [ $# == 1 ];then
    CARES_VER=$1
fi
if [ $# == 2 ];then
    CARES_VER=$1
    ANDROID_PLATFORM=$2
fi
# cares src file
CARES_SRC=${CARES_PREFIX}${CARES_VER}".tar.gz"
if [ ! -f ${CARES_SRC} ]; then
    wget http://c-ares.haxx.se/download/${CARES_SRC}
fi
if [ ! -d ${CARES_PREFIX}${CARES_VER} ]; then 
    tar zxf ${CARES_SRC}
fi
# env
if [ -d "out/cares" ]; then
    rm -fr "out/cares"
fi
mkdir "out"
mkdir "out/cares"
_compile() {
    SURFIX=$1
    TOOL=$2
    ARCH_FLAGS=$3
    ARCH_LINK=$4
    CFGNAME=$5
    ARCH=$6
    HOST=$7
    if [ ! -d "out/cares/${SURFIX}" ]; then
        mkdir "out/cares/${SURFIX}" 
    fi
    if [ ! -d "toolchain_${SURFIX}" ]; then
        $ANDROID_NDK_ROOT/build/tools/make-standalone-toolchain.sh --arch=${ARCH} --platform=${ANDROID_PLATFORM} --install-dir=./toolchain_${SURFIX}
    fi
    export ANDROID_HOME=`pwd`
    export TOOLCHAIN=$ANDROID_HOME/toolchain_${SURFIX}
    export PATH=$TOOLCHAIN/bin:$PATH
    export SYSROOT=$TOOLCHAIN/sysroot
    export CC=${TOOL}"-gcc --sysroot $SYSROOT"
    export CXX=${TOOL}"-g++ --sysroot $SYSROOT"
    cd ${CARES_PREFIX}${CARES_VER}/
    mkdir build
    ./configure --prefix=$(pwd)/build --host=${HOST} --disable-shared CFLAGS=${ARCH_FLAGS}
    # Build and install
    make && make install
    cd ..
    mv ${CARES_PREFIX}${CARES_VER}/build/lib/libcares.a out/cares/${SURFIX}/
}
# arm
_compile "armeabi" "arm-linux-androideabi" "-mthumb" "" "android" "arm" "arm-linux-androideabi"
# armv7
#_compile "armeabi-v7a" "arm-linux-androideabi" "-march=armv7-a" "-march=armv7-a -Wl,--fix-cortex-a8" "android-armeabi" "arm" "arm-linux-androideabi"
# x86
_compile "x86" "i686-linux-android" "-m32 -march=i686" "" "android-x86" "x86" "x86"

PLAFORM_21="android-21"
# only android-21 and later support 64
if [[ ${ANDROID_PLATFORM} > ${PLAFORM_21} || ${ANDROID_PLATFORM} = ${PLAFORM_21} ]];then
    # arm64v8
    #_compile "arm64-v8a" "aarch64-linux-android" "" "" "android64-aarch64" "arm64" "aarch64-linux-android"
    # x86_64
    _compile "x86_64" "x86_64-linux-android" "-march=x86-64" "" "android64" "x86_64" "x86_64"
fi
# mips
# _compile "mips" "mipsel-linux-android" "" "" "android-mips" "mips"
# mips64
# _compile "mips64" "mips64el-linux-android" "" "" "linux64-mips64" "mips64"
echo "done"
