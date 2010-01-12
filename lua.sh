#!/bin/sh
cd `dirname $0`
find .. | grep -i "\.lua\$" | grep -vi "Box2D" | grep -vi "git" | grep -vi "CMakeC" | grep -vi "qrc" | grep -vi "moc_" | grep -vi "ui_" | grep -vi "build" | grep -vi "physfs" | grep -vi "summary.lua" | grep -vi "posix" | xargs wc -l
