# hid4flutter 项目架构参考

## 项目概述

> **English Version**: [HID4FLUTTER_REFERENCE-EN.md](HID4FLUTTER_REFERENCE-EN.md)

**仓库**: https://github.com/vinsfortunato/hid4flutter  
**版本**: 0.1.2  
**License**: MIT  
**描述**: Flutter 插件，用于从 Flutter 应用程序与 HID（人机接口设备）通信

### 支持平台
- ✅ Windows (完全支持)
- ✅ macOS (完全支持)
- ✅ Linux (完全支持，需手动安装 libhidapi-hidraw0)
- 📋 Android (计划中)
- 📋 Web (计划中)

### 技术栈
- **Desktop**: Windows/macOS/Linux - 使用 hidapi (0.14.0) + Dart FFI
- **Android**: 计划使用 MethodChannel + Android HID
- **Web**: 计划使用 WebHID API

---

## 1. 项目结构

```
hid4flutter/
├── lib/                              # 主要 Dart 代码
│   ├── hid4flutter.dart             # 公共 API 入口
│   └── src/
│       ├── hid_device.dart          # HidDevice 抽象类
│       ├── hid_exception.dart       # 异常类
│       ├── hid_platform_interface.dart  # 平台接口
│       ├── desktop/                 # Desktop 实现
│       │   ├── hid_desktop.dart
│       │   ├── hid_device_desktop.dart
│       │   ├── hidapi_ffi.dart      # FFI 绑定
│       │   └── extensions.dart      # 指针扩展
│       └── android/                 # Android 实现
│           └── hid_android.dart
├── windows/                         # Windows 原生代码
├── macos/                          # macOS 原生代码
├── linux/                          # Linux 原生代码
├── android/                        # Android 原生代码
├── pubspec.yaml                    # Flutter 依赖配置
└── third_party/                    # hidapi 库源代码
```

---

## 2. 主要 Dart API 类和方法

### 2.1 Hid 类（公共入口）

```dart
// lib/hid4flutter.dart
// 导出的公共类
export 'src/hid_device.dart';
export 'src/hid_exception.dart';

class Hid {
  /// 获取连接的 HID 设备列表
  /// 可选过滤参数：vendorId, productId, usagePage, usage
  static Future<List<HidDevice>> getDevices({
    int? vendorId,
    int? productId,
    int? usagePage,
    int? usage,
  })
}
```

### 2.2 HidDevice 抽象类

```dart
// lib/src/hid_device.dart
abstract class HidDevice {
  // ===== 设备属性 =====
  String get id;                    // 唯一标识符（通常是路径）
  String get path;                  // 平台特定的设备路径
  int get vendorId;                 // 设备供应商 ID
  int get productId;                // 设备产品 ID
  String get serialNumber;          // 序列号
  int get releaseNumber;            // 设备版本号（BCD格式）
  String get manufacturer;          // 制造商字符串
  String get productName;           // 产品名称字符串
  int get usagePage;                // HID 用途页面
  int get usage;                    // HID 用途
  int get interfaceNumber;          // USB 接口号
  int get busType;                  // 总线类型（USB/Bluetooth/I2C/SPI）

  // ===== 连接管理 =====
  Future<void> open();              // 打开设备
  bool get isOpen;                  // 检查是否已打开
  Future<void> close();             // 关闭设备

  // ===== 数据读写 =====
  Stream<int> inputStream();        // 输入报告流（字节流）
  Future<Uint8List> receiveReport(
    int reportLength, 
    {Duration? timeout}
  );                                // 接收完整报告
  Future<void> sendReport(
    Uint8List data, 
    {int reportId = 0x00}
  );                                // 发送输出报告

  // ===== 特性报告 =====
  Future<Uint8List> getFeatureReport(
    int reportLength, 
    {int reportId = 0x00}
  );                                // 获取特性报告
  Future<void> sendFeatureReport(
    Uint8List data, 
    {int reportId = 0x00}
  );                                // 发送特性报告

  // ===== 字符串检索 =====
  Future<String> getIndexedString(int index, {int maxLength = 256});
}
```

### 2.3 HidException 类

```dart
// lib/src/hid_exception.dart
class HidException implements Exception {
  final String message;
  HidException(this.message);
  
  @override
  String toString() => 'HidException: $message';
}
```

### 2.4 平台接口

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

## 3. Desktop 实现详解

### 3.1 Platform 实现 (Desktop/hid_desktop.dart)

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
    
    // 遍历链表获取所有设备
    var current = pointer;
    while (current.address != nullptr.address) {
      final info = current.ref;
      
      // 应用过滤条件
      if (usagePage != null && usagePage != info.usage_page) {
        current = info.next;
        continue;
      }
      
      // 创建设备对象
      // ...
    }
  }
}
```

### 3.2 HidDevice 实现 (Desktop/hid_device_desktop.dart)

```dart
// lib/src/desktop/hid_device_desktop.dart

class HidDeviceDesktop extends HidDevice {
  final NativeLibrary _hidapi;
  Pointer<hid_device_> _device = nullptr;

  // ===== 连接管理 =====
  @override
  Future<void> open() async {
    if (isOpen) throw StateError('Device is already open.');
    
    using((arena) {
      _device = _hidapi.hid_open_path(path.toCharPointer(allocator: arena));
      
      if (_device == nullptr) {
        throw HidException('Failed to open hid device.');
      }
      
      // 启用非阻塞模式
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

  // ===== 数据读写 =====
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
        
        // 100 微秒轮询间隔
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

  // ===== 特性报告 =====
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

  // ===== 字符串检索 =====
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

## 4. FFI 绑定详解

### 4.1 FFI 绑定结构 (hidapi_ffi.dart)

```dart
// lib/src/desktop/hidapi_ffi.dart
// 自动生成的 FFI 绑定，通过 ffigen 工具生成

class NativeLibrary {
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) _lookup;
  
  NativeLibrary(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  // ===== 库初始化 =====
  int hid_init()        // 初始化库
  int hid_exit()        // 清理库资源

  // ===== 设备枚举 =====
  ffi.Pointer<hid_device_info> hid_enumerate(int vendor_id, int product_id)
  void hid_free_enumeration(ffi.Pointer<hid_device_info> devs)

  // ===== 设备打开/关闭 =====
  ffi.Pointer<hid_device> hid_open(int vendor_id, int product_id, ffi.Pointer<ffi.WChar> serial_number)
  ffi.Pointer<hid_device> hid_open_path(ffi.Pointer<ffi.Char> path)
  void hid_close(ffi.Pointer<hid_device> dev)

  // ===== 数据传输 =====
  int hid_write(ffi.Pointer<hid_device> dev, ffi.Pointer<ffi.UnsignedChar> data, int length)
  int hid_read(ffi.Pointer<hid_device> dev, ffi.Pointer<ffi.UnsignedChar> data, int length)
  int hid_read_timeout(ffi.Pointer<hid_device> dev, ffi.Pointer<ffi.UnsignedChar> data, int length, int milliseconds)

  // ===== 特性报告 =====
  int hid_send_feature_report(ffi.Pointer<hid_device> dev, ffi.Pointer<ffi.UnsignedChar> data, int length)
  int hid_get_feature_report(ffi.Pointer<hid_device> dev, ffi.Pointer<ffi.UnsignedChar> data, int length)
  int hid_get_input_report(ffi.Pointer<hid_device> dev, ffi.Pointer<ffi.UnsignedChar> data, int length)

  // ===== 设备配置 =====
  int hid_set_nonblocking(ffi.Pointer<hid_device> dev, int nonblock)
  ffi.Pointer<hid_device_info> hid_get_device_info(ffi.Pointer<hid_device> dev)

  // ===== 字符串方法 =====
  int hid_get_manufacturer_string(ffi.Pointer<hid_device> dev, ffi.Pointer<ffi.WChar> string, int maxlen)
  int hid_get_product_string(ffi.Pointer<hid_device> dev, ffi.Pointer<ffi.WChar> string, int maxlen)
  int hid_get_serial_number_string(ffi.Pointer<hid_device> dev, ffi.Pointer<ffi.WChar> string, int maxlen)
  int hid_get_indexed_string(ffi.Pointer<hid_device> dev, int string_index, ffi.Pointer<ffi.WChar> string, int maxlen)

  // ===== 报告描述符（hidapi 0.14.0+ 新增）=====
  int hid_get_report_descriptor(ffi.Pointer<hid_device> dev, ffi.Pointer<ffi.UnsignedChar> buf, int buf_size)

  // ===== 错误处理 =====
  ffi.Pointer<ffi.WChar> hid_error(ffi.Pointer<hid_device> dev)

  // ===== 版本信息 =====
  ffi.Pointer<hid_api_version> hid_version()
  ffi.Pointer<ffi.Char> hid_version_str()
}
```

### 4.2 FFI 结构体定义

```dart
// hidapi 设备信息结构体
final class hid_device_info extends ffi.Struct {
  external ffi.Pointer<ffi.Char> path;           // 平台特定路径
  
  @ffi.UnsignedShort()
  external int vendor_id;                        // 供应商 ID
  
  @ffi.UnsignedShort()
  external int product_id;                       // 产品 ID
  
  external ffi.Pointer<ffi.WChar> serial_number; // 序列号
  
  @ffi.UnsignedShort()
  external int release_number;                   // 版本号 (BCD)
  
  external ffi.Pointer<ffi.WChar> manufacturer_string;  // 制造商
  external ffi.Pointer<ffi.WChar> product_string;       // 产品名称
  
  @ffi.UnsignedShort()
  external int usage_page;                       // HID 用途页面
  
  @ffi.UnsignedShort()
  external int usage;                            // HID 用途
  
  @ffi.Int()
  external int interface_number;                 // USB 接口号
  
  external ffi.Pointer<hid_device_info> next;    // 下一个设备
  
  @ffi.Int32()
  external int bus_type;                         // 总线类型
}

// 版本信息结构
final class hid_api_version extends ffi.Struct {
  @ffi.Int()
  external int major;
  
  @ffi.Int()
  external int minor;
  
  @ffi.Int()
  external int patch;
}

// 不透明设备句柄
final class hid_device_ extends ffi.Opaque {}
typedef hid_device = hid_device_;

// 总线类型常量
abstract class hid_bus_type {
  static const int HID_API_BUS_UNKNOWN = 0;      // 未知
  static const int HID_API_BUS_USB = 1;          // USB
  static const int HID_API_BUS_BLUETOOTH = 2;    // Bluetooth/BLE
  static const int HID_API_BUS_I2C = 3;          // I2C
  static const int HID_API_BUS_SPI = 4;          // SPI
}
```

### 4.3 指针扩展 (extensions.dart)

```dart
// lib/src/desktop/extensions.dart

extension CharPointerToString on Pointer<Char> {
  String toDartString({int? length}) {
    // 将 C char* 指针转换为 Dart 字符串
    // length == null 时读取到 null 终止符
  }
}

extension WCharPointerToString on Pointer<WChar> {
  String toDartString({int? length}) {
    // 将 C wchar_t* 指针转换为 Dart 字符串
  }
}

extension StringToCharPointer on String {
  Pointer<Char> toCharPointer({required Allocator allocator}) {
    // 将 Dart 字符串转换为 C char*
  }
}
```

---

## 5. 原生代码接口

### 5.1 Windows (C++)

**文件**: `windows/hid4flutter_plugin.cpp` 和 `windows/hid4flutter_plugin.h`

```cpp
// windows/hid4flutter_plugin.h
namespace hid4flutter {
  class Hid4flutterPlugin : public flutter::Plugin {
   public:
    static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);
    
    Hid4flutterPlugin();
    virtual ~Hid4flutterPlugin();
    
    void HandleMethodCall(
        const flutter::MethodCall<flutter::EncodableValue> &method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  };
}

// windows/hid4flutter_plugin.cpp
void Hid4flutterPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "hid4flutter",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<Hid4flutterPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}
```

**C API**: `windows/include/hid4flutter/hid4flutter_plugin_c_api.h`

```cpp
extern "C" {
  FLUTTER_PLUGIN_EXPORT void Hid4flutterPluginCApiRegisterWithRegistrar(
      FlutterDesktopPluginRegistrarRef registrar);
}
```

**CMake 配置**: `windows/CMakeLists.txt`

```cmake
cmake_minimum_required(VERSION 3.14)
project(hid4flutter)

# 添加 hidapi 子目录
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../third_party/hidapi")

set(PLUGIN_NAME "hid4flutter_plugin")

list(APPEND PLUGIN_SOURCES
  "hid4flutter_plugin.cpp"
  "hid4flutter_plugin.h"
)

add_library(${PLUGIN_NAME} SHARED
  "include/hid4flutter/hid4flutter_plugin_c_api.h"
  "hid4flutter_plugin_c_api.cpp"
  ${PLUGIN_SOURCES}
)

target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)
target_link_libraries(${PLUGIN_NAME} PRIVATE hidapi::hidapi)

set(hid4flutter_bundled_libraries
  "$<TARGET_FILE:hidapi::hidapi>"
  PARENT_SCOPE
)
```

### 5.2 macOS (Swift)

**文件**: `macos/Classes/Hid4flutterPlugin.swift`

```swift
import Cocoa
import FlutterMacOS

public class Hid4flutterPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "hid4flutter",
      binaryMessenger: registrar.messenger
    )
    let instance = Hid4flutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
```

**CocoaPods 配置**: `macos/hid4flutter.podspec`

```ruby
Pod::Spec.new do |s|
  s.name             = 'hid4flutter'
  s.version          = '0.1.2'
  s.summary          = 'A flutter plugin for HID'
  s.description      = 'Flutter plugin for communicating with HID devices'
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.dependency 'hidapi', '0.14.0'  # hidapi 依赖
  
  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
```

### 5.3 Linux (C)

**文件**: `linux/hid4flutter_plugin.cc`

```c
#include "include/hid4flutter/hid4flutter_plugin.h"
#include <flutter_linux/flutter_linux.h>

struct _Hid4flutterPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(Hid4flutterPlugin, hid4flutter_plugin, g_object_get_type())

static void hid4flutter_plugin_handle_method_call(
    Hid4flutterPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;
  response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  fl_method_call_respond(method_call, response, nullptr);
}

void hid4flutter_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  Hid4flutterPlugin* plugin = HID4FLUTTER_PLUGIN(
      g_object_new(hid4flutter_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "hid4flutter",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      channel, method_call_cb, g_object_ref(plugin), g_object_unref);

  g_object_unref(plugin);
}
```

**CMake 配置**: `linux/CMakeLists.txt`

```cmake
cmake_minimum_required(VERSION 3.10)
project(hid4flutter LANGUAGES CXX)

set(PLUGIN_NAME "hid4flutter_plugin")

list(APPEND PLUGIN_SOURCES "hid4flutter_plugin.cc")

add_library(${PLUGIN_NAME} SHARED ${PLUGIN_SOURCES})

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")

target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)
```

### 5.4 Android (Kotlin)

**文件**: `android/src/main/kotlin/com/github/vinsfortunato/hid4flutter/Hid4flutterPlugin.kt`

```kotlin
package com.github.vinsfortunato.hid4flutter

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class Hid4flutterPlugin: FlutterPlugin, MethodChannel.MethodCallHandler {
  private lateinit var channel: MethodChannel

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(binding.binaryMessenger, "hid4flutter")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    result.notImplemented()
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
```

---

## 6. 编译配置信息

### 6.1 pubspec.yaml 依赖

```yaml
name: hid4flutter
description: A flutter plugin for HID devices

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.3.0'

dependencies:
  flutter:
    sdk: flutter
  plugin_platform_interface: ^2.0.2
  ffi: ^2.1.0                    # C FFI 支持

dev_dependencies:
  flutter_test:
    sdk: flutter
  ffigen: ^9.0.0                 # FFI 生成工具
```

### 6.2 Windows 构建要求

- Visual Studio 2017 或更新版本
- CMake 3.14+
- hidapi 库（自动下载为子模块）

**相关文件**:
- `windows/CMakeLists.txt` - 主 CMake 配置
- `third_party/hidapi/` - hidapi 源代码

### 6.3 macOS 构建要求  

- Xcode 12+
- macOS 10.11+
- CocoaPods

**安装 hidapi** (通过 CocoaPods):
```bash
pod repo update
pod install
```

### 6.4 Linux 构建要求

- CMake 3.10+
- GCC/Clang
- GTK 依赖

**安装 hidapi**:
```bash
sudo apt-get install libhidapi-dev libhidapi-hidraw0
```

### 6.5 FFI 生成流程

FFI 绑定通过 ffigen 工具自动生成：

```bash
flutter pub run ffigen --config ffigen.yaml
```

**ffigen 配置示例** (`ffigen.yaml`):
```yaml
name: NativeLibrary
description: Bindings to hidapi

output: 'lib/src/desktop/hidapi_ffi.dart'

headers:
  entry-points:
    - 'third_party/hidapi/hidapi/hidapi.h'

functions:
  include-all: true
  
structs:
  include-all: true
```

---

## 7. 使用 hidapi 0.15.0 的关键更改

### hidapi 版本历史

- **0.14.0**: 
  - `hid_get_report_descriptor()` 支持
  - 改进的错误处理
  
- **0.15.0** (新增功能，计划支持):
  - 新的 HID 功能
  - 改进的兼容性
  - 性能优化

### 升级步骤

1. **更新 hidapi 子模块**:
   ```bash
   git submodule update --remote third_party/hidapi
   ```

2. **更新 FFI 绑定**:
   ```bash
   flutter pub run ffigen --config ffigen.yaml
   ```

3. **更新版本常量** (`hidapi_ffi.dart`):
   ```dart
   const int HID_API_VERSION_MAJOR = 0;
   const int HID_API_VERSION_MINOR = 15;
   const int HID_API_VERSION_PATCH = 0;
   const int HID_API_VERSION = 3840;
   const String HID_API_VERSION_STR = '0.15.0';
   ```

4. **在原生代码中使用新 API**:
   - Windows: 更新 `windows/CMakeLists.txt`
   - macOS: 更新 `macos/hid4flutter.podspec` 版本号
   - Linux: 系统 libhidapi-dev 需要 0.15.0+

---

## 8. 核心工作流程

### 8.1 设备发现和连接流程

```
Hid.getDevices() 
  ↓
HidPlatform.instance.getDevices()
  ↓
_HidDesktop.getDevices()
  ↓
hid_enumerate(vendorId, productId)  [FFI → hidapi]
  ↓
遍历 hid_device_info 链表
  ↓
为每个设备创建 HidDeviceDesktop 对象
  ↓
返回 List<HidDevice>
  ↓
应用用户指定的过滤条件 (usagePage, usage)
```

### 8.2 数据传输流程

```
device.open()
  ↓
hid_open_path() [FFI]
  ↓
设置非阻塞模式
  ↓
device.sendReport(data)
  ↓
hid_write() [FFI → hidapi]
  ↓
device.inputStream()
  ↓
循环调用 hid_read() [FFI]
  ↓
yield 读取的字节
  ↓
device.close()
  ↓
hid_close() [FFI]
```

---

## 9. 最佳实践建议

### 9.1 内存管理

- 使用 `using()` 和 `Arena` 管理 FFI 内存分配
- 及时调用 `device.close()` 释放资源
- 使用 try-finally 确保资源清理

### 9.2 error 处理

```dart
try {
  await device.open();
  // 使用设备
} on HidException catch (e) {
  print('HID Error: ${e.message}');
} finally {
  if (device.isOpen) {
    await device.close();
  }
}
```

### 9.3 性能优化

- 非阻塞模式 + 轮询 (100 µs 间隔)
- 使用流处理大量数据
- 异步操作不阻塞 UI 线程

### 9.4 跨平台兼容性

- 使用 `DynamicLibrary.open()` 支持多个库名
- 处理平台特定的路径格式
- 测试在实际设备上的连接稳定性

---

## 10. 参考资源

- **Official hidapi**: https://github.com/libusb/hidapi
- **HID 规范**: https://www.usb.org/hid
- **Dart FFI 文档**: https://dart.dev/guides/libraries/native-interop
- **Flutter 插件开发**: https://flutter.dev/develop/packages-and-plugins

---

*文档生成时间: 2026年3月26日*  
*基于 hid4flutter v0.1.2 和 hidapi 0.14.0*
