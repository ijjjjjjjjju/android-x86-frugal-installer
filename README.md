# android-x86-frugal-installer
Android-x86(pie-x86) installer for frugal install

android-x86を他のLinux環境上にいわゆるfrugal installします。**pie-x86のみ**に対応しています。

なお動作確認はUbuntu 20.04.1 LTS環境で行っています。他の環境でも動作する可能性はありますが未確認です。

作業内容は以下となります。

・android-x86のフォルダの作成

・android-x86 ISOイメージの展開(標準のHoudini Binary Translatorの導入)

・起動用grubの設定

以下はオプションです。通常は必要ありません。理解している場合のみ行ってください

・OpenGappsの導入

・Linux firmwareの更新

・Linux kernelの更新

・ChromeOS由来のarmeabi-v7a及びarm64-v8a対応Houdini Binary Translatorの導入(非常に実験的)




必要な事前準備

・Android-x86のISOイメージ

9.0-r2(officail)をインストールする場合は、本scriptと同じフォルダにISOファイルをおいてください。

存在しない場合は、OSDNから自動的にダウンロードして使用します。

custom imageを使用する場合は、配置場所は自由です。

・android-x86をインストールするパーティションのUUIDの確認



オプション(通常は不要です)

・ChromeOSのリカバリーイメージ

配置場所は自由です。

・kernelの更新ファイル

・linux kernel firmwareの更新ファイル

・Opengappsのzipファイル

kernelおよびfirmwareについてはインストール作業前に圧縮ファイルを展開しておいてください

また、OpenGappsを導入する場合は、事前にlzipを導入してください

sudo apt install lzip

