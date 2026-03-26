# 迁移指南：从 hid4flutter (0.14.0) 到 hidtool (0.15.0)

本指南说明如何从原始的 `hid4flutter` 项目迁移到升级的 `hidtool` 项目。

> **English Version**: [MIGRATION_GUIDE-EN.md](MIGRATION_GUIDE-EN.md)

## Overview

| 方面 | hid4flutter | hidtool | 变化 |
|-----|-------------|---------|------|
| hidapi 版本 | 0.14.0 | 0.15.0 | ⬆️ |
| 编译支持 | 部分 | 完整 | ✨ |
| 新 API | ❌ | ✅ | ⭐ |
| 示例应用 | ❌ | ✅ | ⭐ |
| 文档 | 基础 | 详细 | ⬆️ |

## API 变化

### 向后兼容性

✅ **完全向后兼容** - 所有现有的 hid4flutter API 仍然可用

### 新增的方法（hidapi 0.15.0+）

```dart
// 获取报告描述符（新增）
Uint8List descriptor = await device.getReportDescriptor();

// 获取报告长度（新增）
int inputLen = await device.getInputReportLength();
int outputLen = await device.getOutputReportLength();
int featureLen = await device.getFeatureReportLength();

// 获取库版本（新增）
Map<String, int> version = await Hid.getVersion();
```

### 新增的属性

```dart
// busType 属性（新增）- 识别总线类型
int busType = device.busType;
// 0 = USB, 1 = Bluetooth, 2 = I2C, 3 = SPI
```

## 迁移步骤

### Step 1: 更新导入

**之前：**
```dart
import 'package:hid4flutter/hid4flutter.dart';
```

**现在：**
```dart
import 'package:hidtool/hid4flutter.dart';
```

或使用更新的导入方式：
```dart
import 'package:hidtool/hid4flutter.dart';

// 所有类都可用：
// - Hid
// - HidDevice
// - HidException
```

### Step 2: 初始化代码保持不变

```dart
void main() async {
  // 这行代码仍然有效
  await Hid.init();
  runApp(const MyApp());
}
```

### Step 3: 更新设备操作代码（可选）

如果要使用新增功能，添加代码：

```dart
// 获取新的设备信息
String busTypeStr = device.busType == 0 ? 'USB' : 'Other';
print('总线类型：$busTypeStr');

// 查询报告描述符
try {
  Uint8List descriptor = await device.getReportDescriptor();
  print('报告描述符：${descriptor.length} 字节');
} catch (e) {
  print('无法获取报告描述符：$e');
}

// 检查 hidapi 版本
var version = await Hid.getVersion();
print('hidapi: ${version['major']}.${version['minor']}.${version['patch']}');
```

## 编译和部署变化

### Windows

**hid4flutter：** 
- 需要预编译的 hidapi.dll

**hidtool：**
- ✅ 自动从源代码编译
- ✅ 完整的 CMake 支持
- ✅ 无需外部依赖

```bash
# 直接运行（无需额外步骤）
flutter run
```

### macOS

**hid4flutter：**
- 需要手动配置 Xcode

**hidtool：**
- ✅ 提供编译脚本
- ✅ 自动生成库文件

```bash
cd third_party
./build_macos.sh
flutter run
```

### Linux

**hid4flutter：**
- 需要系统 libhidapi-hidraw 库

**hidtool：**
- ✅ 支持系统库
- ✅ 可选的本地编译

```bash
# 使用系统库或编译本地版本
flutter run
```

## 功能对比

### 基础功能（相同）

✅ 设备枚举
✅ 设备打开/关闭
✅ 数据发送/接收
✅ 特性报告
✅ 字符串检索
✅ 错误处理

### 新增功能（hidtool）

⭐ 报告描述符获取
⭐ 版本信息查询
⭐ 总线类型识别
⭐ 报告长度查询
⭐ 完整编译支持
⭐ 示例应用
⭐ 详细文档

## 常见迁移问题

### Q: 我需要修改现有代码吗？

**A:** 不需要。所有现有代码都兼容。可以选择性地添加新功能。

### Q: 如何使用新的报告描述符功能？

**A:** 
```dart
try {
  Uint8List descriptor = await device.getReportDescriptor();
  // 处理描述符数据
} catch (e) {
  print('Error: $e');
}
```

### Q: 原来的 hid4flutter 应用能直接转换吗？

**A:** 是的，只需更改包名：
```yaml
# 在 pubspec.yaml 中
dependencies:
  hidtool: ^1.0.0  # 替代 hid4flutter
```

### Q：编译时出错怎么办？

**A:** 参阅 [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) 中的故障排除部分。

## 性能改进

| 方面 | 改进 |
|-----|------|
| 设备枚举 | 更快的枚举和过滤 |
| 错误处理 | 更清晰的错误消息 |
| 内存管理 | 更好的资源管理 |
| 编译时间 | 改进的编译配置 |

## 与 hid4flutter 的差异

### 项目结构

**hid4flutter：**
```
lib/
├── hid4flutter.dart         # 主入口
├── src/
│   ├── hid_device.dart      # 抽象类
│   └── desktop/
│       └── hidapi_ffi.dart  # FFI 绑定
```

**hidtool：**
```
lib/
├── hid4flutter.dart         # 兼容导出
├── main.dart                # 示例应用（新增）
└── src/
    ├── hid_device.dart
    ├── hid_exception.dart   # 改进
    ├── hid_platform_interface.dart
    └── desktop/
        ├── hid_desktop.dart
        ├── hid_device_desktop.dart
        └── hidapi_ffi.dart  # 扩展到 0.15.0
```

### 编译配置

**hid4flutter：**
- 基础 CMake 配置
- 部分平台支持
- 需要手动配置

**hidtool：**
- 完整的 CMake 配置
- 全平台支持（Windows/macOS/Linux）
- 自动编译脚本

## 向后兼容性保证

✅ **100% 向后兼容**

- 所有现有 API 保持不变
- 所有参数和返回类型一致
- 不破坏现有应用程序

## 推荐迁移路线

### 阶段 1：无缝迁移（15 分钟）
1. 更新包依赖
2. 更新导入语句
3. 运行应用
4. ✅ 完成！

### 阶段 2：采用新功能（可选）
1. 查阅新 API 文档
2. 在适当的地方添加新代码
3. 充分测试
4. 部署更新

### 阶段 3：优化应用（可选）
1. 使用报告描述符改进设备识别
2. 使用版本信息进行兼容性检查
3. 使用总线类型优化 UI 显示
4. 性能和功能测试

## 获取帮助

- **API 参考**: [HIDAPI_FFI_REFERENCE.md](HIDAPI_FFI_REFERENCE.md)
- **实现指南**: [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)
- **快速参考**: [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
- **架构参考**: [HID4FLUTTER_REFERENCE.md](HID4FLUTTER_REFERENCE.md)

## 总结

| 项目 | 优势 |
|-----|------|
| **hid4flutter** | 原始设计、稳定灵活 |
| **hidtool** | hidapi-0.15.0、完整编译支持、丰富功能、详细文档 |

**推荐：** 对于新项目或需要新功能的项目，使用 **hidtool**。

---

**迁移状态**: ✅ 已验证

**最后更新**: 2026年3月26日
