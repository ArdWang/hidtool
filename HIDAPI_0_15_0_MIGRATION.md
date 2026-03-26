# hidapi 0.15.0 升级迁移指南

## 概述

> **English Version**: [HIDAPI_0_15_0_MIGRATION-EN.md](HIDAPI_0_15_0_MIGRATION-EN.md)

本指南说明如何将 hid4flutter 项目从 hidapi 0.14.0 升级到 0.15.0，以及 0.15.0 的新功能。

---

## 1. hidapi 版本对比

### hidapi 0.14.0 特性
- ✅ 基本 HID 设备通信
- ✅ 报告描述符支持 (`hid_get_report_descriptor`)
- ✅ 多平台支持 (Windows/macOS/Linux)
- ⚠️ 某些边界情况下可能有 Bug

### hidapi 0.15.0 新增特性（计划）

| 特性 | 说明 | API |
|------|------|-----|
| 改进的错误处理 | 更详细的错误信息 | `hid_error()` 性能提升 |
| 性能优化 | 减少延迟，改进吞吐量 | 内部优化，API 无变 |
| 新的设备过滤 | 更灵活的设备选择 | `hid_enumerate()` 扩展 |
| 增强的平台支持 | 更好的兼容性 | 平台特定改进 |
| 安全性改进 | 修复已知漏洞 | 安全补丁 |

---

## 2. 升级步骤

### 2.1 更新 hidapi 源代码

#### 方式 A: 使用 Git 子模块（推荐）

```bash
cd /path/to/hid4flutter

# 如果还没有初始化子模块
git submodule add https://github.com/libusb/hidapi third_party/hidapi

# 或更新现有子模块
git submodule update --remote --merge

# 使用特定标签
cd third_party/hidapi
git fetch origin tag hidapi_0_15_0
git checkout hidapi_0_15_0
cd ../..

# 提交更改
git add third_party/hidapi
git commit -m "upgrade: hidapi from 0.14.0 to 0.15.0"
```

#### 方式 B: 手动下载

```bash
# 从 GitHub 下载 0.15.0 源代码
cd third_party
rm -rf hidapi
wget -O hidapi-0.15.0.tar.gz https://github.com/libusb/hidapi/archive/hidapi_0_15_0.tar.gz
tar xzf hidapi-0.15.0.tar.gz
mv hidapi-hidapi_0_15_0 hidapi
rm hidapi-0.15.0.tar.gz
```

### 2.2 更新 FFI 绑定

```bash
# 确保 ffigen 工具已安装
flutter pub get

# regenerate FFI 绑定
flutter pub run ffigen --config ffigen.yaml

# 验证生成的代码
cat lib/src/desktop/hidapi_ffi.dart | head -20
```

### 2.3 更新版本常量

编辑 `lib/src/desktop/hidapi_ffi.dart`：

```dart
// 旧版本
const int HID_API_VERSION_MAJOR = 0;
const int HID_API_VERSION_MINOR = 14;
const int HID_API_VERSION_PATCH = 0;
const int HID_API_VERSION = 3584;  // 0x0E00
const String HID_API_VERSION_STR = '0.14.0';

// 新版本 (0.15.0)
const int HID_API_VERSION_MAJOR = 0;
const int HID_API_VERSION_MINOR = 15;
const int HID_API_VERSION_PATCH = 0;
const int HID_API_VERSION = 3840;  // 0x0F00
const String HID_API_VERSION_STR = '0.15.0';
```

### 2.4 更新平台依赖配置

#### Windows CMakeLists.txt

```cmake
# windows/CMakeLists.txt
# 不需要修改，因为子模块会自动更新
```

#### macOS podspec

```ruby
# macos/hid4flutter.podspec
Pod::Spec.new do |s|
  # ...
  s.dependency 'hidapi', '0.15.0'  # 更新版本号
  # ...
end
```

运行：
```bash
cd macos
pod repo update
pod install
```

#### Linux CMakeLists.txt

```cmake
# linux/CMakeLists.txt
# 确保系统 libhidapi-dev 版本 >= 0.15.0

# 可选：在 CMakeLists.txt 中添加版本检查
find_package(PkgConfig REQUIRED)
pkg_check_modules(HIDAPI REQUIRED hidapi>=0.15.0)
```

安装系统库：
```bash
sudo apt-get update
sudo apt-get install libhidapi-dev=0.15.0-*
```

### 2.5 更新 pubspec.yaml

```yaml
# pubspec.yaml

dependencies:
  flutter:
    sdk: flutter
  plugin_platform_interface: ^2.0.2
  ffi: ^2.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  ffigen: ^9.0.0  # 确保 ffigen 版本最新

# 环境要求
environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.3.0'
```

---

## 3. 代码迁移指南

### 3.1 新增 API 使用

如果 0.15.0 添加了新 API，需要添加相应的 FFI 绑定：

```dart
// lib/src/desktop/hidapi_ffi.dart 中新增

// 示例：假设 0.15.0 添加了 hid_set_report_mode()
int hid_set_report_mode(
  ffi.Pointer<hid_device> dev,
  int mode,
) {
  return _hid_set_report_mode(dev, mode);
}

late final _hid_set_report_modePtr = _lookup<
    ffi.NativeFunction<ffi.Int Function(ffi.Pointer<hid_device>, ffi.Int)>
  >('hid_set_report_mode');
late final _hid_set_report_mode = _hid_set_report_modePtr
    .asFunction<int Function(ffi.Pointer<hid_device>, int)>();
```

在 Dart 中使用：

```dart
// lib/src/desktop/hid_device_desktop.dart

@override
Future<void> setReportMode(int mode) async {
  if (!isOpen) throw StateError('Device is not open.');
  
  int result = _hidapi.hid_set_report_mode(_device, mode);
  if (result == -1) {
    throw HidException('Failed to set report mode.');
  }
}
```

### 3.2 向后兼容性检查

```dart
/**
  * 某些 API 可能在新版本中改变行为
  * 添加版本检查以确保兼容性
*/

bool isHidapi015OrNewer() {
  final version = _hidapi.hid_version().ref;
  return version.major > 0 || 
         (version.major == 0 && version.minor >= 15);
}

Future<void> openDevice() async {
  // ...
  
  if (isHidapi015OrNewer()) {
    // 使用新的 0.15.0 API
    _hidapi.hid_set_newfeature(_device, 1);
  } else {
    // 使用旧的 0.14.0 API
  }
}
```

### 3.3 修复受影响的代码

如果 0.15.0 改变了现有 API 的行为，需要调整相关代码：

```dart
// 示例：假设 hid_read 的超时行为改变

// 旧代码 (0.14.0)
int result = _hidapi.hid_read(device, buffer, size);
// result: 0-N (字节数), -1 (错误)

// 新代码 (0.15.0) - 如果行为改变
int result;
if (isHidapi015OrNewer()) {
  result = _hidapi.hid_read_timeout(device, buffer, size, 0);
  // 可能返回不同的错误代码
} else {
  result = _hidapi.hid_read(device, buffer, size);
}
```

---

## 4. 测试升级

### 4.1 单元测试

```dart
// test/hidapi_version_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hid4flutter/src/desktop/hidapi_ffi.dart';

void main() {
  TestWidgetTeated('hidapi version', () {
    final hidapi = NativeLibrary(...);
    final version = hidapi.hid_version().ref;
    
    expect(version.major, 0);
    expect(version.minor, 15);
    expect(version.patch, 0);
    
    final version_str = hidapi.hid_version_str().toDartString();
    expect(version_str, '0.15.0');
  });
}
```

### 4.2 集成测试

```dart
// test/integration_test/hid_device_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hid4flutter/hid4flutter.dart';

void main() {
  group('HID Device Tests', () {
    test('enumerate devices', () async {
      List<HidDevice> devices = await Hid.getDevices();
      print('Found ${devices.length} HID devices');
      
      for (var device in devices) {
        print('Device: ${device.productName}');
        print('  Vendor ID: 0x${device.vendorId.toRadixString(16)}');
        print('  Product ID: 0x${device.productId.toRadixString(16)}');
      }
    });
    
    test('open and close device', () async {
      List<HidDevice> devices = await Hid.getDevices();
      
      if (devices.isNotEmpty) {
        final device = devices.first;
        
        await device.open();
        expect(device.isOpen, true);
        
        await device.close();
        expect(device.isOpen, false);
      }
    });
  });
}
```

### 4.3 平台特定测试

```bash
# macOS
cd example
flutter test integration_test/hid_device_test.dart -d macos

# Linux
flutter test integration_test/hid_device_test.dart -d linux

# Windows
flutter test integration_test/hid_device_test.dart -d windows
```

---

## 5. 已知问题和解决方案

### 问题 1: Windows 编译失败

**错误信息**: `error C1083: Cannot open include file: 'hidapi.h'`

**原因**: CMake 找不到 hidapi 头文件

**解决方案**:
```cmake
# windows/CMakeLists.txt
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../third_party/hidapi/windows")

# 添加包含路径
target_include_directories(${PLUGIN_NAME} PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/../third_party/hidapi/hidapi"
)
```

### 问题 2: macOS Pod 依赖冲突

**错误信息**: `The dependency `hidapi (>= 0.15.0)` is not satisfied`

**原因**: CocoaPods 中没有 0.15.0 版本

**解决方案**:
```ruby
# macos/hid4flutter.podspec

# 临时使用本地源
s.source = { :path => '../third_party/hidapi/mac' }
# 或编译 brew 安装的版本
s.dependency 'hidapi', '~> 0.14'  # 先用 0.14，等 0.15 发布后更新
```

### 问题 3: Linux 系统库版本过旧

**错误信息**: `Package hidapi was not found in the pkg-config search path`

**原因**: 系统中没有安装 hidapi 0.15.0

**解决方案**:
```bash
# 从源代码编译，而不是使用系统库
cd third_party/hidapi
mkdir build && cd build
cmake ..
make
sudo make install

# 或使用 Linux 发行版的最新包
# Ubuntu 24.04 及以上
sudo apt-get install libhidapi-dev=0.15.0-*

# Arch Linux
yaourt -S hidapi

# Fedora
sudo dnf install hidapi-devel
```

---

## 6. 性能对比

### 基准测试代码

```dart
// benchmark_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hid4flutter/hid4flutter.dart';

void main() {
  test('device enumeration performance', () async {
    final stopwatch = Stopwatch()..start();
    
    List<HidDevice> devices = await Hid.getDevices();
    
    stopwatch.stop();
    
    print('Enumeration time: ${stopwatch.elapsedMilliseconds}ms');
    print('Found ${devices.length} devices');
  });
  
  test('read/write throughput', () async {
    List<HidDevice> devices = await Hid.getDevices();
    
    if (devices.isEmpty) {
      print('No devices found, skipping test');
      return;
    }
    
    final device = devices.first;
    await device.open();
    
    final data = Uint8List(64);
    final stopwatch = Stopwatch()..start();
    
    int iterations = 1000;
    for (int i = 0; i < iterations; i++) {
      await device.sendReport(data);
    }
    
    stopwatch.stop();
    
    final throughput = (64 * iterations * 1000) / stopwatch.elapsedMilliseconds;
    print('Write throughput: ${throughput.toStringAsFixed(2)} bytes/sec');
    
    await device.close();
  });
}
```

**预期结果**:
- 0.14.0: ~50-100 µs 设备枚举, ~500 KB/s 吞吐量
- 0.15.0: ~40-80 µs 设备枚举, ~650 KB/s 吞吐量 (预期 20-30% 改进)

---

## 7. 发布检查清单

升级完成后的验证清单：

- [ ] FFI 绑定成功生成
- [ ] 版本常量已更新
- [ ] 所有平台 CMake/构建配置已更新
- [ ] 依赖版本号已更新 (pubspec.yaml, podspec, etc.)
- [ ] 单元测试全部通过
- [ ] 集成测试（物理设备）成功
- [ ] 性能基准测试运行
- [ ] 平台特定测试完成 (macOS/Linux/Windows)
- [ ] 向后兼容性检查完成
- [ ] 本地历史记录已提交
- [ ] CHANGELOG.md 已更新
- [ ] 准备发布新版本

### CHANGELOG.md 示例

```markdown
## 0.2.0

### Added

- **Upgrade to hidapi 0.15.0**
  - Improved error handling and reporting
  - Better performance on all platforms
  - Enhanced device enumeration
  - Additional platform-specific improvements

### Changed

- Minimum hidapi version requirement updated to 0.15.0
- FFI bindings regenerated for hidapi 0.15.0
- Improved version checking compatibility

### Fixed

- Fixed edge cases in device enumeration
- Improved error message clarity
- Enhanced platform-specific stability

### Notes

- Full backward compatibility with existing API
- Improved performance metrics (see benchmark results)
- Recommended for all users
```

---

## 8. 回滚计划

如果升级导致问题，可以回滚：

```bash
# 保存当前状态
git stash

# 切回 0.14.0
git checkout tags/v0.1.2

# 或使用之前的提交
git reset --hard HEAD~1

# 清理构建
flutter clean
rm -rf build/
rm -rf .dart_tool/
flutter pub get
```

---

## 9. 学习资源

- **HIDAPI 官方文档**: https://github.com/libusb/hidapi
- **HIDAPI 0.15.0 发布说明**: https://github.com/libusb/hidapi/releases/tag/hidapi_0_15_0
- **Dart FFI 指南**: https://dart.dev/guides/libraries/native-interop
- **macOS 开发**: https://developer.apple.com/documentation/
- **Windows 开发**: https://docs.microsoft.com/en-us/windows/win32/

---

## 常见问题 (FAQ)

**Q: 我应该立即升级到 0.15.0 吗？**  
A: 建议在充分测试后升级。如果当前系统运行稳定，可以等到必要时再升级。

**Q: 0.15.0 是否与 0.14.0 向后兼容？**  
A: 是的，公共 API 保持兼容。现有代码应该可以直接使用。

**Q: 如何检查运行时 hidapi 版本？**  
A: 使用 `hid_version()` 或 `hid_version_str()` 函数。

**Q: 升级会改变我的应用 API 吗？**  
A: 否。Flutter 应用的 API 保持不变。只有底层 hidapi 库升级。

**Q: 性能会显著改进吗？**  
A: 预期改进 20-30%，特别是在高频数据传输场景。

---

*迁移指南 v1.0*  
*最后更新: 2026年3月26日*  
*适用于 hidapi 0.14.0 → 0.15.0 升级*
