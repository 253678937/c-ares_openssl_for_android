#!/bin/sh
OPENSSL_PREFIX="openssl-"
OPENSSL_VER="1.1.0f"
ANDROID_PLATFORM="android-14"
if [ $# == 1 ];then
    OPENSSL_VER=$1
fi
if [ $# == 2 ];then
    OPENSSL_VER=$1
    ANDROID_PLATFORM=$2
fi
# openssl src file
OPENSSL_SRC=${OPENSSL_PREFIX}${OPENSSL_VER}".tar.gz"
if [ ! -f ${OPENSSL_SRC} ]; then
    wget https://www.openssl.org/source/${OPENSSL_SRC}
fi
if [ ! -d ${OPENSSL_PREFIX}${OPENSSL_VER} ]; then 
    tar zxf ${OPENSSL_SRC}
fi
# env
if [ -d "out/openssl" ]; then
    rm -fr "out/openssl"
fi
mkdir "out"
mkdir "out/openssl"
_compile() {
    SURFIX=$1
    TOOL=$2
    ARCH_FLAGS=$3
    ARCH_LINK=$4
    CFGNAME=$5
    ARCH=$6
    if [ ! -d "out/openssl/${SURFIX}" ]; then
        mkdir "out/openssl/${SURFIX}" 
    fi
    if [ ! -d "toolchain_${SURFIX}" ]; then
        $ANDROID_NDK_ROOT/build/tools/make-standalone-toolchain.sh --arch=${ARCH} --platform=${ANDROID_PLATFORM} --install-dir=./toolchain_${SURFIX}
    fi
    export ANDROID_HOME=`pwd`
    export TOOLCHAIN=$ANDROID_HOME/toolchain_${SURFIX}
    export CROSS_SYSROOT=$TOOLCHAIN/sysroot
    export PATH=$TOOLCHAIN/bin:$PATH
    export CC=$TOOLCHAIN/bin/${TOOL}-gcc
    export CXX=$TOOLCHAIN/bin/${TOOL}-g++
    export LINK=${CXX}
    export LD=$TOOLCHAIN/bin/${TOOL}-ld
    export AR=$TOOLCHAIN/bin/${TOOL}-ar
    export RANLIB=$TOOLCHAIN/bin/${TOOL}-ranlib
    export STRIP=$TOOLCHAIN/bin/${TOOL}-strip
    export ARCH_FLAGS=$ARCH_FLAGS
    export ARCH_LINK=$ARCH_LINK
    export CFLAGS="${ARCH_FLAGS} -fpic -ffunction-sections -funwind-tables -fstack-protector -fno-strict-aliasing -finline-limit=64"
    export CXXFLAGS="${CFLAGS} -frtti -fexceptions"
    export LDFLAGS="${ARCH_LINK}"
    cd ${OPENSSL_PREFIX}${OPENSSL_VER}/
    ./Configure ${CFGNAME} --prefix=$TOOLCHAIN/sysroot/usr/local --with-zlib-include=$TOOLCHAIN/sysroot/usr/include --with-zlib-lib=$TOOLCHAIN/sysroot/usr/lib zlib no-asm no-shared no-unit-test
    make clean
    make -j4
    #make install
    make install_sw
    make install_ssldirs
    cd ..
    mv ${OPENSSL_PREFIX}${OPENSSL_VER}/libssl.a out/openssl/${SURFIX}/ 
    mv ${OPENSSL_PREFIX}${OPENSSL_VER}/libcrypto.a out/openssl/${SURFIX}/
}
# arm
_compile "armeabi" "arm-linux-androideabi" "-mthumb" "" "android" "arm"
# armv7
_compile "armeabi-v7a" "arm-linux-androideabi" "-march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16" "-march=armv7-a -Wl,--fix-cortex-a8" "android-armeabi" "arm"
# arm64v8
_compile "arm64-v8a" "aarch64-linux-android" "" "" "android64-aarch64" "arm64"
# x86
_compile "x86" "i686-linux-android" "-march=i686 -m32 -msse3 -mstackrealign -mfpmath=sse -mtune=intel" "" "android-x86" "x86"

PLAFORM_21="android-21"
# only android-21 and later support 64
if [[ ${ANDROID_PLATFORM} > ${PLAFORM_21} || ${ANDROID_PLATFORM} = ${PLAFORM_21} ]];then
    # x86_64
    _compile "x86_64" "x86_64-linux-android" "-march=x86-64 -m64 -msse4.2 -mpopcnt  -mtune=intel" "" "android64" "x86_64"
fi
# mips
# _compile "mips" "mipsel-linux-android" "" "" "android-mips" "mips"
# mips64
# _compile "mips64" "mips64el-linux-android" "" "" "linux64-mips64" "mips64"
echo "done"
