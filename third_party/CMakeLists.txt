# Official hidapi 0.15.0 build configuration
# From: https://github.com/libusb/hidapi

cmake_minimum_required(VERSION 3.14)

# Build as a subdirectory
set(HIDAPI_WITH_TESTS OFF)
set(HIDAPI_BUILD_PP_DATA_DUMP OFF)
set(BUILD_SHARED_LIBS ON)

# Add the official hidapi source
add_subdirectory(hidapi_official/src)
