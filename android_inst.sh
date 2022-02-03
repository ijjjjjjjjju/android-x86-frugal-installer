#!/bin/bash

SCRIPT=$(cd $(dirname $0); pwd)

function abort_install(){
	zenity --info --width 400 --title "インストール中断" --text "インストールを中断しました"
	exit
}

#root check
ROOT=$(whoami)
if [ $ROOT != "root" ]; then
	zenity --warning --width 400 --text "インストールにはroot権限が必要です\n　sudo ./android_inst.sh\n　として実行してください"
	abort_install
fi

zenity --info --width 600 --text "Android x86のインストールを開始します。\n最終確認までは、インストールはキャンセルを選択することでいつでも中断できます。"


#simple descriptions
zenity --info --width 400 --text "インストールについての簡易説明を見ますか？"
INST_DESC=$(zenity --list  --title "simple descriptions" --text "" --column "select" no yes)
if [ -z $INST_DESC ]; then abort_install; fi
if [ $INST_DESC = "yes" ]; then
	zenity --info --width 880 --text "android-x86を他のLinux環境上にいわゆるfrugal installします。\nなお動作確認はUbuntu 20.04.1 LTS環境で行っています。他の環境でも動作する可能性はありますが未確認です。\n作業内容は以下となります。\n・android-x86のフォルダの作成\n・android-x86 ISOイメージの展開(標準のHoudini Binary Translatorの導入)\n・起動用grubの設定\n以下はオプションです。通常は必要ありません。理解している場合のみ行ってください\n・OpenGappsの導入\n・Linux firmwareの更新\n・Linux kernelの更新\n・ChromeOS由来のarmeabi-v7a及びarm64-v8a対応Houdini Binary Translatorの導入(非常に実験的)\n\n\n必要な事前準備\n・Android-x86のISOイメージ\n　9.0-r2(officail)をインストールする場合は、本scriptと同じフォルダにISOファイルをおいてください。\n　存在しない場合は、OSDNから自動的にダウンロードして使用します。\n　custom imageを使用する場合は、配置場所は自由です。\n・android-x86をインストールするパーティションのUUIDの確認\n\nオプション(通常は不要です)\n・ChromeOSのリカバリーイメージ\n　配置場所は自由です。\n・kernelの更新ファイル\n・linux kernel firmwareの更新ファイル\n・Opengappsのzipファイル\n　kernelおよびfirmwareについてはインストール作業前に圧縮ファイルを展開しておいてください\n　また、OpenGappsを導入する場合は、事前にlzipを導入してください\n 　　sudo apt install lzip\n　なお、ChromeOS由来のBinary Translatorの導入を行うと同時にWidevine(L3)も導入されますが、動作については未確認です。"
fi

#install selection
zenity --info --width 400 --text "インストールするandroidのversionを選択してください\n特に理由がない場合は、9.0-r2(official)が推奨です。"
VER_INST=$(zenity --list  --title "version" --text "" --column "select" 9.0-r2\(official\) custom_image )
if [ -z $VER_INST ]; then abort_install; fi
#choose ISO file
if [ $VER_INST = "custom_image" ]; then
	zenity --info --width 600 --text "Android x86のインストールに使用するISOイメージファイルを選択してください"
	ANDROID_ISO=$(zenity --width 400 --file-selection --title "select android-x86 ISO image")
	if [ -z $ANDROID_ISO ]; then abort_install; fi
fi

#select install dir
ANDROID_INST_DIR=$(zenity --entry --title "インストール先" --entry-text="/android" --text="Android-x86をインストールするフォルダを入力してください"　)
if [ -z $ANDROID_INST_DIR ]; then abort_install; fi
if [ -e $ANDROID_INST_DIR ]; then 
	zenity --error --width 400 --text "すでに存在しています"
	abort_install
fi


#UUID
zenity --info --width 600 --text "Android x86をインストールするパーティションのUUIDを入力してください\n標準的なインストールの場合は、すでに入力されている値が通常は適切です"
#/etc/fstabからUUIDを読み取って初期入力値に設定
UUIDTMP=$(sed -n -e '0,/^UUID*/p' < /etc/fstab |sed -n -e '/^UUID=/p' |sed -n -e 's/UUID=//p')
UUIDTMP2=$(cut -d' ' -f 1 <<<$UUIDTMP)
UUIDNAME=$(zenity --entry --title "UUID" --width 400 --text "Please input UUID" --entry-text=$UUIDTMP2)
if [ -z $UUIDNAME ]; then abort_install; fi


#Grub update selection
zenity --info --width 600 --text "Grub設定の更新を行いますか？通常は<span color=\"red\">「yes」</span>を選択してください。"
GRUB=$(zenity --list  --title "grub" --text "" --column "select" yes no)
if [ -z $GRUB ]; then abort_install; fi
if [ $GRUB = "yes" ]; then
	zenity --info --width 600 --text "GRUBに表示するタイトル名を入力してください"
	TITLE=$(zenity --entry --title "タイトル名" --entry-text="Android-x86" --text="GRUBに表示するタイトル名を入力してください"　)
	if [ -z $TITLE ]; then abort_install; fi
	zenity --info --width 600 --text "VULKANを有効化しますか？<span color=\"red\">「yes」</span>を選択することをお勧めします。"
	VULKAN_SELECT=$(zenity --list  --title "VULKAN" --text "" --column "select" no yes)
	if [ -z $VULKAN_SELECT ]; then abort_install; fi
	if [ $VULKAN_SELECT = "yes" ]; then
		VULKAN="VULKAN=1"
	fi	
	zenity --info --width 600 --text "VIRT_WIFIを無効化しますか？通常は<span color=\"red\">「no」</span>を選択してください。"
	VIRT=$(zenity --list  --title "VIRT_WIFI" --text "" --column "select" no yes)
	if [ -z $VIRT ]; then abort_install; fi
	if [ $VIRT = "yes" ]; then
		VIRT_WIFI="VIRT_WIFI=0"
	fi
#	zenity --info --width 600 --text "HWCにdrmfbを使用しますか？通常は<span color=\"red\">「no」</span>を選択してください。"
#	HWC_SELECT=$(zenity --list  --title "HWC" --text "" --column "select" no yes)
#	if [ -z $HWC_SELECT ]; then abort_install; fi
#	if [ $HWC_SELECT = "yes" ]; then
#		HWC="HWC=drmfb"
#	fi		
fi


if [ $VER_INST = "custom_image" ]; then
#Gapps install selection
   zenity --info --width 400 --text "Open gapps を別途インストールするか選んでください。通常は<span color=\"red\">「no」</span>を選択してください。"
   GAPPS_INST=$(zenity --list  --title "gapps" --text "" --column "select" no yes)
   if [ -z $GAPPS_INST ]; then abort_install; fi
   if [ $GAPPS_INST = "yes" ]; then
	zenity --info --width 400 --text "使用するOpen Gappsのzipファイルを選択してください"
	OPANGAPPS_ZIP=$(zenity --width 400 --file-selection --title "Open gapps ZIP file" --filename="./")
	if [ -z $OPANGAPPS_ZIP ]; then abort_install; fi
   fi
fi


if [ $VER_INST = "custom_image" ]; then
#firmware update
   zenity --info --width 400 --text "firmwareをアップデートするかどうかを選んでください。通常は<span color=\"red\">「no」</span>を選択してください。"
   FIRM_INST=$(zenity --list  --title "firmware" --text "" --column "select" no yes)
   if [ -z $FIRM_INST ]; then abort_install; fi
   if [ $FIRM_INST = "yes" ]; then
 	zenity --info --width 400 --text "使用するfirmwareが存在するフォルダを選択してください"
	NEW_FIRM=$(zenity --width 400 --file-selection --title "new firmware" --directory --filename="./")
	if [ -z $NEW_FIRM ]; then abort_install; fi
   fi
fi


if [ $VER_INST = "custom_image" ]; then
#kernel update
   zenity --info --width 400 --text "kernelの更新を行うかどうかを選択してください。通常は<span color=\"red\">「no」</span>を選択してください。"
   UPDATE_KERNEL=$(zenity --list  --title "kernel" --text "kernelの更新を行いますか？" --column "select" no yes)
   if [ -z $UPDATE_KERNEL ]; then abort_install; fi
   if [ $UPDATE_KERNEL = "yes" ]; then
	zenity --info --width 400 --text "更新するkernelのvmlinuzファイルを選択してください"
	NEW_KERNEL=$(zenity --width 400 --file-selection --title "kernel image" --filename="./")
	if [ -z $NEW_KERNEL ]; then abort_install; fi
	zenity --info --width 400 --text "更新するkernelのmoduleフォルダを選択してください"
	NEW_KERNEL_LIB=$(zenity --width 400 --file-selection --title "kernel lib module" --directory --filename="./")
	if [ -z $NEW_KERNEL_LIB ]; then abort_install; fi
   fi
fi


if [ $VER_INST = "custom_image" ]; then
#houdini from Chrome OS  (Experimental option)
   zenity --info --width 400 --text "Houdini Binary TranslatorをChrome OSから導入するか選んでください。このオプションは非常に実験的です。<span color=\"red\">「no」を選択することを強く推奨します</span>。\nなお、インストール後にEnable native bridgeにチェックを入れることで有効化されます。\n種々の問題がある(可能性があります）ので、yesを選択する場合は<span color=\"red\">内容についての充分な理解のうえで自己責任でお使いください</span>。"
   ARM=$(zenity --list  --title "houdini" --text "" --column "select" no yes)
   if [ -z $ARM ]; then abort_install; fi
   if [ $ARM = "yes" ]; then
	zenity --info --width 600 --text "使用するChromeOS ISOイメージファイルを選択してください"
	CHROMEOS_FILENAME=$(zenity --width 400 --file-selection --title "select chromeOS ISO image")
	CHROMEOS_RECOVERY=$(echo "$CHROMEOS_FILENAME" | sed -e "s/.\{8\}$//")
	CHROMEOS_RECOVERY=$(basename "$CHROMEOS_RECOVERY")
	CHROMEOS_EXTRACTED="$CHROMEOS_RECOVERY.bin"
	CHROMEOS_ANDROID_VENDOR_IMAGE="chromeos/opt/google/containers/android/vendor.raw.img"
	if [ -z $CHROMEOS_FILENAME ]; then abort_install; fi
#houdini for arm32 (Experimental option)
	zenity --info --width 400 --text "armeabi-v7aに対応したHoudini Binary Translatorを有効化しますか？"
	ARM32=$(zenity --list  --title "armeabi-v7a" --text "" --column "select" no yes)
	if [ -z $ARM32 ]; then abort_install; fi
#houdini for arm64 (Experimental option)
	zenity --info --width 400 --text "arm64-v8aに対応したHoudini Binary Translatorを有効化しますか？"
	ARM64=$(zenity --list  --title "arm64-v8a" --text "" --column "select" no yes)
	if [ -z $ARM64 ]; then abort_install; fi
   fi
fi

#final confirmation
zenity --warning --width 400 --text "インストールの準備が完了しました。この最終確認以降はインストール作業をキャンセルすることはできません"
CONFIRMATION=$(zenity --list  --title "final confirmation" --text "最終確認です。インストール作業を開始してよろしいですか？" --column "select" yes no)
if [ -z ${CONFIRMATION} ]; then abort_install; fi
if [ ${CONFIRMATION} = "no" ]; then abort_install; fi

#official imageの確認及び取得
if [ $VER_INST = "9.0-r2(official)" ]; then
   LAN_REALTEK="EXTMOD=realtek"
   ANDROID_FILENAME="android-x86_64-9.0-r2.iso"
   ANDROID_SHA1="1cc85b5ed7c830ff71aecf8405c7281a9c995aa0 $SCRIPT/$ANDROID_FILENAME"
   ANDROID_URL="https://osdn.net/projects/android-x86/downloads/71931/android-x86_64-9.0-r2.iso/"
   ANDROID_ISO="$SCRIPT/$ANDROID_FILENAME"
#	echo $VER_INST
   if ! sha1sum -c <<< "$ANDROID_SHA1" 2> /dev/null; then
      if command -v wget &> /dev/null; then
        wget -O "$ANDROID_FILENAME" "$ANDROID_URL"
      else
        echo "This script requires 'wget' to download the Android-x86 OS image."
        echo "You can install one of them with the package manager provided by your distribution."
        echo "Alternatively, download $ANDROID_URL manually and place it in the current directory."
        exit 1
      fi
      sha1sum -c <<< "$ANDROID_SHA1"
   fi
fi

#android-x86用フォルダの作成
cd /
mkdir -p $ANDROID_INST_DIR

#ISOファイルの展開およびdataフォルダの作成
cd $ANDROID_INST_DIR
mkdir tmp
mount -o loop $ANDROID_ISO tmp
cp tmp/kernel .
cp tmp/initrd.img .
cp tmp/ramdisk.img .
unsquashfs tmp/system.sfs
umount tmp
mount -o loop squashfs-root/system.img tmp
cp -af -Z tmp system
umount tmp
mkdir data

#不要なフォルダの消去
cd $ANDROID_INST_DIR
rm -rf tmp
rm -rf squashfs-root

#Open Gappsの導入
if [ $GAPPS_INST = "yes" ]; then
	cd $ANDROID_INST_DIR
	mkdir tmp
	unzip $OPANGAPPS_ZIP -d tmp/
	cd tmp/
	mkdir unpacked
	find -name '*.tar.lz' | xargs -n 1 tar -px -C unpacked -f
	find unpacked/ -type f -exec chmod 644 {} +
	mkdir combined
	find unpacked/ -type f | xargs -n 1 -I@ sh -c 'cd `echo "@" | cut -d/ -f1-3`; file=`echo "@" | cut -d/ -f4-`; rsync -R $file ../../../combined; cd ../../../'
	rsync -r combined/ ${ANDROID_INST_DIR}/system
	rm -rf ${ANDROID_INST_DIR}/system/priv-app/GooglePackageInstaller
	rm -rf ${ANDROID_INST_DIR}/system/priv-app/SetupWizard
	cd $ANDROID_INST_DIR
	rm -rf tmp
fi

#kernelの更新
if [ $UPDATE_KERNEL = "yes" ]; then
	cd $ANDROID_INST_DIR
	mv kernel kernel.bak
	cp $NEW_KERNEL kernel
	cp -r $NEW_KERNEL_LIB system/lib/modules/
fi

#firmwareの更新
if [ $FIRM_INST = "yes" ]; then
	cd $ANDROID_INST_DIR
	rsync -avl $NEW_FIRM/ system/lib/firmware
fi

# houdiniの導入(from chrome os)
if [ $ARM = "yes" ]; then
   cd $ANDROID_INST_DIR

   temp_dir="$PWD/tmp32"
   mkdir "$temp_dir"
   cd "$temp_dir"

   echo " -> Extracting recovery image"
   unzip "$CHROMEOS_FILENAME"

   echo " -> Mounting partitions"
# Setup loop device
   loop_dev=$(sudo losetup -r -f --show --partscan "$CHROMEOS_EXTRACTED")

   mkdir chromeos
   sudo mount -r "${loop_dev}p3" chromeos
   mkdir vendor
   sudo mount -r "$CHROMEOS_ANDROID_VENDOR_IMAGE" vendor

# copy houdini files
   if [ $ARM32 = "yes" ]; then
	cp -af -Z $temp_dir/vendor/lib/libhoudini.so $ANDROID_INST_DIR/system/lib/
	cp -af -Z $temp_dir/vendor/lib/arm/ $ANDROID_INST_DIR/system/lib/
	cp -af -Z $temp_dir/vendor/bin/houdini $ANDROID_INST_DIR/system/bin/
   fi
   if [ $ARM64 = "yes" ]; then
	cp -af -Z $temp_dir/vendor/lib64/libhoudini.so $ANDROID_INST_DIR/system/lib64/
	cp -af -Z $temp_dir/vendor/lib64/arm64/ $ANDROID_INST_DIR/system/lib64/
	cp -af -Z $temp_dir/vendor/bin/houdini64 $ANDROID_INST_DIR/system/bin/
   fi
# Widevine DRM
   cp -af -Z $temp_dir/vendor/bin/hw/android.hardware.drm@1.1-service.widevine $ANDROID_INST_DIR/system/vendor/bin/hw/
   cp -af -Z $temp_dir/vendor/etc/init/android.hardware.drm@1.1-service.widevine.rc $ANDROID_INST_DIR/system/vendor/etc/init/
   cp -af -Z $temp_dir/vendor/lib/libwvhidl.so $ANDROID_INST_DIR/system/vendor/lib/
   
function cleanup32 {
    set +e
    cd "$temp_dir"
    mountpoint -q vendor && sudo umount vendor
    mountpoint -q chromeos && sudo umount chromeos
    [[ -n "${loop_dev:-}" ]] && sudo losetup -d "$loop_dev"
    rm -r "$temp_dir"
}
   trap cleanup32 EXIT

#build.propの設定変更
	if [ $ARM64 = "yes" ]; then
	   BUILD_PROP=$ANDROID_INST_DIR/system/build.prop
	   sed -i -e 's/abilist=x86_64,x86,armeabi-v7a,armeabi/abilist=x86_64,x86,arm64-v8a,armeabi-v7a,armeabi/' $BUILD_PROP
	   sed -i -e 's/abilist64=x86_64/abilist64=x86_64,arm64-v8a/' $BUILD_PROP
	fi
fi

#grubの設定
if [ $GRUB = "yes" ]; then
	##40_customに必要事項を追記
	GRUB_FILE=/etc/grub.d/40_custom
#	TITLE="Android-x86"
	echo "menuentry '"$TITLE"' {" >> $GRUB_FILE
	echo "search --no-floppy --fs-uuid --set=root" $UUIDNAME >> $GRUB_FILE
	echo "linux" $ANDROID_INST_DIR"/kernel quiet root=/dev/ram0 androidboot.selinux=permissive androidboot.hardware=android_x86_64 buildvariant=userdebug" $VULKAN $VIRT_WIFI $HWC $LAN_REALTEK "SRC="$ANDROID_INST_DIR >> $GRUB_FILE
	echo "initrd" $ANDROID_INST_DIR"/initrd.img" >> $GRUB_FILE
	echo "}" >> $GRUB_FILE
	##デフォルト設定ファイルを更新
	GRUB_DEF=/etc/default/grub
	sed -i -e '/TIMEOUT/d' $GRUB_DEF
	echo -e "\n""#setting GRUB_TIMEOUT, GRUB_TIMEOUT_STYLE" >> $GRUB_DEF
	echo "GRUB_TIMEOUT_STYLE=menu" >> $GRUB_DEF
	echo "GRUB_TIMEOUT=-1" >> $GRUB_DEF
	##grub.cfgの再構築
	update-grub
fi

#インストール終了
zenity --info --width 400 --text "Android-x86のインストール作業は終了しました"
