[中文版本](QUICK_REFERENCE.md) | English

# hid4flutter Quick Reference Guide

> A formatted quick reference card for easy lookup during development

---

## Quick Navigation

| Document | Content | Purpose |
|----------|---------|---------|
| **HID4FLUTTER_REFERENCE.md** | Complete project architecture | Project understanding, design reference |
| **HIDAPI_FFI_REFERENCE.md** | FFI API explanation | Writing hidapi call code |
| **HIDAPI_0_15_0_MIGRATION.md** | Upgrade guide | Version upgrade, migration |
| **This file** | Quick lookup | Daily development reference |

---

## 🚀 5-Minute Quick Start

### 1. Get Device List

```dart
import 'package:hid4flutter/hid4flutter.dart';

// Get all devices
List<HidDevice> devices = await Hid.getDevices();

// With filter conditions
List<HidDevice> myDevices = await Hid.getDevices(
  vendorId: 0x1234,      // Vendor ID
  productId: 0x5678,     // Product ID
  usagePage: 0xFF00,     // HID usage page
  usage: 0x0001,         // Usage
);

for (var device in myDevices) {
  print('${device.productName} (${device.serialNumber})');
}
```

### 2. Connect and Read/Write Data

```dart
try {
  // Open device
  await device.open();
  
  // Send data
  var data = Uint8List.fromList([
    0x00,           // Report ID
    0x12, 0x34,     // Data...
  ]);
  await device.sendReport(data);
  
  // Receive data
  var received = await device.receiveReport(64);
  print('Received: $received');
  
  // Close device
  await device.close();
  
} on HidException catch (e) {
  print('Error: ${e.message}');
}
```

### 3. Stream Read Data

```dart
// Continuously read input reports
device.inputStream().listen((byte) {
  print('Byte: 0x${byte.toRadixString(16)}');
});
```

---

## 📋 Device Properties Quick Reference

```dart
HidDevice device = ...;

// Basic info
device.id              // Unique identifier
device.path            // Platform-specific path
device.isOpen          // Whether opened

// Hardware info
device.vendorId        // VID (16-bit)
device.productId       // PID (16-bit)
device.serialNumber    // Serial number string
device.releaseNumber   // Version number (BCD format)

// Identification info
device.manufacturer    // Manufacturer string
device.productName     // Product name string

// HID info
device.usagePage       // HID usage page (16-bit)
device.usage           // HID usage (16-bit)
device.interfaceNumber // USB interface number
device.busType         // Bus type (0=unknown, 1=USB, 2=BT, 3=I2C, 4=SPI)
```

---

## 🔌 API Methods Quick Reference

### Connection Management
```dart
Future<void> open()                                    // Open device
Future<void> close()                                   // Close device
bool get isOpen                                        // Whether opened
```

### Data Transfer
```dart
Future<void> sendReport(Uint8List data, {int reportId = 0x00})
Future<Uint8List> receiveReport(int reportLength, {Duration? timeout})
Stream<int> inputStream()                              // Byte stream
```

### Feature Reports
```dart
Future<Uint8List> getFeatureReport(int reportLength, {int reportId = 0x00})
Future<void> sendFeatureReport(Uint8List data, {int reportId = 0x00})
```

### String Retrieval
```dart
Future<String> getIndexedString(int index, {int maxLength = 256})
```

---

## 🔧 Common Scenario Code Examples

### Scenario 1: Find Specific Device

```dart
Future<HidDevice?> findMyDevice() async {
  List<HidDevice> devices = await Hid.getDevices(
    vendorId: 0x1234,
    productId: 0x5678,
  );
  
  for (var device in devices) {
    if (device.serialNumber == 'MY_SERIAL_001') {
      return device;
    }
  }
  return null;
}
```

### Scenario 2: Connect and Send Command

```dart
Future<List<int>> sendCommand(HidDevice device, List<int> cmd) async {
  try {
    await device.open();
    
    // Send
    var request = Uint8List.fromList([0x00, ...cmd]);
    await device.sendReport(request);
    
    // Receive
    var response = await device.receiveReport(
      64,
      timeout: Duration(seconds: 5),
    );
    
    return response;
    
  } finally {
    if (device.isOpen) await device.close();
  }
}
```

### Scenario 3: Monitor Device Connection/Disconnection

```dart
Future<void> monitorDevices() async {
  Set<String> previousIds = {};
  
  while (true) {
    List<HidDevice> current = await Hid.getDevices();
    Set<String> currentIds = {for (var d in current) d.id};
    
    // Detect new connections
    var connected = currentIds.difference(previousIds);
    for (var id in connected) {
      print('Device connected: $id');
    }
    
    // Detect disconnections
    var disconnected = previousIds.difference(currentIds);
    for (var id in disconnected) {
      print('Device disconnected: $id');
    }
    
    previousIds = currentIds;
    await Future.delayed(Duration(seconds: 1));  // 1 second polling
  }
}
```

### Scenario 4: Get Device Information

```dart
Future<void> printDeviceInfo(HidDevice device) async {
  print('''
HID Device Information
======================
Product: ${device.productName}
Manufacturer: ${device.manufacturer}
Serial Number: ${device.serialNumber}
VID: 0x${device.vendorId.toRadixString(16).padLeft(4, '0')}
PID: 0x${device.productId.toRadixString(16).padLeft(4, '0')}
Version: 0x${device.releaseNumber.toRadixString(16).padLeft(4, '0')}
Usage Page: 0x${device.usagePage.toRadixString(16).padLeft(4, '0')}
Usage: 0x${device.usage.toRadixString(16).padLeft(4, '0')}
Bus: ${getBusTypeName(device.busType)}
Interface: ${device.interfaceNumber}
Path: ${device.path}
  ''');
}

String getBusTypeName(int busType) {
  return const {
    0: 'Unknown',
    1: 'USB',
    2: 'Bluetooth',
    3: 'I2C',
    4: 'SPI',
  }[busType] ?? 'Unknown';
}
```

---

## ⚠️ Error Handling

### Exception Types

```dart
// HidException - All HID operation errors
try {
  await device.open();
} on HidException catch (e) {
  print('HID Error: ${e.message}');
}

// StateError - Device state errors
try {
  await device.sendReport(data);  // Throws if not opened
} on StateError catch (e) {
  print('State Error: ${e.message}');
}
```

### Error Recovery Pattern

```dart
Future<bool> tryOperation(HidDevice device) async {
  int maxRetries = 3;
  
  for (int i = 0; i < maxRetries; i++) {
    try {
      await device.open();
      await device.sendReport(Uint8List(64));
      return true;
    } on HidException catch (e) {
      print('Attempt $i failed: ${e.message}');
      
      // Wait then retry
      await Future.delayed(Duration(milliseconds: 100 * i));
      
      if (i < maxRetries - 1) continue;
      return false;
    } finally {
      if (device.isOpen) await device.close();
    }
  }
  
  return false;
}
```

---

## 📊 Performance Optimization Suggestions

| Operation | Latency | Optimization Tips |
|-----------|---------|-------------------|
| Device enumeration | 50-100ms | Cache results, background polling |
| Open device | 10-50ms | Pre-open until ready |
| Single read/write | 1-10ms | Batch operations, use streams |
| Feature report | 5-20ms | Call only when necessary |

### Best Practice

```dart
class HidDeviceManager {
  Map<String, HidDevice> _cachedDevices = {};
  late Timer _enumerationTimer;
  
  void initialize() {
    // Background polling for devices
    _enumerationTimer = Timer.periodic(
      Duration(seconds: 2),
      (_) => _updateDeviceList(),
    );
  }
  
  Future<void> _updateDeviceList() async {
    try {
      List<HidDevice> devices = await Hid.getDevices();
      _cachedDevices = {for (var d in devices) d.id: d};
    } catch (e) {
      print('Enumeration error: $e');
    }
  }
  
  List<HidDevice> getDevices() => _cachedDevices.values.toList();
  
  void dispose() => _enumerationTimer.cancel();
}
```

---

## 🐛 Common Issue Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Device not found | Wrong VID/PID or device not connected | Check Device Manager, verify VID/PID |
| Cannot open device | Insufficient permissions | Windows/Mac: run as admin; Linux: add udev rules |
| Data transfer failed | Wrong report ID | Check device documentation, verify report format |
| Memory leak | Device not closed or resources not freed | Use finally block to ensure close() is called |
| Timeout error | Slow device response | Increase timeout or use non-blocking mode |

---

## 📱 Platform-Specific Information

### Windows
- Driver: Usually auto-installed (generic HID driver)
- Permissions: Accessible to regular users
- Cleanup: Handles released automatically on app exit

### macOS
- Driver: Built-in system support
- Permissions: User accessible
- Special: Uses DynamicLibrary.executable() to link hidapi

### Linux
- Driver: Built-in kernel HID driver
- Permissions: Need udev rules or sudo
- Library: Need to manually install libhidapi-hidraw0

```bash
# Linux udev rules (/etc/udev/rules.d/99-hidapi.rules)
SUBSYSTEM=="hidraw", MODE="0666"
```

---

## 🔍 Debugging Tips

### Print All Device Information

```dart
Future<void> debugAllDevices() async {
  List<HidDevice> devices = await Hid.getDevices();
  
  if (devices.isEmpty) {
    print('No HID devices found');
    return;
  }
  
  for (int i = 0; i < devices.length; i++) {
    final d = devices[i];
    print('''
[Device $i]
  Path: ${d.path}
  VID: 0x${d.vendorId.toRadixString(16).padLeft(4, '0')}
  PID: 0x${d.productId.toRadixString(16).padLeft(4, '0')}
  Serial: ${d.serialNumber}
  Product: ${d.productName}
  Manufacturer: ${d.manufacturer}
  Usage: 0x${d.usage.toRadixString(16).padLeft(4, '0')}
  UsagePage: 0x${d.usagePage.toRadixString(16).padLeft(4, '0')}
    ''');
  }
}
```

### Monitor Connection Events

```dart
Future<void> watchConnections() async {
  Set<String> previous = {};
  
  while (true) {
    final current = (await Hid.getDevices()).map((d) => d.path).toSet();
    
    // New devices
    final added = current.difference(previous);
    for (final path in added) print('Connected: $path');
    
    // Removed devices
    final removed = previous.difference(current);
    for (final path in removed) print('Disconnected: $path');
    
    previous = current;
    await Future.delayed(Duration(seconds: 1));
  }
}
```

---

## 📚 Related Resources

| Resource | URL |
|----------|-----|
| GitHub Project | https://github.com/vinsfortunato/hid4flutter |
| Pub.dev | https://pub.dev/packages/hid4flutter |
| HIDAPI | https://github.com/libusb/hidapi |
| USB HID Specification | https://www.usb.org/hid |
| Dart FFI | https://dart.dev/guides/libraries/native-interop |
| Flutter Documentation | https://flutter.dev |

---

## 🎯 Project Integration Checklist

Confirmation checklist when creating new projects:

- [ ] Add dependency: `flutter pub add hid4flutter`
- [ ] Import package: `import 'package:hid4flutter/hid4flutter.dart';`
- [ ] Platform version check (MacOS 10.11+, Windows 7+, Linux GTK3+)
- [ ] Permission configuration (Linux udev rules if needed)
- [ ] Error handling (try-catch HidException)
- [ ] Resource cleanup (device.close() in finally block)
- [ ] Test connection and transfer
- [ ] Documentation and examples

---

## Version Information

| Component | Version |
|-----------|---------|
| hid4flutter | 0.1.2 |
| hidapi | 0.14.0 (recommend upgrade to 0.15.0) |
| Flutter | ≥ 3.3.0 |
| Dart | ≥ 3.0.0 |

---

**Last Updated**: March 26, 2026  
**Status**: Complete Reference  
**Purpose**: Daily development lookup + Learning Reference

---

**Documentation Version**: 1.0  
**Accuracy Level**: Complete Reference
