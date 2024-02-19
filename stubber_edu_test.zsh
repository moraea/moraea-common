set -e
cd "$(dirname "$0")"

zsh Build.tool
clang -fmodules stubber_edu_kill_symtab.m -o Build/ks

PATH+=:"$PWD/Build"

cd ~/Desktop/GeoServices
Stubber GeoServices_current GeoServices_old . out.m GeoServices_old.json GeoServices_current.json aliases.txt

ks GeoServices_current GeoServices_current_no_symtab

clang -fmodules -dynamiclib out.m -Xlinker -reexport_library -Xlinker GeoServices_current_no_symtab -Xlinker -alias_list -Xlinker aliases.txt -o out.dylib

echo done