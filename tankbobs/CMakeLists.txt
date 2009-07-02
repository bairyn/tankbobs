cmake_minimum_required(VERSION 2.6)
project(tankbobs)

if(UNIX)
	set(CMAKE_C_FLAGS ${CMAKE_C_FLAGS} -ansi)
	set(CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS} -ansi)
endif(UNIX)

set(include_dirs ./src/lib ./src/lib/tstr ./src/common ./src/lib/Box2D/Include /usr/include/lua)

include_directories(${include_dirs})

set(trmc_srcs src/trmc/trmc.c)

set_source_files_properties(${trmc_srcs} PROPERTIES COMPILE_FLAGS "-Wall -Werror -pedantic-errors -ansi")

add_executable(trmc ${trmc_srcs})

set(tankbobs_srcs src/common/m_input.c src/common/m_io.c src/common/m_math.c src/common/m_console.c src/common/m_renderer.c src/common/m_net.c src/common/m_audio.c src/common/m_tankbobs.c src/lib/crossdll.c)
set(tankbobs_Box2D_srcs src/common/m_world.cpp)
if(WIN32)
	set(tankbobs_libs lua SDL SDL_mixer SDL_image SDL_ttf SDL_net GL GLU z box2d m pdcurses)
else(WIN32)
	set(tankbobs_libs lua SDL SDL_mixer SDL_image SDL_ttf SDL_net GL GLU z box2d m ncurses)
endif(WIN32)
set(tankbobs_libdirs ../src/lib/Box2D/Source/Gen/float)

if(CMAKE_BUILD_TYPE MATCHES Debug)
	add_definitions(-DTDEBUG)
endif(CMAKE_BUILD_TYPE MATCHES Debug)

set_source_files_properties(${tankbobs_srcs} PROPERTIES COMPILE_FLAGS "-Wall -Werror -pedantic-errors -ansi")

link_directories(${tankbobs_libdirs})
add_library(mtankbobs SHARED ${tankbobs_srcs} ${tankbobs_Box2D_srcs})
target_link_libraries(mtankbobs ${tankbobs_libs})

set(client_srcs src/client/client.c)

add_executable(tankbobs ${client_srcs})
target_link_libraries(tankbobs lua m)

set(server_srcs src/server/server.c)

add_executable(tankbobs-server ${server_srcs})
target_link_libraries(tankbobs-server lua m)

set(tstr_srcs src/lib/tstr/tstr.c)

add_library(tstr SHARED ${tstr_srcs})
