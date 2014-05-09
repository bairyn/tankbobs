#!/bin/bash

set -e

cd `dirname $0`

SERVER_SRCS="src/common/common.lua src/common/c_class.lua src/common/c_config.lua src/common/c_const.lua src/common/c_data.lua src/common/c_math.lua src/common/c_mods.lua src/common/c_module.lua src/common/c_state.lua src/common/c_files.lua src/common/c_tcm.lua src/common/c_weapon.lua src/common/c_ai.lua src/common/c_world.lua src/common/c_protocol.lua src/common/lom.lua src/server/init.lua src/server/main.lua src/server/commands.lua src/server/client.lua src/server/st_main.lua"
CLIENT_SRCS="src/common/common.lua src/common/c_class.lua src/common/c_config.lua src/common/c_const.lua src/common/c_data.lua src/common/c_math.lua src/common/c_mods.lua src/common/c_module.lua src/common/c_state.lua src/common/c_files.lua src/common/c_tcm.lua src/client/game.lua src/common/c_weapon.lua src/common/c_ai.lua src/common/c_world.lua src/common/c_protocol.lua src/common/lom.lua src/client/gui.lua src/client/init.lua src/client/main.lua src/client/renderer.lua src/client/st_exit.lua src/client/st_help.lua src/client/st_level.lua src/client/st_background.lua src/client/st_internet.lua src/client/st_online.lua src/client/st_options.lua src/client/st_play.lua src/client/st_selected.lua src/client/st_set.lua src/client/st_title.lua"
OPT_SRCS="src/lib/LuaJIT/jit/opt.lua src/lib/LuaJIT/jit/opt_inline.lua"
COPYDATA="mod-client mod-server"
VERSION=$(cat VERSION)
ZIPFLAGS="-9r"

# Files to copy to build directory.
DATAFILES="CHANGELOG COPYING NOTICE mod-client mod-server modules modules64 modules-win modules64-win data"
# Files to archive in optional binary distribution.
DISTFILES="CHANGELOG COPYING NOTICE mod-client mod-server modules modules64 modules-win modules64-win client server libmtankbobs.so libtstr.so jit data-tankbobs-v*-r*.tpk tankbobs* trmc*"

REVISION=$(git rev-list master | wc -l)
PAKNAME="data-tankbobs-v${VERSION}-r${REVISION}.tpk"
BUILDNAME="tankbobs-build-v${VERSION}-r${REVISION}.tar.gz"
CMAKEFLAGS="-D PEDANTIC=TRUE $OTHER_CMAKE_FLAGS"

LUAC=luac5.1

if ! [ -d "./build" ]; then
	mkdir ./build
fi

cd ./build

debug=0
nojit=0
cdist=0
phelp=0

while getopts dnth\? opt; do
	case $opt in
	d)
		debug=1
		;;
	n)
		nojit=1
		;;
	t)
		cdist=1
		;;
	h)
		phelp=1
		;;
	\?)
		phelp=1
		;;
	esac
done

if [ "$phelp" == 1 ]; then
  cat <<EOM
Build Tankbobs:

1) Compiles lua.
2) Compiles third party libraries.
3) Wraps cmake to build Tankbobs.
4) Copies data files to build directory.
5) Compiles maps.
6) Creates data archive containing compiled maps.
7) Optionally creates binary tarball containing the build.

Usage: $0 [-d] [-n] [-t] [MAKE ARGS]

Example: ./build.sh -d -n -t VERBOSE=1

-d: Enable debugging
-n: Disable Lua JIT
-t: Create binary tarball containing the build
EOM
	exit 1
fi

cd ./../

PHYSFS_CMAKE_FLAGS="-Wno-dev -DPHYSFS_BUILD_WX_TEST=FALSE $PHYSFS_CMAKE_FLAGS"
if [ $debug == 0 ]; then
	LUAFLAGS="$LUAFLAGS"
	BOX2D_CXXFLAGS="-O2 -fPIC $BOX2D_CXXFLAGS"
	TANKBOBS_CMAKE_FLAGS=" $PHYSFS_CMAKE_FLAGS"
	CMAKEFLAGS="-D CMAKE_BUILD_TYPE=Release $CMAKEFLAGS"
else
	LUAFLAGS="-s $LUAFLAGS"
	BOX2D_CXXFLAGS="-g -fPIC $BOX2D_CXXFLAGS"
	TANKBOBS_CMAKE_FLAGS=" $PHYSFS_CMAKE_FLAGS"
	CMAKEFLAGS="-D CMAKE_BUILD_TYPE=Debug $CMAKEFLAGS"
fi

if [ $nojit == 0 ]; then
	CMAKEFLAGS="-D NOJIT=False $CMAKEFLAGS"
else
	CMAKEFLAGS="-D NOJIT=True $CMAKEFLAGS"
fi

set -x
mkdir -p build

# Build lua.

$LUAC $LUAFLAGS -o ./build/server ${SERVER_SRCS}
$LUAC $LUAFLAGS -o ./build/client ${CLIENT_SRCS}


# Build dependencies.

## Box2D
make -C ./src/lib/Box2D/Source CXXFLAGS="$BOX2D_CXXFLAGS"

## LuaJIT
if [ $nojit == 0 ]; then
	make -C ./src/lib/LuaJIT linux
fi

## PhysFS
cd ./src/lib/physfs-2.0.0/
cmake $PHYSFS_CMAKE_FLAGS .
make -C .
cd $OLDPWD


# Call cmake for Tankbobs.

cd ./build/
cmake $CMAKEFLAGS ./../
make -C .
cd $OLDPWD


# Copy data files to build directory.
rm -fr ./build/data
cp -a -t ./build/ $DATAFILES


# Compile maps.
find ./build/data/tcm/ -name '*.trm' -exec ./build/trmc -f {} +
find ./build/data/tcm/ -name '*.trm' -exec rm              {} +


# Pack data archive.
cd ./build/data/
find .. -maxdepth 1 -name 'data-tankbobs-*.tpk' -exec rm {} +
zip $ZIPFLAGS "./../${PAKNAME}" *
cd $OLDPWD


# Optionally create binary tarball.
if [ $cdist == 1 ]; then
	cd ./build
	find . -maxdepth 1 -name 'tankbobs-build-*.tar.gz' -exec rm {} +
	tar -c -hz -f $BUILDNAME $(eval echo $DISTFILES)
	cd $OLDPWD
fi


exit
