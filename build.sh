 # Licensed under the Apache License, Version 2.0 (the "License");
 # you may not use this file except in compliance with the License.
 # You may obtain a copy of the License at
 #
 #      http://www.apache.org/licenses/LICENSE-2.0
 #
 # Unless required by applicable law or agreed to in writing, software
 # distributed under the License is distributed on an "AS IS" BASIS,
 # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 # See the License for the specific language governing permissions and
 # limitations under the License.
 # 
 
#! /bin/sh

#Kernel building script

KERNEL_DIR=`pwd`
function colors {
	blue='\033[0;34m' cyan='\033[0;36m'
	yellow='\033[0;33m'
	red='\033[0;31m'
	nocol='\033[0m'
}

colors;
PARSE_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
PARSE_ORIGIN="$(git config --get remote.origin.url)"
COMMIT_POINT="$(git log --pretty=format:'%h : %s' -1)"
TELEGRAM_TOKEN=${BOT_API_KEY}
export BOT_API_KEY PARSE_BRANCH PARSE_ORIGIN COMMIT_POINT TELEGRAM_TOKEN
. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"/stacks/telegram
kickstart_pub
function clone {
	git clone --depth=1 --no-single-branch https://github.com/RaphielGang/aarch64-raph-linux-android.git
	git clone --depth=1 --no-single-branch https://github.com/baalajimaestro/anykernel2.git anykernel2
}

function exports {
	export KBUILD_BUILD_USER="baalajimaestro"
	export KBUILD_BUILD_HOST="maestro-ci"
	export ARCH=arm64
	export SUBARCH=arm64
        PATH=$KERNEL_DIR/aarch64-raph-linux-android/bin:$PATH
	export PATH
}

function build_kernel {
	#better checking defconfig at first
	if [ -f $KERNEL_DIR/arch/arm64/configs/whyred_defconfig ]
	then 
		DEFCONFIG=whyred_defconfig
	elif [ -f $KERNEL_DIR/arch/arm64/configs/whyred_defconfig ]
	then
		DEFCONFIG=whyred_defconfig
	else
		echo "Defconfig Mismatch"
		echo "Exiting in 5 seconds"
		sleep 5
		exit
	fi
	
	make O=out $DEFCONFIG
	BUILD_START=$(date +"%s")
	make -j8 O=out \
		CROSS_COMPILE=$KERNEL_DIR/aarch64-raph-linux-android/bin/aarch64-raph-linux-android-
	BUILD_END=$(date +"%s")
	BUILD_TIME=$(date +"%Y%m%d-%T")
	DIFF=$((BUILD_END - BUILD_START))	
}

function check_img {
	if [ -f $KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb ]
	then 
		echo -e "Kernel Built Successfully in $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds..!!"
		gen_zip
	else 
		finerr
	fi	
}

function gen_zip {
	if [ -f $KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb ]
	then 
		echo "Zipping Files.."
		mv $KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb anykernel2/Image.gz-dtb
		cd anykernel2
		zip -r9 "Retarded-Nightly.zip" * -x .git README.md Retarded-Nightly.zip
		fin
		push
		cd ..
        fi
}
tg_senderror() {
    tg_sendinfo "Build Throwing Error(s)" \
    "@baalajimaestro naaaaa"
     tg_channelcast "Build Throwing Error(s)"
     tg_debugcast "Build Throwing Error(s)"
     exit 1
}

tg_yay() {
    tg_sendinfo "Compilation for whyred Completed yay" \
    "Haha yes"
}

# Fin Prober
fin() {
    echo "Yay! My works took $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds.~"
    tg_sendinfo "Build for whyred with GCC-7.3-Raph took $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds"
    tg_channelcast "Build for whyred with GCC-7.3-Raph took $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds"
    tg_yay
}
finerr() {
    echo "My works took $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds but it's error..."
    tg_sendinfo "Build for whyred with clang took $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds" \
                "but it is having error anyways xd"
    tg_senderror
    exit 1
}
clone
exports
build_kernel
check_img
