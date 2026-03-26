# hidapi 0.15.0 Windows build configuration
# This CMakeLists.txt is used to build hidapi library for Windows

cmake_minimum_required(VERSION 3.14)
project(hidapi C)

# Select platform-specific source files.
if(WIN32)
    set(HIDAPI_SOURCES
        windows/hid.c
    )
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
    add_definitions(-DHIDAPI_EXPORTS)
    add_library(hidapi SHARED ${HIDAPI_SOURCES} ${HIDAPI_HEADERS})

    # Set visibility for symbol exports
    set_target_properties(hidapi PROPERTIES
        WINDOWS_EXPORT_ALL_SYMBOLS ON
        OUTPUT_NAME hidapi
    )
else()
    add_library(hidapi STATIC ${HIDAPI_SOURCES})
endif()

# Set the include directory
target_include_directories(hidapi 
    PUBLIC 
    ${CMAKE_CURRENT_SOURCE_DIR}
)

# Link required Windows libraries
if(WIN32)
    target_link_libraries(hidapi PRIVATE setupapi.lib hid.lib)
endif()

# Link required macOS frameworks
if(APPLE)
    target_link_libraries(hidapi PRIVATE "-framework IOKit" "-framework CoreFoundation")
endif()

# Link required Linux libraries
if(UNIX AND NOT APPLE)
    target_link_libraries(hidapi PRIVATE udev)
endif()
