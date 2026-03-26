[🇨🇳 Chinese Version](IMPLEMENTATION_GUIDE.md)

# HIDtool - Complete HID Device Communication Flutter Application

This is a complete Flutter application that implements cross-platform HID (Human Interface Device) communication using **hidapi-0.15.0**.

## Project Features

✅ **Complete Dart API Layer** - Type-safe HID device interface  
✅ **FFI Bindings** - Direct access to hidapi-0.15.0 native library  
✅ **Cross-platform Support** - Windows, macOS, Linux (with build configurations)  
✅ **hidapi-0.15.0 New Features** - Including report descriptor retrieval  
✅ **Example Application** - Complete device list and interactive UI  

## Directory Structure

```
hidtool/
├── lib/
│   ├── main.dart                      # Flutter UI Application
│   ├── hid4flutter.dart               # Public API Entry Point
│   └── src/
│       ├── hid_device.dart            # HidDevice Abstract Class
│       ├── hid_exception.dart         # Exception Classes
│       ├── hid_platform_interface.dart # Platform Interface
│       └── desktop/
│           ├── hid_desktop.dart       # Desktop Implementation
│           ├── hid_device_desktop.dart # Device Implementation
│           └── hidapi_ffi.dart        # FFI Bindings (hidapi 0.15.0)
├── third_party/
│   ├── hidapi/
│   │   └── hidapi.h                   # hidapi-0.15.0 Header File
│   ├── windows/
│   │   └── hid.c                      # Windows Implementation
│   ├── macos/
│   │   └── hid.c                      # macOS Implementation
│   ├── linux/
│   │   └── hid.c                      # Linux Implementation
│   ├── CMakeLists.txt                 # Library Build Configuration
│   └── build_macos.sh                 # macOS Build Script
├── windows/CMakeLists.txt             # Windows Build Configuration
├── macos/                             # macOS Project Files
├── linux/CMakeLists.txt               # Linux Build Configuration
└── pubspec.yaml                       # Flutter Dependency Configuration
```

## Quick Start

### 1. Environment Requirements

- Flutter 3.10.4 or higher
- Dart SDK 3.10.4 or higher
- Platform-specific build tools:
  - **Windows**: Visual Studio 2022 (CMake, MSVC, Windows SDK)
  - **macOS**: Xcode 13+ (Command Line Tools)
  - **Linux**: GCC, CMake, libhidapi-hidraw0-dev

### 2. Install Dependencies

#### Linux
```bash
sudo apt-get install -y \
    cmake \
    ninja-build \
    clang \
    pkg-config \
    libgtk-3-dev \
    libhidapi-hidraw0 \
    libhidapi-hidraw-dev \
    libudev-dev
```

#### macOS
```bash
# Make sure Xcode command line tools are installed
xcode-select --install

# Install dependencies using Homebrew (optional)
brew install cmake ninja
```

#### Windows
- Install Visual Studio 2022 Community (check C++ workload)
- Install CMake
- Install Flutter SDK

### 3. Get Project Dependencies

```bash
cd /Users/admin/Development/hidtool
flutter pub get
```

### 4. Run Application

#### Windows
```bash
flutter run -v
```

#### macOS
Before building, you need to compile the hidapi library:
```bash
cd third_party
chmod +x build_macos.sh
./build_macos.sh

flutter run -v
```

#### Linux
```bash
flutter run -v
```

## API Usage Guide

### Initialization

```dart
void main() async {
  // Initialize HID System
  await Hid.init();
  runApp(const MyApp());
}
```

### Get Device List

```dart
import 'package:hidtool/hid4flutter.dart';

// Get all devices
List<HidDevice> devices = await Hid.getDevices();

// Filter by VID/PID
List<HidDevice> myDevices = await Hid.getDevices(
  vendorId: 0x1234,
  productId: 0x5678,
);

// Get specific device
HidDevice? device = await Hid.getDevice(
  vendorId: 0x1234,
  productId: 0x5678,
);
```

### Communicate with Device

```dart
// Open device
await device.open();

// Send report
import 'dart:typed_data';
var data = Uint8List.fromList([0x00, 0x01, 0x02]);
await device.sendReport(data);

// Receive report
var received = await device.receiveReport(64, timeout: Duration(seconds: 2));

// Send feature report
await device.sendFeatureReport(data);

// Get feature report
var feature = await device.getFeatureReport(64);

// Get report descriptor (hidapi 0.15.0+)
var descriptor = await device.getReportDescriptor();

// Close device
await device.close();
```

### Query Device Information

```dart
// Basic Information
int vid = device.vendorId;          // USB Vendor ID
int pid = device.productId;         // USB Product ID
String serial = device.serialNumber; // Serial Number
String product = device.productName; // Product Name
String mfg = device.manufacturer;    // Manufacturer

// HID Information
int usagePage = device.usagePage;   // HID Usage Page
int usage = device.usage;            // HID Usage
int busType = device.busType;        // Bus Type (USB/Bluetooth/I2C/SPI)

// Report Length (hidapi 0.15.0+)
int inputLen = await device.getInputReportLength();
int outputLen = await device.getOutputReportLength();
int featureLen = await device.getFeatureReportLength();
```

### Get Version Information

```dart
// Get hidapi version (0.15.0+)
Map<String, int> version = await Hid.getVersion();
print('hidapi version: ${version['major']}.${version['minor']}.${version['patch']}');
```

## hidapi-0.15.0 New Features

This project implements all new features in hidapi-0.15.0:

1. **`hid_get_report_descriptor()`** - Get raw report descriptor bytes
2. **`hid_version()`** - Query hidapi library version
3. **Enhanced Error Handling** - Better error messages
4. **Improved Device Enumeration** - More reliable device detection
5. **Bus Type Support** - Identify bus types (USB, Bluetooth, etc.)

## Build Details

### Windows Build

Windows implementation uses Windows HID API (hid.dll and setupapi.lib):

```bash
# Compile in Visual Studio
cmake -G "Visual Studio 17 2022" -B build
cmake --build build --config Release
```

### macOS Build

macOS implementation uses IOKit framework:

```bash
# Use build script
cd third_party
./build_macos.sh

# Script generates dist/libhidapi.a
```

### Linux Build

Linux implementation uses hidraw (/dev/hidraw*):

```bash
# CMake automatically detects and links libudev
cmake -B build
cmake --build build
```

## Native Code Integration

### Library Locations

- **Windows**: Uses system hid.dll (Windows HID API)
- **macOS**: [Requires manual compilation or download precompiled library](https://github.com/libusb/hidapi/releases)
- **Linux**: System libhidapi-hidraw

### Environment Variables

You can specify hidapi library location via environment variables:

```bash
# Linux
export LD_LIBRARY_PATH=/path/to/hidapi:$LD_LIBRARY_PATH

# macOS
export DYLD_LIBRARY_PATH=/path/to/hidapi:$DYLD_LIBRARY_PATH
```

## Troubleshooting

### "Failed to load hidapi library"

**Cause**: Cannot find hidapi library

**Solution**:
- **Linux**: Install `libhidapi-hidraw0` package
- **macOS**: Run `third_party/build_macos.sh` to compile library
- **Windows**: Ensure Windows 10/11 and install all system updates

### Device Not Visible

**Cause**: Permission issues or driver issues

**Solution**:
- **Linux**: Add udev rules or run with root privileges
- **macOS**: Check system privacy settings
- **Windows**: Run application as administrator

### Compilation Failed

**Cause**: Missing build tools

**Solution**:
- **Linux**: `sudo apt-get install build-essential cmake`
- **macOS**: `xcode-select --install`
- **Windows**: Install Visual Studio Build Tools

## Testing

The project includes a complete example UI application:

```bash
flutter run
```

The application will:
1. Scan all connected HID devices
2. Display device information in a list
3. Allow opening/closing devices
4. Allow sending test reports
5. Display any error messages

## Production Use Recommendations

1. **Add Error Handling**: Use try-catch and HidException
2. **Resource Cleanup**: Ensure devices are closed in dispose()
3. **Permission Checks**: Implement permission requests on Android/iOS
4. **Timeout Settings**: Set appropriate timeouts for long operations
5. **Logging**: Implement detailed logging for debugging
6. **Test Coverage**: Add unit tests and integration tests

## License

MIT License - See LICENSE file for details

## Reference Resources

- [hidapi GitHub](https://github.com/libusb/hidapi)
- [hidapi-0.15.0 Release](https://github.com/libusb/hidapi/releases/tag/hidapi-0.15.0)
- [Flutter FFI](https://dart.dev/guides/libraries/c-interop)
- [HID Specification](https://www.usb.org/hid)

## Support

For issues or improvement suggestions, please submit an Issue or Pull Request.
