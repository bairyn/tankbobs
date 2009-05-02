#!/bin/sh

# wrapper for cmake
# use ./build.sh make etc

skipBaseDirCheck=0  # change this to one to stop checking for "tankbobs" as the basename of pwd

SERVER_SRCS="src/common/common.lua src/common/c_config.lua src/common/c_const.lua src/common/c_data.lua src/common/c_math.lua src/common/c_mods.lua src/common/c_module.lua src/common/c_state.lua src/common/c_tcm.lua src/common/c_weapon.lua src/common/c_world.lua src/common/lom.lua src/server/init.lua"
CLIENT_SRCS="src/common/common.lua src/common/c_config.lua src/common/c_const.lua src/common/c_data.lua src/common/c_math.lua src/common/c_mods.lua src/common/c_module.lua src/common/c_state.lua src/common/c_tcm.lua src/common/c_weapon.lua src/common/c_world.lua src/common/lom.lua src/client/gui.lua src/client/init.lua src/client/main.lua src/client/renderer.lua src/client/st_exit.lua src/client/st_help.lua src/client/st_level.lua src/client/st_license.lua src/client/st_manual.lua src/client/st_options.lua src/client/st_play.lua src/client/st_set.lua src/client/st_start.lua src/client/st_title.lua"
DATA="CHANGELOG COPYING data mod-client mod-server NOTICE"

if [ `basename ${PWD}` == "build" ]; then
	cd ./../
fi

if [ $skipBaseDirCheck == 0 ]; then
	if ! [ `basename ${PWD}` == "tankbobs" ]; then
		if [ "$1" == "-f" ]; then
			shift
		else
			echo -ne "Not in "tankbobs/".  Use -f as the first argument to conitune anyway\n"
			exit 1
		fi
	fi
fi

if [ -e "/usr/bin/gcc" ]; then
	# try to link with C compiler
	CMAKEFLAGS="-D PEDANTIC=TRUE -D CMAKE_CXX_LINKER=/usr/bin/gcc"
else
	CMAKEFLAGS="-D PEDANTIC=TRUE"
fi

if ! [ -d "./build" ]; then
	mkdir ./build
fi

cd ./build

debug=0
skipc=0

if [ "$1" == "-d" ]; then
	debug=1
	shift
fi

if [ "$1" == "-n" ]; then
	skipc=1
	shift
fi

if [ "$1" == "-d" ]; then
	debug=1
	shift
fi

if [ "$1" == "make" ]; then
	arg_1=$1

	cd ./../

	# build lua manually
	if [ $debug == 0 ]; then
		if ! luac -s -o ./build/server ${SERVER_SRCS}; then
			exit 1
		fi
		if ! luac -s -o ./build/client ${CLIENT_SRCS}; then
			exit 1
		fi
	else
		if ! luac -o ./build/server ${SERVER_SRCS}; then
			exit 1
		fi
		if ! luac -o ./build/client ${CLIENT_SRCS}; then
			exit 1
		fi
	fi

	# build Box2D manually
	make -C ./src/lib/Box2D/Source

	# build tankbobs
	cd ./build/
	if [ $skipc == 0 ]; then
		if [ $debug == 0 ]; then
			if ! cmake -D CMAKE_BUILD_TYPE=Release ${CMAKEFLAGS} ./../; then
				exit 1
			fi
		else
			if ! cmake -D CMAKE_BUILD_TYPE=Debug ${CMAKEFLAGS} ./../; then
				exit 1
			fi
		fi
	fi

	# copy data
	cd ./../
	cp -R --preserve=all -t ./build/ ${DATA}

	cd ./build/

	# make it
	if ! eval $*; then
		exit 1
	fi

	# compile maps
	if [ -f "./trmc" ] && [ -d "./data/tcm/" ]; then
		if ! find ./data/tcm/ -name "*.trm" -exec ./trmc -f {} +; then
			exit 1
		fi
	else
		echo -ne "Warning: level compiler not built\n"
	fi
elif [ "$1" == "-h" ]; then
	echo -ne "Usage: $0 (-d to debug) (-n to skip cmake) make options\nuse make VERBOSE=1 for verbose output\n"
else
	# just cmake

	if [ $skipc == 0 ]; then
		if [ $debug == 0 ]; then
			if ! cmake -D CMAKE_BUILD_TYPE=Release ${CMAKEFLAGS} ./../; then
				exit 1
			fi
		else
			if ! cmake -D CMAKE_BUILD_TYPE=Debug ${CMAKEFLAGS} ./../; then
				exit 1
			fi
		fi
	fi
fi
