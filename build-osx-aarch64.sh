#!/bin/bash

set -e

SIGNING_IDENTITY="F60F427F725F23E7224489A912A0D1661A129C48"

pushd native
cmake -DCMAKE_OSX_ARCHITECTURES=arm64 -B build-aarch64 .
cmake --build build-aarch64 --config Release
popd

source .jdk-versions.sh

rm -rf build/macos-aarch64
mkdir -p build/macos-aarch64

if ! [ -f mac_aarch64_jre.tar.gz ] ; then
    curl -Lo mac_aarch64_jre.tar.gz $MAC_AARCH64_LINK
fi

echo "$MAC_AARCH64_CHKSUM  mac_aarch64_jre.tar.gz" | shasum -c

# packr requires a "jdk" and pulls the jre from it - so we have to place it inside
# the jdk folder at jre/
if ! [ -d osx-aarch64-jdk ] ; then
    tar zxf mac_aarch64_jre.tar.gz
    mkdir osx-aarch64-jdk
    mv jdk-$MAC_AARCH64_VERSION-jre osx-aarch64-jdk/jre

    pushd osx-aarch64-jdk/jre
    # Move JRE out of Contents/Home/
    mv Contents/Home/* .
    # Remove unused leftover folders
    rm -rf Contents
    popd
fi

APPBASE="build/macos-aarch64/Torva.app"

mkdir -p $APPBASE/Contents/{MacOS,Resources}

cp native/build-aarch64/src/Torva $APPBASE/Contents/MacOS/
cp target/Torva.jar $APPBASE/Contents/Resources/
cp packr/macos-aarch64-config.json $APPBASE/Contents/Resources/config.json
cp target/filtered-resources/Info.plist $APPBASE/Contents/
cp osx/app.icns $APPBASE/Contents/Resources/icons.icns

tar zxf mac_aarch64_jre.tar.gz
mkdir $APPBASE/Contents/Resources/jre
mv jdk-$MAC_AARCH64_VERSION-jre/Contents/Home/* $APPBASE/Contents/Resources/jre

echo Setting world execute permissions on Torva
pushd $APPBASE
chmod g+x,o+x Contents/MacOS/Torva
popd

codesign -f -s "${SIGNING_IDENTITY}" --entitlements osx/signing.entitlements --options runtime $APPBASE || true

# create-dmg exits with an error code due to no code signing, but is still okay
create-dmg $APPBASE . || true
mv Torva\ *.dmg Torva-aarch64.dmg

# Notarize app
if xcrun notarytool submit Torva-aarch64.dmg --wait --keychain-profile "07c13e1cb5" ; then
    xcrun stapler staple Torva-aarch64.dmg
fi