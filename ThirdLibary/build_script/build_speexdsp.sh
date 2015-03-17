#作者：康林
#参数:
#    $1:编译目标(android、windows_msvc、windows_mingw、unix、unix_mingw)
#    $2:源码的位置 

#运行本脚本前,先运行 build_$1_envsetup.sh 进行环境变量设置,需要先设置下面变量:
#   RABBITIM_BUILD_TARGERT   编译目标（android、windows_msvc、windows_mingw、unix、unix_mingw）
#   RABBITIM_BUILD_PREFIX=`pwd`/../${RABBITIM_BUILD_TARGERT}  #修改这里为安装前缀
#   RABBITIM_BUILD_SOURCE_CODE    #源码目录
#   RABBITIM_BUILD_CROSS_PREFIX     #交叉编译前缀
#   RABBITIM_BUILD_CROSS_SYSROOT  #交叉编译平台的 sysroot

HELP_STRING="Usage $0 PLATFORM (android|windows_msvc|windows_mingw|unix|unix_mingw) SOURCE_CODE_ROOT"

case $1 in
    android|windows_msvc|windows_mingw|unix|unix_mingw)
    RABBITIM_BUILD_TARGERT=$1
    ;;
    *)
    echo "${HELP_STRING}"
    return 1
    ;;
esac

if [ -z "${RABBITIM_BUILD_PREFIX}" ]; then
    echo "source build_${RABBITIM_BUILD_TARGERT}_envsetup.sh"
    source build_${RABBITIM_BUILD_TARGERT}_envsetup.sh
fi

if [ -n "$2" ]; then
    RABBITIM_BUILD_SOURCE_CODE=$2
else
    RABBITIM_BUILD_SOURCE_CODE=${RABBITIM_BUILD_PREFIX}/../src/speexdsp
fi

#下载源码:
if [ ! -d ${RABBITIM_BUILD_SOURCE_CODE} ]; then
    echo "git clone http://git.xiph.org/speexdsp.git  ${RABBITIM_BUILD_SOURCE_CODE}"
    git clone http://git.xiph.org/speexdsp.git  ${RABBITIM_BUILD_SOURCE_CODE}
fi

CUR_DIR=`pwd`
cd ${RABBITIM_BUILD_SOURCE_CODE}

if [ ! -f configure ]; then
    echo "sourc autogen.sh"
    source autogen.sh 
fi

mkdir -p build_${RABBITIM_BUILD_TARGERT}
cd build_${RABBITIM_BUILD_TARGERT}
rm -fr *

echo ""
echo "RABBITIM_BUILD_TARGERT:${RABBITIM_BUILD_TARGERT}"
echo "RABBITIM_BUILD_SOURCE_CODE:$RABBITIM_BUILD_SOURCE_CODE"
echo "CUR_DIR:`pwd`"
echo "RABBITIM_BUILD_PREFIX:$RABBITIM_BUILD_PREFIX"
echo "RABBITIM_BUILD_HOST:$RABBITIM_BUILD_HOST"
echo "RABBITIM_BUILD_CROSS_PREFIX:$RABBITIM_BUILD_CROSS_PREFIX"
echo "RABBITIM_BUILD_CROSS_SYSROOT:$RABBITIM_BUILD_CROSS_SYSROOT"
echo ""

echo "configure ..."

CONFIG_PARA="--disable-static --enable-shared"
case ${RABBITIM_BUILD_TARGERT} in
    android)
        CONFIG_PARA="CC=${RABBITIM_BUILD_CROSS_PREFIX}gcc --disable-shared -enable-static --with-gnu-ld --host=${RABBITIM_BUILD_HOST}"
        CONFIG_PARA="${CONFIG_PARA} --with-sysroot=${RABBITIM_BUILD_CROSS_SYSROOT}"
        CFLAGS="-march=armv7-a -mfpu=neon --sysroot=${RABBITIM_BUILD_CROSS_SYSROOT}"
        CPPFLAGS="-march=armv7-a -mfpu=neon --sysroot=${RABBITIM_BUILD_CROSS_SYSROOT}"
    ;;
    unix)
        CONFIG_PARA="${CONFIG_PARA} --enable-vbr --enable-sse"
    ;;
    windows_msvc)
    ;;
    windows_mingw)
    ;;
	unix_mingw)
		CONFIG_PARA="CC=${RABBITIM_BUILD_CROSS_PREFIX}gcc --enable-shared --with-gnu-ld --host=${RABBITIM_BUILD_HOST}"
		;;
    *)
    echo "${HELP_STRING}"
    return 2
    ;;
esac

CONFIG_PARA="${CONFIG_PARA}"
echo "../configure --prefix=$RABBITIM_BUILD_PREFIX  --disable-examples  ${CONFIG_PARA} CFLAGS=\"${CFLAGS}\" CPPFLAGS=\"${CPPFLAGS}\""
../configure --prefix=$RABBITIM_BUILD_PREFIX  --disable-examples ${CONFIG_PARA} CFLAGS="${CFLAGS}" CPPFLAGS="${CPPFLAGS}"

echo "make install"
make -j 2 && make install

cd $CUR_DIR
