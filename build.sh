#!/bin/bash

# Script edited by xanaxdroid

# Bash Color
green='\033[01;32m'
red='\033[01;31m'
blink_red='\033[05;31m'
restore='\033[0m'

clear

# Number of threads to use. Cores+2 
NUMJOBS="$(cat /proc/cpuinfo | grep -c processor)";
if [ $NUMJOBS = "4" ];
then
    THREAD="-j6";
elif [ $NUMJOBS = "6" ];
then
    THREAD="-j8";
elif [ $NUMJOBS = "8" ];
then
    THREAD="-j10";
elif [ $NUMJOBS = "10" ];
then
    THREAD="-j12";
elif [ $NUMJOBS = "12" ];
then
    THREAD="-j14";
elif [ $NUMJOBS = "14" ];
then
    THREAD="-j16";
elif [ $NUMJOBS = "16" ];
    THREAD="-j18";
else
    THREAD=-j"$NUMJOBS";
fi;

# Other resources
KERNEL="Image.gz"
DTBIMAGE="dtb"
DEFCONFIG="saber_defconfig"
KERNEL_DIR=`pwd`
ANYKERNEL_DIR="${HOME}/kernel/sC-Angler-AnyKernel2"

# Kernel Details
BASE_AK_VER="fuckery"
VER=".3.75"
AK_VER="$BASE_AK_VER$VER"

# Vars
export USE_CCACHE=1
export LOCALVERSION=~`echo $AK_VER`
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER=f100cleveland
export KBUILD_BUILD_HOST=BuildBox
CROSS_COMPILE="${HOME}/toolchain/UBERTC-aarch64-linux-android-6.0-kernel/bin/aarch64-linux-android-"

if [ "$USE_CCACHE" = 1 ]; then
   export CROSS_COMPILE="ccache $CROSS_COMPILE"
else
   export CROSS_COMPILE="$CROSS_COMPILE"
fi

# Paths
REPACK_DIR="$ANYKERNEL_DIR"
PATCH_DIR="$ANYKERNEL_DIR/patch"
MODULES_DIR="$ANYKERNEL_DIR/modules"
ZIP_MOVE="${HOME}/AK-releases"
ZIMAGE_DIR="$KERNEL_DIR/arch/arm64/boot"

# Functions
function clean_all {
		echo; ccache -c -C echo;
		if [ -f "$MODULES_DIR/*.ko" ]; then
			rm `echo $MODULES_DIR"/*.ko"`
		fi
		cd $REPACK_DIR
		rm -rf $KERNEL
		rm -rf $DTBIMAGE
		git reset --hard > /dev/null 2>&1
		git clean -f -d > /dev/null 2>&1
		cd $KERNEL_DIR
		echo
		make clean && make mrproper
}

function make_kernel {
		echo
		make $DEFCONFIG
		make $THREAD
		cp -vr $ZIMAGE_DIR/$KERNEL $REPACK_DIR/zImage
}

function make_modules {
		if [ -f "$MODULES_DIR/*.ko" ]; then
			rm `echo $MODULES_DIR"/*.ko"`
		fi
		#find $MODULES_DIR/proprietary -name '*.ko' -exec cp -v {} $MODULES_DIR \;
		find $KERNEL_DIR -name '*.ko' -exec cp -v {} $MODULES_DIR \;
}

function make_dtb {
		$REPACK_DIR/tools/dtbToolCM -v2 -o $REPACK_DIR/$DTBIMAGE -s 2048 -p scripts/dtc/ arch/arm64/boot/dts/
}

function make_zip {
		cd $REPACK_DIR
		zip -x@zipexclude -r9 `echo $AK_VER`.zip *
		mv  `echo $AK_VER`.zip $ZIP_MOVE
		cd $KERNEL_DIR
}


DATE_START=$(date +"%s")

echo -e "${green}"
echo "saberCore64 Kernel Creation Script:"
echo

echo "---------------"
echo "Kernel Version:"
echo "---------------"

echo -e "${red}"; echo -e "${blink_red}"; echo "$AK_VER"; echo -e "${restore}";

echo -e "${green}"
echo "-----------------"
echo "Making sC64 Kernel:"
echo "-----------------"
echo -e "${restore}"

while read -p "Do you want to clean stuffs (y/n)? " cchoice
do
case "$cchoice" in
	y|Y )
		clean_all
		echo
		echo "All Cleaned now."
		break
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done

echo

while read -p "Do you want to build kernel (y/n)? " dchoice
do
case "$dchoice" in
	y|Y)
		make_kernel
		make_dtb
		make_modules
		make_zip
		break
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done

echo -e "${green}"
echo "-------------------"
echo "Build Completed in:"
echo "-------------------"
echo -e "${restore}"

DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo "Time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
echo

