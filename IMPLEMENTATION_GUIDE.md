# HIDtool - 完整的 HID 设备通信 Flutter 应用

这是一个完整的 Flutter 应用程序，使用 **hidapi-0.15.0** 实现跨平台的 HID（人机接口设备）通信。

> **English Version**: [IMPLEMENTATION_GUIDE-EN.md](IMPLEMENTATION_GUIDE-EN.md)

## 项目特性

✅ **完整的 Dart API 层** - 类型安全的 HID 设备接口  
✅ **FFI 绑定** - 直接访问 hidapi-0.15.0 原生库  
✅ **跨平台支持** - Windows、macOS、Linux（带编译配置）  
✅ **hidapi-0.15.0 新功能** - 包括获取报告描述符等  
✅ **示例应用** - 完整的设备列表和交互 UI  

## 目录结构

```
hidtool/
├── lib/
│   ├── main.dart                      # Flutter UI 应用
│   ├── hid4flutter.dart               # 公共 API 入口
│   └── src/
│       ├── hid_device.dart            # HidDevice 抽象类
│       ├── hid_exception.dart         # 异常类
│       ├── hid_platform_interface.dart # 平台接口
│       └── desktop/
│           ├── hid_desktop.dart       # Desktop 实现
│           ├── hid_device_desktop.dart # 设备实现
│           └── hidapi_ffi.dart        # FFI 绑定（hidapi 0.15.0）
├── third_party/
│   ├── hidapi/
│   │   └── hidapi.h                   # hidapi-0.15.0 头文件
│   ├── windows/
│   │   └── hid.c                      # Windows 实现
│   ├── macos/
│   │   └── hid.c                      # macOS 实现
│   ├── linux/
│   │   └── hid.c                      # Linux 实现
│   ├── CMakeLists.txt                 # 库编译配置
│   └── build_macos.sh                 # macOS 编译脚本
├── windows/CMakeLists.txt             # Windows 编译配置
├── macos/                             # macOS 项目文件
├── linux/CMakeLists.txt               # Linux 编译配置
└── pubspec.yaml                       # Flutter 依赖配置
```

## 快速开始

### 1. 环境要求

- Flutter 3.10.4 或以上
- Dart SDK 3.10.4 或以上
- 平台特定的编译工具：
  - **Windows**: Visual Studio 2022（CMake、MSVC、Windows SDK）
  - **macOS**: Xcode 13+（Command Line Tools）
  - **Linux**: GCC、CMake、libhidapi-hidraw0-dev

### 2. 安装依赖

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
# 确保安装了 Xcode command line tools
xcode-select --install

# 使用 Homebrew 安装依赖（可选）
brew install cmake ninja
```

#### Windows
- 安装 Visual Studio 2022 Community（勾选 C++ 工作负载）
- 安装 CMake
- 安装 Flutter SDK

### 3. 获取项目依赖

```bash
cd /Users/admin/Development/hidtool
flutter pub get
```

### 4. 运行应用

#### Windows
```bash
flutter run -v
```

#### macOS  
在构建之前，需要编译 hidapi 库：
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

## API 使用指南

### 初始化

```dart
void main() async {
  // 初始化 HID 系统
  await Hid.init();
  runApp(const MyApp());
}
```

### 获取设备列表

```dart
import 'package:hidtool/hid4flutter.dart';

// 获取所有设备
List<HidDevice> devices = await Hid.getDevices();

// 按 VID/PID 过滤
List<HidDevice> myDevices = await Hid.getDevices(
  vendorId: 0x1234,
  productId: 0x5678,
);

// 获取特定设备
HidDevice? device = await Hid.getDevice(
  vendorId: 0x1234,
  productId: 0x5678,
);
```

### 与设备通信

```dart
// 打开设备
await device.open();

// 发送报告
import 'dart:typed_data';
var data = Uint8List.fromList([0x00, 0x01, 0x02]);
await device.sendReport(data);

// 接收报告
var received = await device.receiveReport(64, timeout: Duration(seconds: 2));

// 发送特性报告
await device.sendFeatureReport(data);

// 获取特性报告
var feature = await device.getFeatureReport(64);

// 获取报告描述符（hidapi 0.15.0+）
var descriptor = await device.getReportDescriptor();

// 关闭设备
await device.close();
```

### 查询设备信息

```dart
// 基本信息
int vid = device.vendorId;          // USB Vendor ID
int pid = device.productId;         // USB Product ID
String serial = device.serialNumber; // 序列号
String product = device.productName; // 产品名称
String mfg = device.manufacturer;    // 制造商

// HID 信息
int usagePage = device.usagePage;   // HID Usage Page
int usage = device.usage;            // HID Usage
int busType = device.busType;        // 总线类型（USB/蓝牙/I2C/SPI）

// 报告长度（hydapi 0.15.0+）
int inputLen = await device.getInputReportLength();
int outputLen = await device.getOutputReportLength();
int featureLen = await device.getFeatureReportLength();
```

### 获取版本信息

```dart
// 获取 hidapi 版本（0.15.0+）
Map<String, int> version = await Hid.getVersion();
print('hidapi version: ${version['major']}.${version['minor']}.${version['patch']}');
```

## hidapi-0.15.0 新增功能

这个项目实现了 hidapi-0.15.0 中的所有新功能：

1. **`hid_get_report_descriptor()`** - 获取原始报告描述符字节
2. **`hid_version()`** - 查询 hidapi 库版本
3. **增强的错误处理** - 更好的错误消息
4. **改进的设备枚举** - 更可靠的设备检测
5. **Bus Type 支持** - 识别总线类型（USB、蓝牙等）

## 编译细节

### Windows 编译

Windows 实现使用 Windows HID API（hid.dll 和 setupapi.lib）：

```bash
# 在 Visual Studio 中编译
cmake -G "Visual Studio 17 2022" -B build
cmake --build build --config Release
```

### macOS 编译

macOS 实现使用 IOKit 框架：

```bash
# 使用编译脚本
cd third_party
./build_macos.sh

# 脚本会生成 dist/libhidapi.a
```

### Linux 编译

Linux 实现使用 hidraw（/dev/hidraw*）：

```bash
# CMake 会自动检测并链接 libudev
cmake -B build
cmake --build build
```

## 原生代码集成

### 库位置

- **Windows**：使用系统的 hid.dll（Windows HID API）
- **macOS**：[需要手动编译或下载预编译库](https://github.com/libusb/hidapi/releases)
- **Linux**：系统 libhidapi-hidraw

### 环境变量

可以通过环境变量指定 hidapi 库位置：

```bash
# Linux
export LD_LIBRARY_PATH=/path/to/hidapi:$LD_LIBRARY_PATH

# macOS  
export DYLD_LIBRARY_PATH=/path/to/hidapi:$DYLD_LIBRARY_PATH
```

## 故障排除

### "Failed to load hidapi library"

**原因**：找不到 hidapi 库

**解决**：
- **Linux**：安装 `libhidapi-hidraw0` 包
- **macOS**：运行 `third_party/build_macos.sh` 编译库
- **Windows**：确保 Windows 10/11 并安装了所有系统更新

### 设备不可见

**原因**：权限问题或驱动程序问题

**解决**：
- **Linux**：添加 udev 规则或以 root 权限运行
- **macOS**：检查系统隐私设置
- **Windows**：以管理员身份运行应用

### 编译失败

**原因**：缺少编译工具

**解决**：
- **Linux**：`sudo apt-get install build-essential cmake`
- **macOS**：`xcode-select --install`
- **Windows**：安装 Visual Studio Build Tools

## 测试

项目包含一个完整的示例 UI 应用：

```bash
flutter run
```

应用将：
1. 扫描所有连接的 HID 设备
2. 在列表中显示设备信息
3. 允许打开/关闭设备
4. 允许发送测试报告
5. 显示任何错误消息

## 生产使用建议

1. **添加错误处理**：使用 try-catch 和 HidException
2. **资源清理**：确保在 dispose() 中关闭设备
3. **权限检查**：在 Android/iOS 上实现权限请求
4. **超时设置**：为长时间操作设置适当的超时
5. **日志记录**：实现详细的日志记录用于调试
6. **测试覆盖**：添加单元测试和集成测试

## 许可证

MIT License - 详见 LICENSE 文件

## 参考资源

- [hidapi GitHub](https://github.com/libusb/hidapi)
- [hidapi-0.15.0 Release](https://github.com/libusb/hidapi/releases/tag/hidapi-0.15.0)
- [Flutter FFI](https://dart.dev/guides/libraries/c-interop)
- [HID 规范](https://www.usb.org/hid)

## 支持

对于问题或改进建议，请提交 Issue 或 Pull Request。
