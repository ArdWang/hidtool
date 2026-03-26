#!/bin/bash

# macOS build script for hidapi library
# This script builds the hidapi library for macOS

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BUILD_DIR="${SCRIPT_DIR}/build"
INSTALL_DIR="${SCRIPT_DIR}/dist"

echo "Building hidapi for macOS..."

mkdir -p "${BUILD_DIR}"
mkdir -p "${INSTALL_DIR}"

# Check if Xcode is installed
if ! command -v clang &> /dev/null; then
    echo "Error: Xcode command line tools not found"
    exit 1
fi

# Compile hidapi for macOS
echo "Compiling hidapi with Xcode..."

cd "${BUILD_DIR}"

# Build object for the static library.
clang -c \
    -fPIC \
    -framework IOKit \
    -framework CoreFoundation \
    -I.. \
    -I/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include \
    ../macos/hid.c \
    -o hid.o

if [ $? -ne 0 ]; then
    echo "Error: Failed to compile hidapi"
    exit 1
fi

# Create static library
ar r libhidapi.a hid.o

if [ $? -ne 0 ]; then
    echo "Error: Failed to create static library"
    exit 1
fi

# Create dynamic library for standalone FFI loading/debugging.
clang -dynamiclib \
    -fPIC \
    -framework IOKit \
    -framework CoreFoundation \
    -I.. \
    ../macos/hid.c \
    -install_name @rpath/libhidapi.dylib \
    -o libhidapi.dylib

if [ $? -ne 0 ]; then
    echo "Error: Failed to create dynamic library"
    exit 1
fi

# Copy to install directory
cp libhidapi.a "${INSTALL_DIR}/"
cp libhidapi.dylib "${INSTALL_DIR}/"
cp ../hidapi/hidapi.h "${INSTALL_DIR}/"

echo "Build complete!"
echo "Library: ${INSTALL_DIR}/libhidapi.a"
echo "Dynamic Library: ${INSTALL_DIR}/libhidapi.dylib"
echo "Header: ${INSTALL_DIR}/hidapi.h"
