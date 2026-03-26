[中文版本](HIDAPI_FFI_REFERENCE.md) | English

# hidapi FFI Complete Binding Reference

## Quick Query Table

| Function | Description | Parameters | Return Value |
|----------|-------------|-----------|--------------|
| `hid_init()` | Initialize library | - | int (0=success, -1=failure) |
| `hid_exit()` | Cleanup resources | - | int (0=success, -1=failure) |
| `hid_enumerate(int, int)` | Enumerate devices | vendorId, productId | `Pointer<hid_device_info>` |
| `hid_free_enumeration()` | Free enumeration | devs | void |
| `hid_open(int, int, Ptr)` | Open device (VID/PID) | vendorId, productId, serialNumber | `Pointer<hid_device>` |
| `hid_open_path()` | Open device (path) | path | `Pointer<hid_device>` |
| `hid_close()` | Close device | dev | void |
| `hid_write()` | Send data | dev, data, length | int (bytes or -1) |
| `hid_read()` | Receive data | dev, data, length | int (bytes or -1) |
| `hid_read_timeout()` | Receive data (timeout) | dev, data, length, ms | int (bytes or -1) |
| `hid_set_nonblocking()` | Set non-blocking | dev, nonblock | int (0=success, -1=failure) |
| `hid_send_feature_report()` | Send feature report | dev, data, length | int (bytes or -1) |
| `hid_get_feature_report()` | Receive feature report | dev, data, length | int (bytes or -1) |
| `hid_get_input_report()` | Get input report | dev, data, length | int (bytes or -1) |
| `hid_get_device_info()` | Get device info | dev | `Pointer<hid_device_info>` |
| `hid_get_report_descriptor()` | Get report descriptor (0.14+) | dev, buf, buf_size | int (bytes or -1) |
| `hid_get_manufacturer_string()` | Get manufacturer string | dev, string, maxlen | int (0 or -1) |
| `hid_get_product_string()` | Get product string | dev, string, maxlen | int (0 or -1) |
| `hid_get_serial_number_string()` | Get serial number string | dev, string, maxlen | int (0 or -1) |
| `hid_get_indexed_string()` | Get indexed string | dev, index, string, maxlen | int (0 or -1) |
| `hid_error()` | Get error message | dev | `Pointer<WChar>` |
| `hid_version()` | Get version struct | - | `Pointer<hid_api_version>` |
| `hid_version_str()` | Get version string | - | `Pointer<Char>` |

---

## Detailed API Documentation

### Initialization and Cleanup

#### `int hid_init()`
Initialize the HIDAPI library. Although not required (other functions call it automatically), it's recommended to call explicitly at application startup to reduce latency.

```dart
final hidapi = NativeLibrary(...);

if (hidapi.hid_init() != 0) {
  throw Exception('Failed to initialize HIDAPI');
}

// Use hidapi...

hidapi.hid_exit();
```

#### `int hid_exit()`
Clean up HIDAPI library static data. Should be called before application exit.

---

### Device Enumeration

#### `Pointer<hid_device_info> hid_enumerate(int vendor_id, int product_id)`
Enumerate all HID devices in the system.

**Parameters**:
- `vendor_id`: Vendor ID (0 = any vendor)
- `product_id`: Product ID (0 = any product)

**Return Value**: Pointer to `hid_device_info` linked list (NULL = failure)

**Example**:
```dart
// Get all devices
final devs = hidapi.hid_enumerate(0, 0);

// Iterate through linked list
var current = devs;
while (current.address != nullptr.address) {
  final info = current.ref;
  print('Device: ${info.path.toDartString()}');
  print('Vendor ID: 0x${info.vendor_id.toRadixString(16)}');
  print('Product ID: 0x${info.product_id.toRadixString(16)}');
  current = info.next;  // Next device
}

// Free list memory
hidapi.hid_free_enumeration(devs);
```

#### `void hid_free_enumeration(Pointer<hid_device_info> devs)`
Free the linked list returned by `hid_enumerate()`.

**Must be called to avoid memory leaks**.

---

### Device Open/Close

#### `Pointer<hid_device> hid_open(int vendor_id, int product_id, Pointer<WChar> serial_number)`
Open HID device using VID/PID and optional serial number.

**Parameters**:
- `vendor_id`: Vendor ID
- `product_id`: Product ID
- `serial_number`: Serial number string (NULL = any serial number)

**Return Value**: Device handle (NULL = failure)

**Example**:
```dart
using((arena) {
  // Open specific device
  final device = hidapi.hid_open(0x1234, 0x5678, nullptr);
  
  if (device == nullptr) {
    throw Exception('Failed to open device');
  }
  
  // Use device...
  hidapi.hid_close(device);
});
```

#### `Pointer<hid_device> hid_open_path(Pointer<Char> path)`
Open HID device using device path. Path is typically from `hid_enumerate()`.

**Example**:
```dart
using((arena) {
  final path = '/dev/hidraw0'.toCharPointer(allocator: arena);
  final device = hidapi.hid_open_path(path);
  
  if (device == nullptr) {
    throw Exception('Failed to open device at path');
  }
  
  // Use device...
  hidapi.hid_close(device);
});
```

#### `void hid_close(Pointer<hid_device> dev)`
Close an opened HID device.

**Example**:
```dart
hidapi.hid_close(device);
device = nullptr;  // Clear reference
```

---

### Data Transfer

#### `int hid_write(Pointer<hid_device> dev, Pointer<UnsignedChar> data, int length)`
Send data report to device.

**Parameters**:
- `dev`: Device handle
- `data`: Data buffer (first byte is report ID)
- `length`: Data length (including report ID)

**Return Value**: 
- > 0: Actual bytes written
- -1: Error

**Important**: If device uses numbered reports, `data[0]` must be report ID. If device doesn't use numbered reports, `data[0]` should be 0x00.

**Example**:
```dart
using((arena) {
  final data = arena<UnsignedChar>(65);
  
  // Set report ID and data
  data[0] = 0x00;  // Report ID
  data[1] = 0x12;  // Data byte 1
  data[2] = 0x34;  // Data byte 2
  // ... more data
  
  int bytes_written = hidapi.hid_write(
    device,
    data,
    65
  );
  
  if (bytes_written == -1) {
    print('Error writing to device: ${hidapi.hid_error(device).toDartString()}');
  }
});
```

#### `int hid_read(Pointer<hid_device> dev, Pointer<UnsignedChar> data, int length)`
Read data report from device.

**Parameters**:
- `dev`: Device handle
- `data`: Output buffer
- `length`: Buffer size

**Return Value**:
- > 0: Actual bytes read
- 0: No data available (non-blocking mode)
- -1: Error

**Example**:
```dart
using((arena) {
  final buffer = arena<UnsignedChar>(64);
  
  int bytes_read = hidapi.hid_read(device, buffer, 64);
  
  if (bytes_read > 0) {
    // Process received data
    print('Received $bytes_read bytes');
    for (int i = 0; i < bytes_read; i++) {
      print('data[${i}] = 0x${buffer[i].toString().padLeft(2, '0')}');
    }
  } else if (bytes_read == 0) {
    print('No data available');
  } else {
    print('Error: ${hidapi.hid_error(device).toDartString()}');
  }
});
```

#### `int hid_read_timeout(Pointer<hid_device> dev, Pointer<UnsignedChar> data, int length, int milliseconds)`
Blocking read with timeout.

**Parameters**:
- `milliseconds`: Timeout time (-1 = blocking, 0 = non-blocking)

**Example**:
```dart
using((arena) {
  final buffer = arena<UnsignedChar>(64);
  
  // Wait for at most 1000ms
  int bytes_read = hidapi.hid_read_timeout(
    device,
    buffer,
    64,
    1000  // 1 second timeout
  );
  
  if (bytes_read > 0) {
    // Process data
  } else if (bytes_read == 0) {
    print('Timeout - no data received');
  }
});
```

#### `int hid_set_nonblocking(Pointer<hid_device> dev, int nonblock)`
Set device to blocking or non-blocking mode.

**Parameters**:
- `nonblock`: 1 = non-blocking, 0 = blocking

**Return Value**: 0 = success, -1 = failure

**Example**:
```dart
// Enable non-blocking mode
if (hidapi.hid_set_nonblocking(device, 1) == -1) {
  print('Failed to set non-blocking mode');
}

// Disable non-blocking mode (return to blocking)
hidapi.hid_set_nonblocking(device, 0);
```

---

### Feature Reports

#### `int hid_send_feature_report(Pointer<hid_device> dev, Pointer<UnsignedChar> data, int length)`
Send feature report to device.

**Important**: First byte must be report ID.

**Return Value**: Bytes written (not including report ID) or -1 (failure)

**Example**:
```dart
using((arena) {
  final data = arena<UnsignedChar>(65);
  
  data[0] = 0x02;  // Report ID
  data[1] = 0xAA;  // Feature data
  data[2] = 0xBB;
  
  int result = hidapi.hid_send_feature_report(device, data, 65);
  
  if (result == -1) {
    print('Error: ${hidapi.hid_error(device).toDartString()}');
  }
});
```

#### `int hid_get_feature_report(Pointer<hid_device> dev, Pointer<UnsignedChar> data, int length)`
Get feature report.

**Pre-operation**: 
1. `data[0]` = report ID to read
2. Allocate sufficient buffer for returned data

**Return Value**: Bytes (including report ID) or -1 (failure)

**Example**:
```dart
using((arena) {
  final buffer = arena<UnsignedChar>(65);
  
  buffer[0] = 0x02;  // Request report ID 2
  
  int result = hidapi.hid_get_feature_report(device, buffer, 65);
  
  if (result > 0) {
    // buffer[0] still report ID
    // buffer[1..result-1] feature data
    print('Received $result bytes');
  }
});
```

#### `int hid_get_input_report(Pointer<hid_device> dev, Pointer<UnsignedChar> data, int length)`
Get input report.

**Similar to hid_get_feature_report, but for input reports**.

---

### String Retrieval

#### `int hid_get_manufacturer_string(Pointer<hid_device> dev, Pointer<WChar> string, int maxlen)`
Get manufacturer string.

**Parameters**:
- `string`: Output buffer (wchar_t characters)
- `maxlen`: Buffer size (in wchar_t units)

**Return Value**: 0 = success, -1 = failure

**Example**:
```dart
using((arena) {
  final buffer = arena<WChar>(256);
  
  if (hidapi.hid_get_manufacturer_string(device, buffer, 256) == 0) {
    final manufacturer = buffer.toDartString();
    print('Manufacturer: $manufacturer');
  }
});
```

#### `int hid_get_product_string(Pointer<hid_device> dev, Pointer<WChar> string, int maxlen)`
Get product string.

#### `int hid_get_serial_number_string(Pointer<hid_device> dev, Pointer<WChar> string, int maxlen)`
Get serial number string.

#### `int hid_get_indexed_string(Pointer<hid_device> dev, int string_index, Pointer<WChar> string, int maxlen)`
Get indexed string.

**Parameters**:
- `string_index`: String index (from HID descriptor)

---

### Device Information

#### `Pointer<hid_device_info> hid_get_device_info(Pointer<hid_device> dev)`
Get info struct for an opened device.

**Return Value**: Pointer to device info (NULL = failure)

**Important**: Returned pointer is owned by device handle, should not be freed. Pointer becomes invalid after calling `hid_close()`.

**Example**:
```dart
final info_ptr = hidapi.hid_get_device_info(device);

if (info_ptr != nullptr) {
  final info = info_ptr.ref;
  print('Vendor ID: 0x${info.vendor_id.toRadixString(16)}');
  print('Bus Type: ${info.bus_type}');
}
```

#### `int hid_get_report_descriptor(Pointer<hid_device> dev, Pointer<UnsignedChar> buf, int buf_size)` (v0.14.0+)
Get raw HID report descriptor.

**Parameters**:
- `buf`: Output buffer
- `buf_size`: Buffer size (recommend >= 4096)

**Return Value**: Bytes read or -1 (failure)

**Example**:
```dart
using((arena) {
  final buf = arena<UnsignedChar>(HID_API_MAX_REPORT_DESCRIPTOR_SIZE);
  
  int desc_size = hidapi.hid_get_report_descriptor(
    device,
    buf,
    HID_API_MAX_REPORT_DESCRIPTOR_SIZE
  );
  
  if (desc_size > 0) {
    print('Report descriptor size: $desc_size bytes');
    // Process descriptor...
  }
});
```

---

### Error Handling

#### `Pointer<WChar> hid_error(Pointer<hid_device> dev)`
Get description of last error.

**Parameters**:
- `dev`: Device handle (NULL = get global error)

**Return Value**: Pointer to wide-char error string (never NULL)

**Example**:
```dart
final error_msg = hidapi.hid_error(device).toDartString();
print('Error: $error_msg');
```

---

### Version Information

#### `Pointer<hid_api_version> hid_version()`
Get runtime library version.

**Return Value**: Pointer to `hid_api_version` struct

**Example**:
```dart
final version_ptr = hidapi.hid_version();
final version = version_ptr.ref;

print('HIDAPI Version: ${version.major}.${version.minor}.${version.patch}');
```

#### `Pointer<Char> hid_version_str()`
Get version string.

**Example**:
```dart
final version_str = hidapi.hid_version_str().toDartString();
print('HIDAPI: $version_str');
```

---

## Struct Details

### `hid_device_info`
```dart
final class hid_device_info extends ffi.Struct {
  external ffi.Pointer<ffi.Char> path;                    // Device path
  @ffi.UnsignedShort() external int vendor_id;            // VID
  @ffi.UnsignedShort() external int product_id;           // PID
  external ffi.Pointer<ffi.WChar> serial_number;          // Serial number
  @ffi.UnsignedShort() external int release_number;       // Version
  external ffi.Pointer<ffi.WChar> manufacturer_string;    // Manufacturer
  external ffi.Pointer<ffi.WChar> product_string;         // Product name
  @ffi.UnsignedShort() external int usage_page;           // HID usage page
  @ffi.UnsignedShort() external int usage;                // HID usage
  @ffi.Int() external int interface_number;               // USB interface
  external ffi.Pointer<hid_device_info> next;             // Next in list
  @ffi.Int32() external int bus_type;                     // Bus type
}
```

### `hid_api_version`
```dart
final class hid_api_version extends ffi.Struct {
  @ffi.Int() external int major;
  @ffi.Int() external int minor;
  @ffi.Int() external int patch;
}
```

### Bus Type Constants
```dart
abstract class hid_bus_type {
  static const int HID_API_BUS_UNKNOWN = 0;       // Unknown
  static const int HID_API_BUS_USB = 1;           // USB
  static const int HID_API_BUS_BLUETOOTH = 2;     // Bluetooth
  static const int HID_API_BUS_I2C = 3;           // I2C
  static const int HID_API_BUS_SPI = 4;           // SPI
}
```

---

**Documentation Version**: 1.0  
**Last Updated**: March 26, 2026  
**Accuracy Level**: Complete Reference
