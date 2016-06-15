#!/bin/sh
cd `dirname $0`
find . | grep -i "\.\(lua\|c\|cpp\|h\)\$" | grep -vi "SDL_net-1.2.8" | grep -vi "Box2D" | grep -vi "git" | grep -vi "CMakeC" | grep -vi "qrc" | grep -vi "moc_" | grep -vi "ui_" | grep -vi "build" | grep -vi "physfs" | grep -vi "summary.lua" | grep -vi "LuaJIT" | grep -vi "posix" | xargs wc -l
