@echo off

:: 64-bit version
mkdir _obj-lib-etc-win64
cd _obj-lib-etc-win64

cmake ../ -G "Visual Studio 17 2022" -A x64

cd ..