[中文版本](HID4FLUTTER_REFERENCE.md) | English

# hid4flutter Project Architecture Reference

## Project Overview

**Repository**: https://github.com/vinsfortunato/hid4flutter  
**Version**: 0.1.2  
**License**: MIT  
**Description**: Flutter plugin for communicating with HID (Human Interface Devices) from Flutter applications

### Supported Platforms
- ✅ Windows (Full support)
- ✅ macOS (Full support)
- ✅ Linux (Full support, requires manual installation of libhidapi-hidraw0)
- 📋 Android (Planned)
- 📋 Web (Planned)

### Technology Stack
- **Desktop**: Windows/macOS/Linux - Using hidapi (0.14.0) + Dart FFI
- **Android**: Planned to use MethodChannel + Android HID
- **Web**: Planned to use WebHID API

---

## 1. Project Structure

```
hid4flutter/
├── lib/                              # Main Dart code
│   ├── hid4flutter.dart             # Public API entry point
│   └── src/
│       ├── hid_device.dart          # HidDevice abstract class
│       ├── hid_exception.dart       # Exception classes
│       ├── hid_platform_interface.dart  # Platform interface
│       ├── desktop/                 # Desktop implementation
│       │   ├── hid_desktop.dart
│       │   ├── hid_device_desktop.dart
│       │   ├── hidapi_ffi.dart      # FFI bindings
│       │   └── extensions.dart      # Pointer extensions
│       └── android/                 # Android implementation
│           └── hid_android.dart
├── windows/                         # Windows native code
├── macos/                          # macOS native code
├── linux/                          # Linux native code
├── android/                        # Android native code
├── pubspec.yaml                    # Flutter dependency configuration
└── third_party/                    # hidapi library source code
```

---

## 2. Main Dart API Classes and Methods

### 2.1 Hid Class (Public Entry Point)

```dart
// lib/hid4flutter.dart
// Exported public classes
export 'src/hid_device.dart';
export 'src/hid_exception.dart';

class Hid {
  /// Get list of connected HID devices
  /// Optional filter parameters: vendorId, productId, usagePage, usage
  static Future<List<HidDevice>> getDevices({
    int? vendorId,
    int? productId,
    int? usagePage,
    int? usage,
  })
}
```

### 2.2 HidDevice Abstract Class

```dart
// lib/src/hid_device.dart
abstract class HidDevice {
  // ===== Device Properties =====
  String get id;                    // Unique identifier (usually path)
  String get path;                  // Platform-specific device path
  int get vendorId;                 // Device vendor ID
  int get productId;                // Device product ID
  String get serialNumber;          // Serial number
  int get releaseNumber;            // Device version number (BCD format)
  String get manufacturer;          // Manufacturer string
  String get productName;           // Product name string
  int get usagePage;                // HID usage page
  int get usage;                    // HID usage
  int get interfaceNumber;          // USB interface number
  int get busType;                  // Bus type (USB/Bluetooth/I2C/SPI)

  // ===== Connection Management =====
  Future<void> open();              // Open device
  bool get isOpen;                  // Check if opened
  Future<void> close();             // Close device

  // ===== Data Read/Write =====
  Stream<int> inputStream();        // Input report stream (byte stream)
  Future<Uint8List> receiveReport(
    int reportLength, 
    {Duration? timeout}
  );                                // Receive complete report
  Future<void> sendReport(
    Uint8List data, 
    {int reportId = 0x00}
  );                                // Send output report

  // ===== Feature Reports =====
  Future<Uint8List> getFeatureReport(
    int reportLength, 
    {int reportId = 0x00}
  );                                // Get feature report
  Future<void> sendFeatureReport(
    Uint8List data, 
    {int reportId = 0x00}
  );                                // Send feature report

  // ===== String Retrieval =====
  Future<String> getIndexedString(int index, {int maxLength = 256});
}
```

### 2.3 HidException Class

```dart
// lib/src/hid_exception.dart
class HidException implements Exception {
  final String message;
  HidException(this.message);
  
  @override
  String toString() => 'HidException: $message';
}
```

### 2.4 Platform Interface

```dart
// lib/src/hid_platform_interface.dart
abstract class HidPlatform extends PlatformInterface {
  static HidPlatform get instance => _instance;
  static set instance(HidPlatform instance) => _instance = instance;

  Future<List<HidDevice>> getDevices({
    int? vendorId,
    int? productId,
    int? usagePage,
    int? usage,
  });
}
```

---

## 3. Desktop Implementation Details

### 3.1 Platform Implementation (Desktop/hid_desktop.dart)

```dart
// lib/src/desktop/hid_desktop.dart

class HidWindows extends _HidDesktop {
  static registerWith() {
    final hidapi = NativeLibrary(DynamicLibrary.open('hidapi.dll'));
    HidPlatform.instance = HidWindows(hidapi);
  }
}

class HidMacos extends _HidDesktop {
  static registerWith() {
    final hidapi = NativeLibrary(DynamicLibrary.executable());
    HidPlatform.instance = HidMacos(hidapi);
  }
}

class HidLinux extends _HidDesktop {
  static registerWith() {
    final hidapi = NativeLibrary(DynamicLibrary.open('libhidapi-hidraw.so.0'));
    HidPlatform.instance = HidLinux(hidapi);
  }
}

class _HidDesktop extends HidPlatform {
  final NativeLibrary _hidapi;
  final List<HidDevice> _openDevices = [];

  @override
  Future<List<HidDevice>> getDevices({
    int? vendorId,
    int? productId,
    int? usagePage,
    int? usage,
  }) async {
    final pointer = _hidapi.hid_enumerate(vendorId ?? 0, productId ?? 0);
    
    // Iterate through linked list to get all devices
    var current = pointer;
    while (current.address != nullptr.address) {
      final info = current.ref;
      
      // Apply filter conditions
      if (usagePage != null && usagePage != info.usage_page) {
        current = info.next;
        continue;
      }
      
      // Create device object
      // ...
    }
  }
}
```

### 3.2 HidDevice Implementation (Desktop/hid_device_desktop.dart)

```dart
// lib/src/desktop/hid_device_desktop.dart

class HidDeviceDesktop extends HidDevice {
  final NativeLibrary _hidapi;
  Pointer<hid_device_> _device = nullptr;

  // ===== Connection Management =====
  @override
  Future<void> open() async {
    if (isOpen) throw StateError('Device is already open.');
    
    using((arena) {
      _device = _hidapi.hid_open_path(path.toCharPointer(allocator: arena));
      
      if (_device == nullptr) {
        throw HidException('Failed to open hid device.');
      }
      
      // Enable non-blocking mode
      if (_hidapi.hid_set_nonblocking(_device, 1) == -1) {
        throw HidException('Failed to set non blocking mode.');
      }
    });
  }

  @override
  Future<void> close() async {
    if (!isOpen) throw StateError('Device is not open.');
    _hidapi.hid_close(_device);
    _device = nullptr;
  }

  @override
  bool get isOpen => _device != nullptr;

  // ===== Data Read/Write =====
  @override
  Stream<int> inputStream() async* {
    if (!isOpen) throw StateError('Device is not open.');
    
    const bufferSize = 1024;
    final arena = Arena();
    
    try {
      var buffer = arena<Uint8>(bufferSize);
      
      while (isOpen) {
        int result = _hidapi.hid_read(
          _device,
          buffer.cast<UnsignedChar>(),
          bufferSize,
        );
        
        if (result == -1) {
          throw HidException('Failed to receive input report.');
        } else if (result > 0) {
          for (var i = 0; i < result; i++) {
            yield buffer[i];
          }
        }
        
        // 100 microsecond polling interval
        await Future.delayed(const Duration(microseconds: 100));
      }
    } finally {
      arena.releaseAll();
    }
  }

  @override
  Future<void> sendReport(Uint8List data, {int reportId = 0x00}) async {
    if (!isOpen) throw StateError('Device is not open.');
    
    using((arena) {
      final buffer = arena<UnsignedChar>(data.length + 1);
      buffer[0] = reportId;
      for (var i = 0; i < data.length; i++) {
        buffer[i + 1] = data[i];
      }
      
      int result = _hidapi.hid_write(
        _device,
        buffer,
        data.length + 1,
      );
      
      if (result == -1) {
        throw HidException('Failed to send report.');
      }
    });
  }

  // ===== Feature Reports =====
  @override
  Future<Uint8List> getFeatureReport(int reportLength, {int reportId = 0x00}) async {
    if (!isOpen) throw StateError('Device is not open.');
    
    return using((arena) {
      var buffer = arena<UnsignedChar>(reportLength + 1);
      buffer[0] = reportId;
      
      int result = _hidapi.hid_get_feature_report(
        _device,
        buffer,
        reportLength + 1,
      );
      
      if (result == -1) {
        throw HidException('Failed to get feature report.');
      }
      
      return Uint8List.fromList([
        for (var i = 1; i < result; i++) buffer[i]
      ]);
    });
  }

  @override
  Future<void> sendFeatureReport(Uint8List data, {int reportId = 0x00}) async {
    if (!isOpen) throw StateError('Device is not open.');
    
    using((arena) {
      final buffer = arena<UnsignedChar>(data.length + 1);
      buffer[0] = reportId;
      for (var i = 0; i < data.length; i++) {
        buffer[i + 1] = data[i];
      }
      
      int result = _hidapi.hid_send_feature_report(
        _device,
        buffer,
        data.length + 1,
      );
      
      if (result == -1) {
        throw HidException('Failed to send feature report.');
      }
    });
  }

  // ===== String Retrieval =====
  @override
  Future<String> getIndexedString(int index, {int maxLength = 256}) async {
    if (!isOpen) throw StateError('Device is not open.');
    
    return using((arena) {
      var buffer = arena<WChar>(maxLength);
      int result = _hidapi.hid_get_indexed_string(
        _device,
        index,
        buffer,
        maxLength,
      );
      
      if (result == 0) {
        return buffer.toDartString();
      } else {
        throw HidException('Failed to get indexed string.');
      }
    });
  }
}
```

---

## 4. FFI Binding Details

### 4.1 FFI Binding Structure (hidapi_ffi.dart)

```dart
// lib/src/desktop/hidapi_ffi.dart
// Auto-generated FFI bindings, generated via ffigen tool

class NativeLibrary {
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) _lookup;
  
  NativeLibrary(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  // ===== Library Initialization =====
  int hid_init()        // Initialize library
  int hid_exit()        // Cleanup library resources

  // ===== Device Enumeration =====
  ffi.Pointer<hid_device_info> hid_enumerate(int vendor_id, int product_id)
  void hid_free_enumeration(ffi.Pointer<hid_device_info> devs)

  // ===== Device Open/Close =====
  ffi.Pointer<hid_device> hid_open(int vendor_id, int product_id, ffi.Pointer<ffi.WChar> serial_number)
  ffi.Pointer<hid_device> hid_open_path(ffi.Pointer<ffi.Char> path)
  void hid_close(ffi.Pointer<hid_device> dev)

  // ===== Data Transfer =====
  int hid_write(ffi.Pointer<hid_device> dev, ffi.Pointer<ffi.UnsignedChar> data, int length)
  int hid_read(ffi.Pointer<hid_device> dev, ffi.Pointer<ffi.UnsignedChar> data, int length)
  int hid_read_timeout(ffi.Pointer<hid_device> dev, ffi.Pointer<ffi.UnsignedChar> data, int length, int milliseconds)

  // ===== Feature Reports =====
  int hid_send_feature_report(ffi.Pointer<hid_device> dev, ffi.Pointer<ffi.UnsignedChar> data, int length)
  int hid_get_feature_report(ffi.Pointer<hid_device> dev, ffi.Pointer<ffi.UnsignedChar> data, int length)
  int hid_get_input_report(ffi.Pointer<hid_device> dev, ffi.Pointer<ffi.UnsignedChar> data, int length)

  // ===== Device Configuration =====
  int hid_set_nonblocking(ffi.Pointer<hid_device> dev, int nonblock)
  ffi.Pointer<hid_device_info> hid_get_device_info(ffi.Pointer<hid_device> dev)

  // ===== String Methods =====
  int hid_get_manufacturer_string(ffi.Pointer<hid_device> dev, ffi.Pointer<ffi.WChar> string, int maxlen)
  int hid_get_product_string(ffi.Pointer<hid_device> dev, ffi.Pointer<ffi.WChar> string, int maxlen)
  int hid_get_serial_number_string(ffi.Pointer<hid_device> dev, ffi.Pointer<ffi.WChar> string, int maxlen)
  int hid_get_indexed_string(ffi.Pointer<hid_device> dev, int string_index, ffi.Pointer<ffi.WChar> string, int maxlen)

  // ===== Report Descriptor (hidapi 0.14.0+) =====
  int hid_get_report_descriptor(ffi.Pointer<hid_device> dev, ffi.Pointer<ffi.UnsignedChar> buf, int buf_size)

  // ===== Error Handling =====
  ffi.Pointer<ffi.WChar> hid_error(ffi.Pointer<hid_device> dev)

  // ===== Version Information =====
  ffi.Pointer<hid_api_version> hid_version()
  ffi.Pointer<ffi.Char> hid_version_str()
}
```

### 4.2 FFI Struct Definitions

```dart
// hidapi device info struct
final class hid_device_info extends ffi.Struct {
  external ffi.Pointer<ffi.Char> path;           // Platform-specific path
  
  @ffi.UnsignedShort()
  external int vendor_id;                        // Vendor ID
  
  @ffi.UnsignedShort()
  external int product_id;                       // Product ID
  
  external ffi.Pointer<ffi.WChar> serial_number; // Serial number
  
  @ffi.UnsignedShort()
  external int release_number;                   // Version number (BCD)
  
  external ffi.Pointer<ffi.WChar> manufacturer_string;  // Manufacturer
  external ffi.Pointer<ffi.WChar> product_string;       // Product name
  
  @ffi.UnsignedShort()
  external int usage_page;                       // HID usage page
  
  @ffi.UnsignedShort()
  external int usage;                            // HID usage
  
  @ffi.Int()
  external int interface_number;                 // USB interface number
  
  external ffi.Pointer<hid_device_info> next;    // Next device
  
  @ffi.Int32()
  external int bus_type;                         // Bus type
}

// Version info struct
final class hid_api_version extends ffi.Struct {
  @ffi.Int()
  external int major;
  
  @ffi.Int()
  external int minor;
  
  @ffi.Int()
  external int patch;
}

// Opaque device handle
final class hid_device_ extends ffi.Opaque {}
typedef hid_device = hid_device_;

// Bus type constants
abstract class hid_bus_type {
  static const int HID_API_BUS_UNKNOWN = 0;      // Unknown
  static const int HID_API_BUS_USB = 1;          // USB
  static const int HID_API_BUS_BLUETOOTH = 2;    // Bluetooth/BLE
  static const int HID_API_BUS_I2C = 3;          // I2C
  static const int HID_API_BUS_SPI = 4;          // SPI
}
```

---

**Documentation Version**: 1.0  
**Last Updated**: March 26, 2026  
**Accuracy Level**: Complete Reference
