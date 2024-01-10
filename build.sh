#!/usr/bin/sh
set -xe
FOLDER_NAME="path_tracer"
LINUX_PATH="/mnt/c/Dev/code/$FOLDER_NAME"
WIN_PATH="C:\\Dev\\code\\$FOLDER_NAME\\"
ODIN_FLAGS=" -o:speed -disable-assert -no-bounds-check "
ODIN_FLAGS=""

CMD_DEV="odin run src $ODIN_FLAGS"

CMD_DEBUG="odin run src -debug -vet-unused -vet-shadowing -warnings-as-errors"
CMD_RELEASE="odin run src -o:speed -disable-assert -no-bounds-check -microarch:native"

rm -rf "$LINUX_PATH"
cp -rf . "$LINUX_PATH"



CMD=$CMD_DEV
CMD=$CMD_RELEASE
$CMD

# Before "-command" you can add "-noexit" with no quotes
# to stay in powershell shell

powershell.exe  -command "cd $WIN_PATH; $CMD"  

