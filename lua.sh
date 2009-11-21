#!/bin/sh
find .. | grep -i "\.lua\$" | grep -vi "Box2D" | grep -vi "git" | grep -vi "CMakeC" | grep -vi "qrc" | grep -vi "moc_" | grep -vi "ui_" | grep -vi "build" | grep -vi "summary.lua" | xargs wc -l
