[🇨🇳 Chinese Version](MIGRATION_GUIDE.md)

# Migration Guide: From hid4flutter (0.14.0) to hidtool (0.15.0)

This guide explains how to migrate from the original `hid4flutter` project to the upgraded `hidtool` project.

## Overview

| Aspect | hid4flutter | hidtool | Change |
|--------|-------------|---------|--------|
| hidapi Version | 0.14.0 | 0.15.0 | ⬆️ |
| Build Support | Partial | Complete | ✨ |
| New API | ❌ | ✅ | ⭐ |
| Example Application | ❌ | ✅ | ⭐ |
| Documentation | Basic | Detailed | ⬆️ |

## API Changes

### Backward Compatibility

✅ **Fully Backward Compatible** - All existing hid4flutter APIs are still available

### New Methods (hidapi 0.15.0+)

```dart
// Get report descriptor (New)
Uint8List descriptor = await device.getReportDescriptor();

// Get report lengths (New)
int inputLen = await device.getInputReportLength();
int outputLen = await device.getOutputReportLength();
int featureLen = await device.getFeatureReportLength();

// Get library version (New)
Map<String, int> version = await Hid.getVersion();
```

### New Properties

```dart
// busType property (New) - Identify bus type
int busType = device.busType;
// 0 = USB, 1 = Bluetooth, 2 = I2C, 3 = SPI
```

## Migration Steps

### Step 1: Update Imports

**Before:**
```dart
import 'package:hid4flutter/hid4flutter.dart';
```

**After:**
```dart
import 'package:hidtool/hid4flutter.dart';
```

Or use the updated import method:
```dart
import 'package:hidtool/hid4flutter.dart';

// All classes available:
// - Hid
// - HidDevice
// - HidException
```

### Step 2: Initialization Code Remains Unchanged

```dart
void main() async {
  // This line is still valid
  await Hid.init();
  runApp(const MyApp());
}
```

### Step 3: Update Device Operation Code (Optional)

To use new features, add code:

```dart
// Get new device information
String busTypeStr = device.busType == 0 ? 'USB' : 'Other';
print('Bus Type: $busTypeStr');

// Query report descriptor
try {
  Uint8List descriptor = await device.getReportDescriptor();
  print('Report Descriptor: ${descriptor.length} bytes');
} catch (e) {
  print('Could not get report descriptor: $e');
}

// Check hidapi version
var version = await Hid.getVersion();
print('hidapi: ${version['major']}.${version['minor']}.${version['patch']}');
```

## Build and Deployment Changes

### Windows

**hid4flutter:**
- Requires precompiled hidapi.dll

**hidtool:**
- ✅ Automatically compile from source
- ✅ Complete CMake support
- ✅ No external dependencies

```bash
# Run directly (no extra steps needed)
flutter run
```

### macOS

**hid4flutter:**
- Requires manual Xcode configuration

**hidtool:**
- ✅ Provides build script
- ✅ Automatically generate library files

```bash
cd third_party
./build_macos.sh
flutter run
```

### Linux

**hid4flutter:**
- Requires system libhidapi-hidraw library

**hidtool:**
- ✅ Supports system library
- ✅ Optional local compilation

```bash
# Use system library or compile local version
flutter run
```

## Feature Comparison

### Basic Features (Same)

✅ Device enumeration
✅ Device open/close
✅ Data send/receive
✅ Feature reports
✅ String retrieval
✅ Error handling

### New Features (hidtool)

⭐ Report descriptor retrieval
⭐ Version information query
⭐ Bus type identification
⭐ Report length query
⭐ Complete build support
⭐ Example application
⭐ Detailed documentation

## Common Migration Issues

### Q: Do I need to modify existing code?

**A:** No. All existing code is compatible. You can optionally add new features.

### Q: How do I use the new report descriptor feature?

**A:**
```dart
try {
  Uint8List descriptor = await device.getReportDescriptor();
  // Process descriptor data
} catch (e) {
  print('Error: $e');
}
```

### Q: Can existing hid4flutter applications be directly converted?

**A:** Yes, just change the package name:
```yaml
# In pubspec.yaml
dependencies:
  hidtool: ^1.0.0  # Replace hid4flutter
```

### Q: What if I get compilation errors?

**A:** Refer to the troubleshooting section in [IMPLEMENTATION_GUIDE-EN.md](IMPLEMENTATION_GUIDE-EN.md).

## Performance Improvements

| Aspect | Improvement |
|--------|------------|
| Device Enumeration | Faster enumeration and filtering |
| Error Handling | Clearer error messages |
| Memory Management | Better resource management |
| Build Time | Improved build configuration |

## Differences from hid4flutter

### Project Structure

**hid4flutter:**
```
lib/
├── hid4flutter.dart         # Main Entry Point
├── src/
│   ├── hid_device.dart      # Abstract Class
│   └── desktop/
│       └── hidapi_ffi.dart  # FFI Bindings
```

**hidtool:**
```
lib/
├── hid4flutter.dart         # Compatible Export
├── main.dart                # Example Application (New)
└── src/
    ├── hid_device.dart
    ├── hid_exception.dart   # Improved
    ├── hid_platform_interface.dart
    └── desktop/
        ├── hid_desktop.dart
        ├── hid_device_desktop.dart
        └── hidapi_ffi.dart  # Extended to 0.15.0
```

### Build Configuration

**hid4flutter:**
- Basic CMake configuration
- Partial platform support
- Requires manual configuration

**hidtool:**
- Complete CMake configuration
- Full platform support (Windows/macOS/Linux)
- Automatic build scripts

## Backward Compatibility Guarantee

✅ **100% Backward Compatible**

- All existing APIs remain unchanged
- All parameters and return types consistent
- Does not break existing applications

## Recommended Migration Path

### Phase 1: Seamless Migration (15 minutes)
1. Update package dependencies
2. Update import statements
3. Run application
4. ✅ Done!

### Phase 2: Adopt New Features (Optional)
1. Consult new API documentation
2. Add new code where appropriate
3. Thoroughly test
4. Deploy updates

### Phase 3: Optimize Application (Optional)
1. Use report descriptor to improve device recognition
2. Use version information for compatibility checks
3. Use bus type to optimize UI display
4. Performance and feature testing

## Getting Help

- **API Reference**: [HIDAPI_FFI_REFERENCE.md](HIDAPI_FFI_REFERENCE.md)
- **Implementation Guide**: [IMPLEMENTATION_GUIDE-EN.md](IMPLEMENTATION_GUIDE-EN.md)
- **Quick Reference**: [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
- **Architecture Reference**: [HID4FLUTTER_REFERENCE.md](HID4FLUTTER_REFERENCE.md)

## Summary

| Project | Advantages |
|---------|-----------|
| **hid4flutter** | Original design, stable and flexible |
| **hidtool** | hidapi-0.15.0, complete build support, rich features, detailed documentation |

**Recommendation:** For new projects or projects requiring new features, use **hidtool**.

---

**Migration Status**: ✅ Verified

**Last Updated**: March 26, 2026
