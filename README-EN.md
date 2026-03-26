# 🎯 HIDtool - Flutter HID Device Management Application

Designed based on [hid4flutter](https://github.com/vinsfortunato/hid4flutter), **fully upgraded** to use the powerful **hidapi-0.15.0** Flutter application.

![License](https://img.shields.io/badge/License-MIT-blue.svg)
![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux-brightgreen.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.10.4%2B-blue.svg)

> **中文版本**: [README.md](README.md)

## ✨ Core Features

🎯 **Complete HID Device Communication**
- Device enumeration and filtering
- Real-time data transmission/reception
- Feature report support
- Comprehensive error handling

🆕 **hidapi-0.15.0 New Features**
- ✅ Report descriptor retrieval
- ✅ Version information query
- ✅ Bus type identification
- ✅ Report length query

🔧 **Ready to Use**
- Complete compilation configuration (Windows/macOS/Linux)
- Example Flutter UI application
- Detailed API documentation
- Production-grade implementation

## 🚀 Quick Start

### 1️⃣ Clone and Prepare

```bash
cd /Users/admin/Development/hidtool
flutter pub get
```

### 2️⃣ Install Platform Dependencies

#### 💻 Windows
```powershell
# Visual Studio 2022 + CMake + Windows SDK (install from Visual Studio Installer)
# Then run:
flutter run
```

#### 🍎 macOS
```bash
# Xcode and Command Line Tools
xcode-select --install

# Build hidapi library
cd third_party
chmod +x build_macos.sh
./build_macos.sh

# Run the application
cd ..
flutter run
```

#### 🐧 Linux
```bash
# Install dependencies
sudo apt-get install -y \
    cmake ninja-build clang pkg-config \
    libgtk-3-dev libhidapi-hidraw0 libhidapi-hidraw-dev libudev-dev

# Run the application
flutter run
```

### 3️⃣ Using the Application

1. Connect a HID device
2. The app will automatically scan and display the device list
3. Click on a device to open the connection
4. Send/receive data

## 💡 API Usage Examples

### Basic Usage

```dart
import 'package:hidtool/hid4flutter.dart';
import 'dart:typed_data';

// Initialize
await Hid.init();

// Get all devices
List<HidDevice> devices = await Hid.getDevices();

// Or get a specific device by VID/PID
HidDevice? device = await Hid.getDevice(
  vendorId: 0x1234,
  productId: 0x5678,
);

if (device != null) {
  // Open the device
  await device.open();
  
  // Send data
  var data = Uint8List.fromList([0x01, 0x02, 0x03]);
  await device.sendReport(data);
  
  // Receive data (with 2-second timeout)
  var response = await device.receiveReport(64, 
    timeout: Duration(seconds: 2)
  );
  
  // Query device information
  print('Device: ${device.productName}');
  print('VID: 0x${device.vendorId.toRadixString(16)}');
  print('PID: 0x${device.productId.toRadixString(16)}');
  
  // hidapi 0.15.0+ new feature: Get report descriptor
  Uint8List descriptor = await device.getReportDescriptor();
  
  // Close the device
  await device.close();
}
```

### Advanced Features

```dart
// Get feature report
Uint8List feature = await device.getFeatureReport(64);

// Send feature report
await device.sendFeatureReport(Uint8List.fromList([0x00, 0x01]));

// Get indexed string
String indexedStr = await device.getIndexedString(1);

// Query hidapi version (0.15.0+)
Map<String, int> version = await Hid.getVersion();
print('hidapi: ${version['major']}.${version['minor']}.${version['patch']}');

// Query report lengths
int inputLen = await device.getInputReportLength();
int outputLen = await device.getOutputReportLength();
```

## 📦 Project Structure

```
lib/
├── main.dart                    # Flutter UI application
├── hid4flutter.dart             # Public API entry point
└── src/
    ├── hid_device.dart          # HidDevice abstract class
    ├── hid_exception.dart       # Exception handling
    ├── hid_platform_interface.dart
    └── desktop/
        ├── hid_desktop.dart     # Desktop platform implementation
        ├── hid_device_desktop.dart
        └── hidapi_ffi.dart      # FFI binding

third_party/
├── hidapi/
│   └── hidapi.h                 # hidapi-0.15.0 header file
├── windows/hid.c                # Windows implementation
├── macos/hid.c                  # macOS implementation
├── linux/hid.c                  # Linux implementation
└── build_macos.sh               # macOS build script
```

## 🎨 Features Demo

### Device List Interface
- Display all connected HID devices
- Device information: VID, PID, serial number, manufacturer
- Real-time refresh button
- Error messages

### Device Details
- Complete information of the selected device
- Connect/disconnect buttons
- Send test report button
- Connection status indicator

### Error Handling
- Clear error messages
- Real-time SnackBar feedback
- Exception handling

## 🔗 Complete API List

### Device Properties (12 total)
| Property | Type | Description |
|----------|------|-------------|
| `id` | String | Device unique identifier |
| `path` | String | Device path |
| `vendorId` | int | USB VID |
| `productId` | int | USB PID |
| `serialNumber` | String | Serial number |
| `releaseNumber` | int | Version number |
| `manufacturer` | String | Manufacturer |
| `productName` | String | Product name |
| `usagePage` | int | HID usage page |
| `usage` | int | HID usage |
| `interfaceNumber` | int | Interface number |
| `busType` | int | Bus type |

### Device Methods (13 total)
| Method | Description |
|--------|-------------|
| `open()` | Open the device |
| `close()` | Close the device |
| `sendReport()` | Send output report |
| `receiveReport()` | Receive input report |
| `sendFeatureReport()` | Send feature report |
| `getFeatureReport()` | Get feature report |
| `getReportDescriptor()` ⭐ | Get report descriptor |
| `getInputReportLength()` | Get input report length |
| `getOutputReportLength()` | Get output report length |
| `getFeatureReportLength()` | Get feature report length |
| `getIndexedString()` | Get indexed string |
| `inputStream()` | Input stream |

### Hid Class Methods
| Method | Description |
|--------|-------------|
| `Hid.init()` | Initialize HID system |
| `Hid.getDevices()` | Get all devices |
| `Hid.getDevice()` | Get device by VID/PID |
| `Hid.getVersion()` ⭐ | Get hidapi version |

⭐ = hidapi 0.15.0 new features

## 📚 Documentation

| Document | Content |
|----------|---------|
| [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) / [IMPLEMENTATION_GUIDE-EN.md](IMPLEMENTATION_GUIDE-EN.md) | Complete implementation guide |
| [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) / [PROJECT_SUMMARY-EN.md](PROJECT_SUMMARY-EN.md) | Project summary |
| [HID4FLUTTER_REFERENCE.md](HID4FLUTTER_REFERENCE.md) / [HID4FLUTTER_REFERENCE-EN.md](HID4FLUTTER_REFERENCE-EN.md) | Architecture reference |
| [HIDAPI_FFI_REFERENCE.md](HIDAPI_FFI_REFERENCE.md) / [HIDAPI_FFI_REFERENCE-EN.md](HIDAPI_FFI_REFERENCE-EN.md) | API details |

## 🐛 Troubleshooting

### "hidapi library not found"

**Linux**
```bash
sudo apt-get install libhidapi-hidraw0
```

**macOS**
```bash
cd third_party
./build_macos.sh
```

**Windows**
- Ensure Visual Studio 2022 is installed
- Re-run `flutter run`

### Device not showing

- Check USB connection
- Try the refresh button
- On Linux, you may need elevated privileges: `sudo flutter run`

### Compilation failed

- **Linux**: Install build tools: `sudo apt-get install build-essential cmake`
- **macOS**: Install Xcode tools: `xcode-select --install`
- **Windows**: Install Visual Studio Build Tools

## 🎯 Supported Platforms

| Platform | Support | Build Method |
|----------|---------|--------------|
| Windows | ✅ | CMake + MSVC |
| macOS | ✅ | Clang + Xcode |
| Linux | ✅ | CMake + GCC |
| iOS | 📋 | Planned |
| Android | 📋 | Planned |

## 📋 Implementation Checklist

- ✅ Dart API layer (complete)
- ✅ FFI binding (hidapi-0.15.0 full features)
- ✅ Desktop implementation (Windows/macOS/Linux)
- ✅ Native code (3 platforms)
- ✅ Compilation configuration (CMake)
- ✅ Flutter UI application
- ✅ Documentation and examples

## 🔐 License

MIT License - See [LICENSE](LICENSE) file

## 📖 Related Links

- [hidapi Official](https://github.com/libusb/hidapi)
- [hidapi-0.15.0 Release](https://github.com/libusb/hidapi/releases/tag/hidapi-0.15.0)
- [Flutter FFI](https://dart.dev/guides/libraries/c-interop)
- [hid4flutter Original Project](https://github.com/vinsfortunato/hid4flutter)

## 💬 Community

Have questions or suggestions?

1. Check the troubleshooting section in [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)
2. Check console error messages
3. Submit an Issue or Pull Request

---

**Project Version**: 1.0.0  
**hidapi Version**: 0.15.0  
**Flutter Version**: 3.10.4+  
**Status**: ✅ Complete

**Get started now!** 🚀
