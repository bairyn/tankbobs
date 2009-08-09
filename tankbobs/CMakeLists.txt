cmake_minimum_required(VERSION 2.6)
project(tankbobs)

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Werror -pedantic-errors -std=c99")
#set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Werror -pedantic-errors -ansi")  # Box2D
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")  # Box2D

if(CMAKE_BUILD_TYPE MATCHES Debug)
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -g -DTDEBUG")
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g -DTDEBUG")
else(CMAKE_BUILD_TYPE MATCHES Debug)
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O3")
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3")
endif(CMAKE_BUILD_TYPE MATCHES Debug)

if(NOJIT MATCHES True)
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DNOJIT")
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DNOJIT")
else(NOJIT MATCHES True)
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DLUA_USE_LINUX")
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DLUA_USE_LINUX")
endif(NOJIT MATCHES True)

if(NOJIT MATCHES True)
	set(include_dirs ./src/lib ./src/lib/tstr ./src/common ./src/lib/Box2D/Include /usr/include/lua)
else(NOJIT MATCHES True)
	set(include_dirs ./src/lib ./src/lib/tstr ./src/common ./src/lib/Box2D/Include ./src/lib/LuaJIT/src)
endif(NOJIT MATCHES True)

include_directories(${include_dirs})

set(trmc_srcs src/trmc/trmc.c)

set(tankbobs_srcs src/common/m_input.c src/common/m_io.c src/common/m_math.c src/common/m_console.c src/common/m_renderer.c src/common/m_net.c src/common/m_audio.c src/common/m_tankbobs.c src/lib/crossdll.c)
set(tankbobs_Box2D_srcs src/common/m_world.cpp)
if(WIN32)
	set(tankbobs_libs lua SDL SDL_mixer SDL_image SDL_ttf SDL_net GL GLU box2d m dl pdcurses)
else(WIN32)
	set(tankbobs_libs lua SDL SDL_mixer SDL_image SDL_ttf SDL_net GL GLU box2d m dl ncurses)
endif(WIN32)
if(NOJIT MATCHES True)
	set(tankbobs_libdirs ../src/lib/Box2D/Source/Gen/float)
else(NOJIT MATCHES True)
	set(tankbobs_libdirs ../src/lib/Box2D/Source/Gen/float ../src/lib/LuaJIT/src)
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

set(tstr_srcs src/lib/tstr/tstr.c)

add_executable(trmc ${trmc_srcs})

link_directories(${tankbobs_libdirs})
add_library(mtankbobs SHARED ${tankbobs_srcs} ${tankbobs_Box2D_srcs})
target_link_libraries(mtankbobs ${tankbobs_libs})

link_directories(${client_libdirs})
add_executable(tankbobs ${client_srcs})
target_link_libraries(tankbobs lua m dl)

link_directories(${server_libdirs})
add_executable(tankbobs-server ${server_srcs})
target_link_libraries(tankbobs-server lua m dl)

add_library(tstr SHARED ${tstr_srcs})
