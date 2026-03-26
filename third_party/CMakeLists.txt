# hidapi 0.15.0 Windows build configuration
# Official hidapi build from https://github.com/libusb/hidapi

cmake_minimum_required(VERSION 3.14)
project(hidapi C)

set(HIDAPI_VERSION "0.15.0")

# Select platform-specific source files.
if(WIN32)
    set(HIDAPI_SOURCES
        windows/hid.c
    )

    # Define export macro for DLL
    add_compile_definitions(HIDAPI_EXPORTS)

elseif(APPLE)
    set(HIDAPI_SOURCES
        macos/hid.c
    )
elseif(UNIX)
    set(HIDAPI_SOURCES
        linux/hid.c
    )
else()
    message(FATAL_ERROR "Unsupported platform for hidapi")
endif()

set(HIDAPI_HEADERS
    hidapi/hidapi.h
)

# Create the hidapi library
# Use SHARED on Windows so Dart FFI can load symbols via DynamicLibrary
if(WIN32)
    add_library(hidapi SHARED ${HIDAPI_SOURCES} ${HIDAPI_HEADERS})

    # Set visibility for symbol exports
    set_target_properties(hidapi PROPERTIES
        WINDOWS_EXPORT_ALL_SYMBOLS ON
        OUTPUT_NAME hidapi
        VERSION ${HIDAPI_VERSION}
    )

    # Link required Windows libraries
    target_link_libraries(hidapi PRIVATE setupapi.lib hid.lib cfgmgr32.lib)

    # Include current directory for hidapi.h
    target_include_directories(hidapi PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

elseif(APPLE)
    add_library(hidapi STATIC ${HIDAPI_SOURCES})
    target_include_directories(hidapi PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
    target_link_libraries(hidapi PRIVATE "-framework IOKit" "-framework CoreFoundation")
else()
    add_library(hidapi STATIC ${HIDAPI_SOURCES})
    target_include_directories(hidapi PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
    target_link_libraries(hidapi PRIVATE udev)
endif()
