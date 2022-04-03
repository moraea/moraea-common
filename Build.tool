#!/bin/zsh

set -e
cd "$(dirname "$0")"

function build
{
	clang -fmodules -I Utils -Wno-unused-getter-return-value -Wno-objc-missing-super-calls Tools/$1.m -o Build/$1
}

rm -rf Build
mkdir Build

build Stubber
build StubberObjcHelper
build Renamer
build Binpatcher