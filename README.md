# hid4flutter 快速参考指南

> 本格式化的快速参考卡，适合在开发过程中随时查阅

> **English Version**: [QUICK_REFERENCE-EN.md](QUICK_REFERENCE-EN.md)


## 快速导航

| 文档 | 内容 | 用途 |
|------|------|------|
| **HID4FLUTTER_REFERENCE.md** | 项目完整架构 | 项目理解、设计参考 |
| **HIDAPI_FFI_REFERENCE.md** | FFI API 详解 | 编写 hidapi 调用代码 |
| **HIDAPI_0_15_0_MIGRATION.md** | 升级指南 | 版本升级、迁移 |
| **这个文件** | 快速查询 | 日常开发速查 |

---

## 🚀 5 分钟快速开始

### 1. 获取设备列表

```dart
import 'package:hid4flutter/hid4flutter.dart';

// 获取所有设备
List<HidDevice> devices = await Hid.getDevices();

// 带过滤条件
List<HidDevice> myDevices = await Hid.getDevices(
  vendorId: 0x1234,      // 供应商 ID
  productId: 0x5678,     // 产品 ID
  usagePage: 0xFF00,     // HID 用途页面
  usage: 0x0001,         // 用途
);

for (var device in myDevices) {
  print('${device.productName} (${device.serialNumber})');
}
```

### 2. 连接和读写数据

```dart
try {
  // 打开设备
  await device.open();
  
  // 发送数据
  var data = Uint8List.fromList([
    0x00,           // 报告 ID
    0x12, 0x34,     // 数据...
  ]);
  await device.sendReport(data);
  
  // 接收数据
  var received = await device.receiveReport(64);
  print('Received: $received');
  
  // 关闭设备
  await device.close();
  
} on HidException catch (e) {
  print('Error: ${e.message}');
}
```

### 3. 流式读取数据

```dart
// 持续读取输入报告
device.inputStream().listen((byte) {
  print('Byte: 0x${byte.toRadixString(16)}');
});
```

---

## 📋 设备属性速查

```dart
HidDevice device = ...;

// 基本信息
device.id              // 唯一标识符
device.path            // 平台特定路径
device.isOpen          // 是否已打开

// 硬件信息
device.vendorId        // VID (16位)
device.productId       // PID (16位)
device.serialNumber    // 序列号字符串
device.releaseNumber   // 版本号 (BCD格式)

// 标识信息
device.manufacturer    // 制造商字符串
device.productName     // 产品名称字符串

// HID 信息
device.usagePage       // HID 用途页面 (16位)
device.usage           // HID 用途 (16位)
device.interfaceNumber // USB 接口号
device.busType         // 总线类型 (0=未知, 1=USB, 2=BT, 3=I2C, 4=SPI)
```

---

## 🔌 API 方法速查

### 连接管理
```dart
Future<void> open()                                    // 打开设备
Future<void> close()                                   // 关闭设备
bool get isOpen                                        // 是否打开
```

### 数据传输
```dart
Future<void> sendReport(Uint8List data, {int reportId = 0x00})
Future<Uint8List> receiveReport(int reportLength, {Duration? timeout})
Stream<int> inputStream()                              // 字节流
```

### 特性报告
```dart
Future<Uint8List> getFeatureReport(int reportLength, {int reportId = 0x00})
Future<void> sendFeatureReport(Uint8List data, {int reportId = 0x00})
```

### 字符串检索
```dart
Future<String> getIndexedString(int index, {int maxLength = 256})
```

---

## 🔧 常见场景代码示例

### 场景 1: 发现特定设备

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

### 场景 2: 连接并发送命令

```dart
Future<List<int>> sendCommand(HidDevice device, List<int> cmd) async {
  try {
    await device.open();
    
    // 发送
    var request = Uint8List.fromList([0x00, ...cmd]);
    await device.sendReport(request);
    
    // 接收
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

### 场景 3: 监听设备连接/断开

```dart
Future<void> monitorDevices() async {
  Set<String> previousIds = {};
  
  while (true) {
    List<HidDevice> current = await Hid.getDevices();
    Set<String> currentIds = {for (var d in current) d.id};
    
    // 检测新连接
    var connected = currentIds.difference(previousIds);
    for (var id in connected) {
      print('Device connected: $id');
    }
    
    // 检测断开
    var disconnected = previousIds.difference(currentIds);
    for (var id in disconnected) {
      print('Device disconnected: $id');
    }
    
    previousIds = currentIds;
    await Future.delayed(Duration(seconds: 1));  // 1秒轮询
  }
}
```

### 场景 4: 获取设备信息

```dart
Future<void> printDeviceInfo(HidDevice device) async {
  print('''
HID 设备信息
===========
产品: ${device.productName}
制造商: ${device.manufacturer}
序列号: ${device.serialNumber}
VID: 0x${device.vendorId.toRadixString(16).padLeft(4, '0')}
PID: 0x${device.productId.toRadixString(16).padLeft(4, '0')}
版本: 0x${device.releaseNumber.toRadixString(16).padLeft(4, '0')}
用途页: 0x${device.usagePage.toRadixString(16).padLeft(4, '0')}
用途: 0x${device.usage.toRadixString(16).padLeft(4, '0')}
总线: ${getBusTypeName(device.busType)}
接口: ${device.interfaceNumber}
路径: ${device.path}
  ''');
}

String getBusTypeName(int busType) {
  return const {
    0: '未知',
    1: 'USB',
    2: 'Bluetooth',
    3: 'I2C',
    4: 'SPI',
  }[busType] ?? '未知';
}
```

---

## ⚠️ 错误处理

### 异常类型

```dart
// HidException - 所有 HID 操作错误
try {
  await device.open();
} on HidException catch (e) {
  print('HID Error: ${e.message}');
}

// StateError - 设备状态错误
try {
  await device.sendReport(data);  // 如果未打开会抛出
} on StateError catch (e) {
  print('State Error: ${e.message}');
}
```

### 错误恢复模式

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
      
      // 等待后重试
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

## 📊 性能优化建议

| 操作 | 耗时 | 优化建议 |
|------|------|---------|
| 设备枚举 | 50-100ms | 缓存结果，后台轮询 |
| 打开设备 | 10-50ms | 提前打开直到就绪 |
| 单次读写 | 1-10ms | 批量操作，使用流 |
| 特性报告 | 5-20ms | 必要时才调用 |

### 最佳实践

```dart
class HidDeviceManager {
  Map<String, HidDevice> _cachedDevices = {};
  late Timer _enumerationTimer;
  
  void initialize() {
    // 后台轮询设备
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

## 🐛 常见问题排查

| 问题 | 原因 | 解决方案 |
|------|------|---------|
| 找不到设备 | VID/PID 错误或设备未连接 | 检查设备管理器，验证 VID/PID |
| 无法打开设备 | 权限不足 | Windows/Mac: 以管理员运行；Linux: 添加 udev 规则 |
| 数据传输失败 | 报告 ID 错误 | 检查设备文档，确认报告格式 |
| 内存泄漏 | 未关闭设备或释放资源 | 使用 finally 块确保 close() 被调用 |
| 超时错误 | 设备响应慢 | 增大超时时间或改用非阻塞模式 |

---

## 📱 平台特定信息

### Windows
- 驱动: 通常自动安装（通用 HID 驱动）
- 权限: 普通用户可访问
- 卸载: 应用退出时自动释放句柄

### macOS
- 驱动: 系统内置支持
- 权限: 用户可访问
- 特殊: 使用 DynamicLibrary.executable() 链接 hidapi

### Linux
- 驱动: 内核 HID 驱动 (内置)
- 权限: 需要 udev 规则或 sudo
- 库: 需要手动安装 libhidapi-hidraw0

```bash
# Linux udev 规则 (/etc/udev/rules.d/99-hidapi.rules)
SUBSYSTEM=="hidraw", MODE="0666"
```

---

## 🔍 调试技巧

### 打印所有设备信息

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

### 监听连接事件

```dart
Future<void> watchConnections() async {
  Set<String> previous = {};
  
  while (true) {
    final current = (await Hid.getDevices()).map((d) => d.path).toSet();
    
    // 新设备
    final added = current.difference(previous);
    for (final path in added) print('Connected: $path');
    
    // 移除设备
    final removed = previous.difference(current);
    for (final path in removed) print('Disconnected: $path');
    
    previous = current;
    await Future.delayed(Duration(seconds: 1));
  }
}
```

---

## 📚 相关资源链接

| 资源 | URL |
|------|-----|
| GitHub 项目 | https://github.com/vinsfortunato/hid4flutter |
| Pub.dev | https://pub.dev/packages/hid4flutter |
| HIDAPI | https://github.com/libusb/hidapi |
| USB HID 规范 | https://www.usb.org/hid |
| Dart FFI | https://dart.dev/guides/libraries/native-interop |
| Flutter 文档 | https://flutter.dev |

---

## 🎯 项目集成检查清单

创建新项目时的确认清单：

- [ ] 添加依赖: `flutter pub add hid4flutter`
- [ ] 导入包: `import 'package:hid4flutter/hid4flutter.dart';`
- [ ] 平台版本检查 (MacOS 10.11+, Windows 7+, Linux GTK3+)
- [ ] 权限配置 (Linux udev 规则，如需要)
- [ ] 错误处理 (try-catch HidException)
- [ ] 资源释放 (finally 块中 device.close())
- [ ] 测试连接与传输
- [ ] 文档注释和用例

---

## 版本信息

| 组件 | 版本 |
|------|------|
| hid4flutter | 0.1.2 |
| hidapi | 0.14.0 (推荐升级到 0.15.0) |
| Flutter | ≥ 3.3.0 |
| Dart | ≥ 3.0.0 |

---

**更新时间**: 2026年3月26日  
**状态**: 完整参考  
**用途**: 日常开发查询 + 学习参考

---

## 快速导航地图

```
┌─ HID4FLUTTER_REFERENCE.md ─┐
│ • 项目架构概览              │
│ • 完整 API 文档             │
│ • 平台实现细节              │
│ • 构建配置信息              │
└─────────────────────────────┘
              ↓
     ┌──────────────────┐
     │  你的项目        │
     │  (开发中)        │
     └──────────────────┘
         ↓          ↓
    请查阅这        查看详细
    个快速指南      API 文档
         ↓          ↓
    快速查询        HIDAPI_
    日常问题        FFI_REFERENCE
                    .md
     ↓
需要升级或
新增功能？
     ↓
HIDAPI_0_15_0_
MIGRATION.md
```

---

**提示**: 书签这个文件，它会是你最常用的参考文档！

