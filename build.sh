#!/usr/bin/sh
FOLDER_NAME="path_tracer"
LINUX_PATH="/mnt/c/Dev/code/$FOLDER_NAME"
WIN_PATH="C:\\Dev\\code\\$FOLDER_NAME\\"
ODIN_FLAGS=" -o:speed -disable-assert -no-bounds-check -no-thread-local "

CMD_DEV="odin run src $ODIN_FLAGS"

CMD_DEBUG="odin build src -debug -vet-unused -vet-shadowing -warnings-as-errors -out:a.debug.exe"
CMD_RELEASE="odin build src -o:speed -disable-assert -no-bounds-check -microarch:native -obfuscate-source-code-locations -out:release"

cp -rf . "$LINUX_PATH"


CMD=$CMD_RELEASE

CMD=$CMD_DEV
$CMD

# Before "-command" you can add "-noexit" with no quotes
# to stay in powershell shell

powershell.exe  -command "cd $WIN_PATH; $CMD"  

