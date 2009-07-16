#!/bin/sh

# wrapper for cmake
# use ./build.sh make etc

SERVER_SRCS="src/common/common.lua src/common/c_class.lua src/common/c_config.lua src/common/c_const.lua src/common/c_data.lua src/common/c_math.lua src/common/c_mods.lua src/common/c_module.lua src/common/c_state.lua src/common/c_tcm.lua src/common/c_weapon.lua src/common/c_world.lua src/common/lom.lua src/server/init.lua src/server/main.lua src/server/commands.lua src/server/client.lua src/server/st_main.lua"
CLIENT_SRCS="src/common/common.lua src/common/c_class.lua src/common/c_config.lua src/common/c_const.lua src/common/c_data.lua src/common/c_math.lua src/common/c_mods.lua src/common/c_module.lua src/common/c_state.lua src/common/c_tcm.lua src/common/c_weapon.lua src/common/c_world.lua src/common/lom.lua src/client/gui.lua src/client/init.lua src/client/main.lua src/client/renderer.lua src/client/st_exit.lua src/client/st_help.lua src/client/st_level.lua src/client/st_internet.lua src/client/st_online.lua src/client/st_manual.lua src/client/st_options.lua src/client/st_play.lua src/client/st_selected.lua src/client/st_set.lua src/client/st_title.lua"
OPT_SRCS="src/lib/LuaJIT/jit/opt.lua src/lib/LuaJIT/jit/opt_inline.lua"
DATA="CHANGELOG COPYING data mod-client mod-server NOTICE"

cd `dirname $0`

CMAKEFLAGS="-D PEDANTIC=TRUE"

if ! [ -d "./build" ]; then
	mkdir ./build
fi

cd ./build

debug=0
skipc=0
nojit=0

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

if [ "$1" == "-o" ]; then
	nojit=1
	shift
fi

if [ "$1" == "make" ]; then
	arg_1=$1

	cd ./../

	# build lua manually
	if [ $debug == 0 ]; then
		echo "luac -s -o ./build/server ${SERVER_SRCS}"
		if ! luac -s -o ./build/server ${SERVER_SRCS}; then
			exit 1
		fi
		echo "luac -s -o ./build/server ${CLIENT_SRCS}"
		if ! luac -s -o ./build/client ${CLIENT_SRCS}; then
			exit 1
		fi
	else
		echo "luac -o ./build/server ${SERVER_SRCS}"
		if ! luac -o ./build/server ${SERVER_SRCS}; then
			exit 1
		fi
		echo "luac -o ./build/server ${CLIENT_SRCS}"
		if ! luac -o ./build/client ${CLIENT_SRCS}; then
			exit 1
		fi
	fi

	# build Box2D and luaJIT manually
	if [ $debug == 0 ]; then
		make -C ./src/lib/Box2D/Source CXXFLAGS="-O2 -fPIC"
		make -C ./src/lib/LuaJIT linux
		if ! [ -d "./build/jit" ]; then
			mkdir ./build/jit
		fi
		cp ./src/lib/LuaJIT/jit/opt.lua ./build/jit/
		cp ./src/lib/LuaJIT/jit/opt_inline.lua ./build/jit/
	else
		make -C ./src/lib/Box2D/Source CXXFLAGS="-g -fPIC"
		make -C ./src/lib/LuaJIT linux CFLAGS="-DLUAJIT_ASSERT -DLUA_USE_APICHECK -DUSE_VALGRIND -g -fomit-frame-pointer -Wall -DLUA_USE_LINUX -I../dynasm"
		if ! [ -d "./build/jit" ]; then
			mkdir ./build/jit
		fi
		cp ./src/lib/LuaJIT/jit/opt.lua ./build/jit/
		cp ./src/lib/LuaJIT/jit/opt_inline.lua ./build/jit/
	fi

	# build tankbobs
	cd ./build/
	if [ $skipc == 0 ]; then
		if [ $debug == 0 ]; then
			if [ $nojit == 0 ]; then
				if ! cmake -D CMAKE_BUILD_TYPE=Release -D NOJIT=False ${CMAKEFLAGS} ./../; then
					exit 1
				fi
			else
				if ! cmake -D CMAKE_BUILD_TYPE=Release -D NOJIT=True ${CMAKEFLAGS} ./../; then
					exit 1
				fi
			fi
		else
			if [ $nojit == 0 ]; then
				if ! cmake -D CMAKE_BUILD_TYPE=Debug -D NOJIT=False ${CMAKEFLAGS} -D TDEBUG=TRUE ./../; then
					exit 1
				fi
			else
				if ! cmake -D CMAKE_BUILD_TYPE=Debug -D NOJIT=True ${CMAKEFLAGS} -D TDEBUG=TRUE ./../; then
					exit 1
				fi
			fi
		fi
	fi

	cd ./../

	# remove old data
	rm ./build/data/*

	# copy data
	cp -R --preserve=all -t ./build/ ${DATA}

	cd ./build/

	# make it
	if ! eval $*; then
		exit 1
	fi

	# compile maps
	if [ -f "./trmc" ] && [ -d "./data/tcm/" ]; then
		echo -ne "./trmc -f" `find ./data/tcm/ -name "*.trm"`"\n"
		if ! find ./data/tcm/ -name "*.trm" -exec ./trmc -f {} +; then
			exit 1
		fi

		echo -ne "rm" `find ./data/tcm/ -name "*.trm"`"\n"
		# remove source maps
		if ! find ./data/tcm/ -name "*.trm" -exec rm {} +; then
			exit 1
		fi
	else
		echo -ne "Warning: level compiler not built\n"
	fi
elif [ "$1" == "-h" ]; then
	echo -ne "Usage: $0 (-d to debug) (-n to skip cmake) (-o to disable jit) make (options)\nUse make VERBOSE=1 for verbose output\nOptions need to be in order\n"
else
	# just cmake

	if [ $skipc == 0 ]; then
		if [ $debug == 0 ]; then
			if [ $nojit == 0 ]; then
				if ! cmake -D CMAKE_BUILD_TYPE=Release -D NOJIT=False ${CMAKEFLAGS} ./../; then
					exit 1
				fi
			else
				if ! cmake -D CMAKE_BUILD_TYPE=Release -D NOJIT=True ${CMAKEFLAGS} ./../; then
					exit 1
				fi
			fi
		else
			if [ $nojit == 0 ]; then
				if ! cmake -D CMAKE_BUILD_TYPE=Debug -D NOJIT=False ${CMAKEFLAGS} ./../; then
					exit 1
				fi
			else
				if ! cmake -D CMAKE_BUILD_TYPE=Release -D NOJIT=True ${CMAKEFLAGS} ./../; then
					exit 1
				fi
			fi
		fi
	fi
fi
