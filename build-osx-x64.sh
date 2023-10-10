#!/bin/bash

set -e

SIGNING_IDENTITY="F60F427F725F23E7224489A912A0D1661A129C48"

pushd native
cmake -DCMAKE_OSX_ARCHITECTURES=x86_64 -B build-x64 .
cmake --build build-x64 --config Release
popd

source .jdk-versions.sh

rm -rf build/macos-x64
mkdir -p build/macos-x64

if ! [ -f mac64_jre.tar.gz ] ; then
    curl -Lo mac64_jre.tar.gz $MAC_AMD64_LINK
fi

echo "$MAC_AMD64_CHKSUM  mac64_jre.tar.gz" | shasum -c

APPBASE="build/macos-x64/Torva.app"

mkdir -p $APPBASE/Contents/{MacOS,Resources}

cp native/build-x64/src/Torva $APPBASE/Contents/MacOS/
cp target/Torva.jar $APPBASE/Contents/Resources/
cp packr/macos-x64-config.json $APPBASE/Contents/Resources/config.json
cp target/filtered-resources/Info.plist $APPBASE/Contents/
cp osx/app.icns $APPBASE/Contents/Resources/icons.icns

tar zxf mac64_jre.tar.gz
mkdir $APPBASE/Contents/Resources/jre
mv jdk-$MAC_AMD64_VERSION-jre/Contents/Home/* $APPBASE/Contents/Resources/jre

echo Setting world execute permissions on Torva
pushd $APPBASE
chmod g+x,o+x Contents/MacOS/Torva
popd

codesign -f -s "${SIGNING_IDENTITY}" --entitlements osx/signing.entitlements --options runtime $APPBASE || true

# create-dmg exits with an error code due to no code signing, but is still okay
# note we use Adam-/create-dmg as upstream does not support UDBZ
create-dmg --format UDBZ $APPBASE . || true
mv Torva\ *.dmg Torva-x64.dmg

if ! hdiutil imageinfo Torva-x64.dmg | grep -q "Format: UDBZ" ; then
    echo "Format of resulting dmg was not UDBZ, make sure your create-dmg has support for --format"
    exit 1
fi

# Notarize app
if xcrun notarytool submit Torva-x64.dmg --wait --keychain-profile "07c13e1cb5" ; then
    xcrun stapler staple Torva-x64.dmg
fi