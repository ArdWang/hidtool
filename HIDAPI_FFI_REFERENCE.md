# hidapi FFI 完整绑定参考

## 快速查询表

> **English Version**: [HIDAPI_FFI_REFERENCE-EN.md](HIDAPI_FFI_REFERENCE-EN.md)

| 函数 | 说明 | 参数 | 返回值 |
|------|------|------|--------|
| `hid_init()` | 初始化库 | - | int (0=成功, -1=失败) |
| `hid_exit()` | 清理资源 | - | int (0=成功, -1=失败) |
| `hid_enumerate(int, int)` | 枚举设备 | vendorId, productId | `Pointer<hid_device_info>` |
| `hid_free_enumeration()` | 释放枚举 | devs | void |
| `hid_open(int, int, Ptr)` | 打开设备 (VID/PID) | vendorId, productId, serialNumber | `Pointer<hid_device>` |
| `hid_open_path()` | 打开设备 (路径) | path | `Pointer<hid_device>` |
| `hid_close()` | 关闭设备 | dev | void |
| `hid_write()` | 发送数据 | dev, data, length | int (字节数或-1) |
| `hid_read()` | 接收数据 | dev, data, length | int (字节数或-1) |
| `hid_read_timeout()` | 接收数据(超时) | dev, data, length, ms | int (字节数或-1) |
| `hid_set_nonblocking()` | 设置非阻塞 | dev, nonblock | int (0=成功, -1=失败) |
| `hid_send_feature_report()` | 发送特性报告 | dev, data, length | int (字节数或-1) |
| `hid_get_feature_report()` | 接收特性报告 | dev, data, length | int (字节数或-1) |
| `hid_get_input_report()` | 获取输入报告 | dev, data, length | int (字节数或-1) |
| `hid_get_device_info()` | 获取设备信息 | dev | `Pointer<hid_device_info>` |
| `hid_get_report_descriptor()` | 获取报告描述符(0.14+) | dev, buf, buf_size | int (字节数或-1) |
| `hid_get_manufacturer_string()` | 获取制造商字符串 | dev, string, maxlen | int (0或-1) |
| `hid_get_product_string()` | 获取产品字符串 | dev, string, maxlen | int (0或-1) |
| `hid_get_serial_number_string()` | 获取序列号字符串 | dev, string, maxlen | int (0或-1) |
| `hid_get_indexed_string()` | 获取索引字符串 | dev, index, string, maxlen | int (0或-1) |
| `hid_error()` | 获取错误信息 | dev | `Pointer<WChar>` |
| `hid_version()` | 获取版本结构 | - | `Pointer<hid_api_version>` |
| `hid_version_str()` | 获取版本字符串 | - | `Pointer<Char>` |

---

## 详细 API 文档

### 初始化和清理

#### `int hid_init()`
初始化 HIDAPI 库。虽然不是必需的（其他函数会自动调用），但建议在应用启动时显式调用以减少延迟。

```dart
final hidapi = NativeLibrary(...);

if (hidapi.hid_init() != 0) {
  throw Exception('Failed to initialize HIDAPI');
}

// 使用 hidapi...

hidapi.hid_exit();
```

#### `int hid_exit()`
清理 HIDAPI 库的静态数据。应在应用退出前调用。

---

### 设备枚举

#### `Pointer<hid_device_info> hid_enumerate(int vendor_id, int product_id)`
枚举系统中所有 HID 设备。

**参数**:
- `vendor_id`: 供应商 ID (0 = 任何供应商)
- `product_id`: 产品 ID (0 = 任何产品)

**返回值**: 指向 `hid_device_info` 链表的指针 (NULL = 失败)

**示例**:
```dart
// 获取所有设备
final devs = hidapi.hid_enumerate(0, 0);

// 遍历链表
var current = devs;
while (current.address != nullptr.address) {
  final info = current.ref;
  print('Device: ${info.path.toDartString()}');
  print('Vendor ID: 0x${info.vendor_id.toRadixString(16)}');
  print('Product ID: 0x${info.product_id.toRadixString(16)}');
  current = info.next;  // 下一个设备
}

// 释放链表内存
hidapi.hid_free_enumeration(devs);
```

#### `void hid_free_enumeration(Pointer<hid_device_info> devs)`
释放 `hid_enumerate()` 返回的链表。

**务必调用以避免内存泄漏**。

---

### 设备打开/关闭

#### `Pointer<hid_device> hid_open(int vendor_id, int product_id, Pointer<WChar> serial_number)`
使用 VID/PID 和可选的序列号打开 HID 设备。

**参数**:
- `vendor_id`: 供应商 ID
- `product_id`: 产品 ID
- `serial_number`: 序列号字符串 (NULL = 任何序列号)

**返回值**: 设备句柄 (NULL = 失败)

**示例**:
```dart
using((arena) {
  // 打开特定设备
  final device = hidapi.hid_open(0x1234, 0x5678, nullptr);
  
  if (device == nullptr) {
    throw Exception('Failed to open device');
  }
  
  // 使用设备...
  hidapi.hid_close(device);
});
```

#### `Pointer<hid_device> hid_open_path(Pointer<Char> path)`
使用设备路径打开 HID 设备。路径通常来自 `hid_enumerate()`。

**示例**:
```dart
using((arena) {
  final path = '/dev/hidraw0'.toCharPointer(allocator: arena);
  final device = hidapi.hid_open_path(path);
  
  if (device == nullptr) {
    throw Exception('Failed to open device at path');
  }
  
  // 使用设备...
  hidapi.hid_close(device);
});
```

#### `void hid_close(Pointer<hid_device> dev)`
关闭已打开的 HID 设备。

**示例**:
```dart
hidapi.hid_close(device);
device = nullptr;  // 清除引用
```

---

### 数据传输

#### `int hid_write(Pointer<hid_device> dev, Pointer<UnsignedChar> data, int length)`
向设备发送数据报告。

**参数**:
- `dev`: 设备句柄
- `data`: 数据缓冲区（第一字节为报告 ID）
- `length`: 数据长度（包括报告 ID）

**返回值**: 
- > 0: 实际写入的字节数
- -1: 错误

**重要**: 如果设备使用编号报告，`data[0]` 必须为报告 ID。如果设备不使用编号报告，`data[0]` 应为 0x00。

**示例**:
```dart
using((arena) {
  final data = arena<UnsignedChar>(65);
  
  // 设置报告 ID 和数据
  data[0] = 0x00;  // 报告 ID
  data[1] = 0x12;  // 数据字节 1
  data[2] = 0x34;  // 数据字节 2
  // ... 更多数据
  
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
从设备读取数据报告。

**参数**:
- `dev`: 设备句柄
- `data`: 输出缓冲区
- `length`: 缓冲区大小

**返回值**:
- > 0: 实际读取的字节数
- 0: 无数据可读（非阻塞模式）
- -1: 错误

**示例**:
```dart
using((arena) {
  final buffer = arena<UnsignedChar>(64);
  
  int bytes_read = hidapi.hid_read(device, buffer, 64);
  
  if (bytes_read > 0) {
    // 处理接收的数据
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
使用超时的阻塞读取。

**参数**:
- `milliseconds`: 超时时间 (-1 = 阻塞, 0 = 非阻塞)

**示例**:
```dart
using((arena) {
  final buffer = arena<UnsignedChar>(64);
  
  // 等待最多 1000ms
  int bytes_read = hidapi.hid_read_timeout(
    device,
    buffer,
    64,
    1000  // 1 second timeout
  );
  
  if (bytes_read > 0) {
    // 处理数据
  } else if (bytes_read == 0) {
    print('Timeout - no data received');
  }
});
```

#### `int hid_set_nonblocking(Pointer<hid_device> dev, int nonblock)`
设置设备为阻塞或非阻塞模式。

**参数**:
- `nonblock`: 1 = 非阻塞, 0 = 阻塞

**返回值**: 0 = 成功, -1 = 失败

**示例**:
```dart
// 启用非阻塞模式
if (hidapi.hid_set_nonblocking(device, 1) == -1) {
  print('Failed to set non-blocking mode');
}

// 禁用非阻塞模式（回到阻塞）
hidapi.hid_set_nonblocking(device, 0);
```

---

### 特性报告

#### `int hid_send_feature_report(Pointer<hid_device> dev, Pointer<UnsignedChar> data, int length)`
发送特性报告到设备。

**重要**: 第一字节必须为报告 ID。

**返回值**: 写入的字节数 (不包括报告 ID) 或 -1 (失败)

**示例**:
```dart
using((arena) {
  final data = arena<UnsignedChar>(65);
  
  data[0] = 0x02;  // 报告 ID
  data[1] = 0xAA;  // 特性数据
  data[2] = 0xBB;
  
  int result = hidapi.hid_send_feature_report(device, data, 65);
  
  if (result == -1) {
    print('Error: ${hidapi.hid_error(device).toDartString()}');
  }
});
```

#### `int hid_get_feature_report(Pointer<hid_device> dev, Pointer<UnsignedChar> data, int length)`
获取特性报告。

**预先操作**: 
1. `data[0]` = 要读取的报告 ID
2. 为返回的数据分配足够的缓冲区

**返回值**: 字节数（包括报告 ID）或 -1 (失败)

**示例**:
```dart
using((arena) {
  final buffer = arena<UnsignedChar>(65);
  
  buffer[0] = 0x02;  // 请求报告 ID 2
  
  int result = hidapi.hid_get_feature_report(device, buffer, 65);
  
  if (result > 0) {
    // buffer[0] 仍为报告 ID
    // buffer[1..result-1] 为特性数据
    print('Received $result bytes');
  }
});
```

#### `int hid_get_input_report(Pointer<hid_device> dev, Pointer<UnsignedChar> data, int length)`
获取输入报告。

**类似于 hid_get_feature_report，但针对输入报告**。

---

### 字符串检索

#### `int hid_get_manufacturer_string(Pointer<hid_device> dev, Pointer<WChar> string, int maxlen)`
获取制造商字符串。

**参数**:
- `string`: 输出缓冲区 (wchar_t 字符)
- `maxlen`: 缓冲区大小 (wchar_t 单位)

**返回值**: 0 = 成功, -1 = 失败

**示例**:
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
获取产品字符串。

#### `int hid_get_serial_number_string(Pointer<hid_device> dev, Pointer<WChar> string, int maxlen)`
获取序列号字符串。

#### `int hid_get_indexed_string(Pointer<hid_device> dev, int string_index, Pointer<WChar> string, int maxlen)`
获取索引字符串。

**参数**:
- `string_index`: 字符串索引 (从 HID 描述符获取)

---

### 设备信息

#### `Pointer<hid_device_info> hid_get_device_info(Pointer<hid_device> dev)`
获取已打开设备的信息结构。

**返回值**: 指向设备信息的指针 (NULL = 失败)

**重要**: 返回的指针由设备句柄拥有，不应被释放。在调用 `hid_close()` 后指针失效。

**示例**:
```dart
final info_ptr = hidapi.hid_get_device_info(device);

if (info_ptr != nullptr) {
  final info = info_ptr.ref;
  print('Vendor ID: 0x${info.vendor_id.toRadixString(16)}');
  print('Bus Type: ${info.bus_type}');
}
```

#### `int hid_get_report_descriptor(Pointer<hid_device> dev, Pointer<UnsignedChar> buf, int buf_size)` (v0.14.0+)
获取原始 HID 报告描述符。

**参数**:
- `buf`: 输出缓冲区
- `buf_size`: 缓冲区大小 (建议 >= 4096)

**返回值**: 读取的字节数或 -1 (失败)

**示例**:
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
    // 处理描述符...
  }
});
```

---

### 错误处理

#### `Pointer<WChar> hid_error(Pointer<hid_device> dev)`
获取最后一个错误的描述。

**参数**:
- `dev`: 设备句柄 (NULL = 获取全局错误)

**返回值**: 指向宽字符错误字符串的指针 (永不为 NULL)

**示例**:
```dart
final error_msg = hidapi.hid_error(device).toDartString();
print('Error: $error_msg');
```

---

### 版本信息

#### `Pointer<hid_api_version> hid_version()`
获取运行时库版本。

**返回值**: 指向 `hid_api_version` 结构的指针

**示例**:
```dart
final version_ptr = hidapi.hid_version();
final version = version_ptr.ref;

print('HIDAPI Version: ${version.major}.${version.minor}.${version.patch}');
```

#### `Pointer<Char> hid_version_str()`
获取版本字符串。

**示例**:
```dart
final version_str = hidapi.hid_version_str().toDartString();
print('HIDAPI: $version_str');
```

---

## 结构体详解

### `hid_device_info`
```dart
final class hid_device_info extends ffi.Struct {
  external ffi.Pointer<ffi.Char> path;                    // 设备路径
  @ffi.UnsignedShort() external int vendor_id;            // VID
  @ffi.UnsignedShort() external int product_id;           // PID
  external ffi.Pointer<ffi.WChar> serial_number;          // 序列号
  @ffi.UnsignedShort() external int release_number;       // 版本号
  external ffi.Pointer<ffi.WChar> manufacturer_string;    // 制造商
  external ffi.Pointer<ffi.WChar> product_string;         // 产品名称
  @ffi.UnsignedShort() external int usage_page;           // HID 用途页面
  @ffi.UnsignedShort() external int usage;                // HID 用途
  @ffi.Int() external int interface_number;               // USB 接口
  external ffi.Pointer<hid_device_info> next;             // 链表下一项
  @ffi.Int32() external int bus_type;                     // 总线类型
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

### 总线类型常量
```dart
abstract class hid_bus_type {
  static const int HID_API_BUS_UNKNOWN = 0;       // 未知
  static const int HID_API_BUS_USB = 1;           // USB
  static const int HID_API_BUS_BLUETOOTH = 2;     // Bluetooth
  static const int HID_API_BUS_I2C = 3;           // I2C
  static const int HID_API_BUS_SPI = 4;           // SPI
}
```

---

## 常见用例代码片段

### 完整的设备打开/使用/关闭流程

```dart
try {
  // 1. 枚举设备
  final devs_ptr = hidapi.hid_enumerate(0x1234, 0x5678);
  
  HidDeviceInfo? target_device;
  var current = devs_ptr;
  
  while (current.address != nullptr.address) {
    final info = current.ref;
    // 查找特定设备
    if (info.usage_page == 0xFF00) {
      target_device = info;
      break;
    }
    current = info.next;
  }
  
  if (target_device == null) {
    throw Exception('Device not found');
  }
  
  // 2. 打开设备
  final device = hidapi.hid_open_path(target_device.path);
  if (device == nullptr) {
    throw Exception('Failed to open device');
  }
  
  // 3. 配置设备
  hidapi.hid_set_nonblocking(device, 1);  // 非阻塞
  
  // 4. 发送数据
  using((arena) {
    final data = arena<UnsignedChar>(65);
    data[0] = 0x00;  // 报告 ID
    data[1] = 0x41;  // 'A'
    
    // 写入数据
    int bytes_written = hidapi.hid_write(device, data, 65);
    
    // 读取数据
    final read_buf = arena<UnsignedChar>(64);
    int bytes_read = hidapi.hid_read(device, read_buf, 64);
  });
  
  // 5. 关闭设备
  hidapi.hid_close(device);
  
  // 6. 释放枚举
  hidapi.hid_free_enumeration(devs_ptr);
  
} catch (e) {
  print('Error: $e');
}
```

### 错误处理最佳实践

```dart
int result = hidapi.hid_write(device, data, length);

if (result == -1) {
  final error = hidapi.hid_error(device).toDartString();
  throw HidException('Write failed: $error');
} else if (result != length) {
  throw HidException('Partial write: wrote $result of $length bytes');
}
```

---

*参考文档 v1.0*  
*基于 hidapi 0.14.0*  
*Dart FFI 绑定参考*
