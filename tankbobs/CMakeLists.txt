cmake_minimum_required(VERSION 2.6)
project(tankbobs)

if(UNIX)
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Werror -Wno-strict-aliasing -fPIC -pedantic-errors -pthread -std=c99")
	#set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC -Wall -Werror -pedantic-errors -ansi")  # Box2D
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pthread -fPIC")  # Box2D
else(UNIX)
	if(MSVC)
		set(CMAKE_C_FLAGS_DEBUG_INIT "/D TDEBUG /MTd /Zi /Ob0 /Od /RTC1")
		set(CMAKE_C_FLAGS_MINSIZEREL_INIT "/MT /O1 /Ob1")
		set(CMAKE_C_FLAGS_RELEASE_INIT "/MT /O2 /Ob2")
		set(CMAKE_C_FLAGS_RELWITHDEBINFO_INIT "/MT /Zi /O2 /Ob1")
	endif(MSVC)
endif(UNIX)

if(CMAKE_BUILD_TYPE MATCHES Debug)
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -g -DTDEBUG")
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g -DTDEBUG")
else(CMAKE_BUILD_TYPE MATCHES Debug)
	if(UNIX)
		set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O3")
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3")
	endif(UNIX)
endif(CMAKE_BUILD_TYPE MATCHES Debug)

if(NOJIT MATCHES True)
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DNOJIT")
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DNOJIT")
else(NOJIT MATCHES True)
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DLUA_USE_LINUX")
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DLUA_USE_LINUX")
endif(NOJIT MATCHES True)

if(NOJIT MATCHES True)
	set(include_dirs /usr/include/SDL ./src/lib ./src/lib/tstr ./src/common ./src/lib/Box2D/Include src/lib/physfs-2.0.0 src/lib/physfs-2.0.0/extras /usr/include/lua /usr/include/lua5.1)
else(NOJIT MATCHES True)
	set(include_dirs /usr/include/SDL ./src/lib ./src/lib/tstr ./src/common ./src/lib/Box2D/Include src/lib/physfs-2.0.0 src/lib/physfs-2.0.0/extras ./src/lib/LuaJIT/src)
endif(NOJIT MATCHES True)

include_directories(${include_dirs})

set(trmc_srcs src/trmc/trmc.c)
if(UNIX)
	set(trmc_libs m)
endif(UNIX)

set(tankbobs_srcs src/common/m_input.c src/common/m_fs.c src/common/m_io.c src/common/m_math.c src/common/m_console.c src/common/m_renderer.c src/common/m_net.c src/common/m_audio.c src/common/m_tankbobs.c src/lib/crossdll.c src/lib/physfs-2.0.0/extras/physfsrwops.c)
set(tankbobs_Box2D_srcs src/common/m_world.cpp)
if(WIN32)
	set(tankbobs_libs lua51.lib SDL SDL_mixer SDL_image SDL_ttf SDL_net.lib OpenGL32.lib glu32.lib box2d.lib physfs.lib libpng.lib freetype.lib zlib.lib)
else(WIN32)
	set(tankbobs_libs lua.a SDL SDL_mixer SDL_image SDL_ttf SDL_net.a GL GLU box2d.a physfs.a png.a freetype m z dl ncurses)
endif(WIN32)
if(NOJIT MATCHES True)
	set(tankbobs_libdirs ../src/lib/Box2D/Source/Gen/float ../src/lib/physfs-2.0.0)
	#set(tankbobs_libdirs ../src/lib/Box2D/Source/Gen/fixed ../src/lib/physfs-2.0.0)  # FIXME: why does linking with this cause linker errors?; TODO
else(NOJIT MATCHES True)
	set(tankbobs_libdirs ../src/lib/Box2D/Source/Gen/float ../src/lib/physfs-2.0.0 ../src/lib/LuaJIT/src)
	#set(tankbobs_libdirs ../src/lib/Box2D/Source/Gen/fixed ../src/lib/physfs-2.0.0 ../src/lib/LuaJIT/src)  # FIXME: why does linking with this cause linker errors?; TODO
endif(NOJIT MATCHES True)

set(client_srcs src/client/client.c)
if(NOJIT MATCHES True)
	set(client_libdirs)
else(NOJIT MATCHES True)
	set(client_libdirs ../src/lib/LuaJIT/src)
endif(NOJIT MATCHES True)

set(server_srcs src/server/server.c)
if(NOJIT MATCHES True)
	set(server_libdirs)
else(NOJIT MATCHES True)
	set(server_libdirs ../src/lib/LuaJIT/src)
endif(NOJIT MATCHES True)

if(UNIX)
	set(client_libs lua.a m z dl physfs.a)
	set(server_libs lua.a m z dl physfs.a)
else(UNIX)
	set(client_libs lua51.lib zlib.lib physfs.lib)
	set(server_libs lua51.lib zlib.lib physfs.lib)
endif(UNIX)

if(WIN32)
	set(tstr_libs strsafe.lib)
endif(WIN32)
	
set(tstr_srcs src/lib/tstr/tstr.c)

add_executable(trmc ${trmc_srcs})
target_link_libraries(trmc ${trmc_libs})

link_directories(${tankbobs_libdirs})
add_library(mtankbobs SHARED ${tankbobs_srcs} ${tankbobs_Box2D_srcs})
target_link_libraries(mtankbobs ${tankbobs_libs})

link_directories(${client_libdirs})
add_executable(tankbobs ${client_srcs})
target_link_libraries(tankbobs ${client_libs})

link_directories(${server_libdirs})
add_executable(tankbobs-server ${server_srcs})
target_link_libraries(tankbobs-server ${server_libs})

add_library(tstr SHARED ${tstr_srcs})
target_link_libraries(tstr ${tstr_libs})
