cmake_minimum_required(VERSION 2.6)
project(tankbobs)

set(include_dirs ./src/lib ./src/lib/tstr ./src/common ./src/lib/Box2D/Include /usr/include/lua5.1)

include_directories(${include_dirs})

set(trmc_srcs src/trmc/trmc.c)

add_executable(trmc ${trmc_srcs})

set(tankbobs_srcs src/common/m_input.c src/common/m_io.c src/common/m_math.c src/common/m_renderer.c src/common/m_world.cpp src/common/m_tankbobs.c src/lib/crossdll.c)

add_library(mtankbobs SHARED ${tankbobs_srcs})
target_link_libraries(mtankbobs lua5.1 SDL SDL_mixer SDL_image freetype GL GLU z)

set(client_srcs src/client/client.c)

add_executable(tankbobs ${client_srcs})
target_link_libraries(tankbobs lua5.1)

set(server_srcs src/server/server.c)

add_executable(tankbobs-server ${server_srcs})
target_link_libraries(tankbobs-server lua5.1)

set(tstr_srcs src/lib/tstr/tstr.c)

add_library(tstr ${tstr_srcs})
