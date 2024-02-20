#!/bin/zsh

set -e

cd "$(dirname "$0")"

function clangCommon
{
	clang -fmodules -dynamiclib -compatibility_version 1.0.0 -current_version 1.0.0 -mmacosx-version-min=12 $@
}

# setup

PATH+=:"$PWD/tools"

rm -rf wrapped
mkdir wrapped

# generate stubs for GS
# wrap monterey version to look like bs version (reverse)

Stubber input/GeoServices_monterey input/GeoServices_bs no_handwritten_shims wrapped/GeoServices_reverse_wrapper.m input/GeoServices_bs.json input/GeoServices_monterey.json wrapped/GeoServices_aliases.txt

# symtab temp again

ks input/GeoServices_monterey wrapped/GeoServices_monterey_no_symtab

# compile GS reverse wrapper

clangCommon -install_name /System/Library/PrivateFrameworks/VectorKit.framework/Versions/A/GeoServicesShim.dylib -Xlinker -reexport_library -Xlinker wrapped/GeoServices_monterey_no_symtab wrapped/GeoServices_reverse_wrapper.m -o wrapped/GeoServicesShim.dylib -Xlinker -alias_list -Xlinker wrapped/GeoServices_aliases.txt

# get VK

cp input/VectorKit_bs wrapped/VectorKitOld.dylib

# point VK at GS reverse shims

install_name_tool -change /System/Library/PrivateFrameworks/GeoServices.framework/Versions/A/GeoServices /System/Library/PrivateFrameworks/VectorKit.framework/Versions/A/GeoServicesShim.dylib wrapped/VectorKitOld.dylib

# update install name of old VK

install_name_tool -id /System/Library/PrivateFrameworks/VectorKit.framework/Versions/A/VectorKitOld.dylib wrapped/VectorKitOld.dylib

# generate stubs for VK
# wrap bs version to look like monterey version (normal)
# note fucked-up json order

Stubber input/VectorKit_bs input/VectorKit_monterey no_handwritten_shims wrapped/VectorKit_wrapper.m input/VectorKit_monterey.json input/VectorKit_bs.json wrapped/VectorKit_aliases.txt

# hack symtab (won't be needed after dscev8 fixed)

ks wrapped/VectorKitOld.dylib wrapped/VectorKitOld.dylib

# compile VK wrapper

clangCommon -install_name System/Library/PrivateFrameworks/VectorKit.framework/Versions/A/VectorKit -Xlinker -reexport_library -Xlinker wrapped/VectorKitOld.dylib wrapped/VectorKit_wrapper.m -o wrapped/VectorKit -Xlinker -alias_list -Xlinker wrapped/VectorKit_aliases.txt

# codesign

codesign -fs - wrapped/VectorKitOld.dylib
codesign -fs - wrapped/VectorKit
codesign -fs - wrapped/GeoServicesShim.dylib

echo DONE