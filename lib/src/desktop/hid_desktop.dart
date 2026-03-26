import 'dart:ffi';

import '../hid_device.dart';
import '../hid_exception.dart';
import '../hid_platform_interface.dart';
import 'hid_device_desktop.dart';
import 'hidapi_ffi.dart';

/// Windows implementation of Hid platform
class HidWindows extends HidDesktop {
  HidWindows(super.hidapi);

  static void registerWith() {
    final hidapi = NativeLibrary(DynamicLibrary.open('hidapi.dll'));
    HidPlatform.instance = HidWindows(hidapi);
  }
}

/// MacOS implementation of Hid platform
class HidMacos extends HidDesktop {
  HidMacos(super.hidapi);

  static void registerWith() {
    final hidapi = NativeLibrary(DynamicLibrary.executable());
    HidPlatform.instance = HidMacos(hidapi);
  }
}

/// Linux implementation of Hid platform
class HidLinux extends HidDesktop {
  HidLinux(super.hidapi);

  static void registerWith() {
    final hidapi = NativeLibrary(DynamicLibrary.open('libhidapi-hidraw.so.0'));
    HidPlatform.instance = HidLinux(hidapi);
  }
}

/// Desktop implementation of Hid platform
class HidDesktop extends HidPlatform {
  HidDesktop(this._hidapi);

  final NativeLibrary _hidapi;

  // Track open devices. Allows to free hidapi resources
  // when all devices get closed.
  final List<HidDevice> _openDevices = [];

  @override
  Future<List<HidDevice>> getDevices({
    int? vendorId,
    int? productId,
    int? usagePage,
    int? usage,
  }) async {
    List<HidDevice> devices = [];

    // HidApi hid_enumerate returns a linked list of device info.
    final pointer = _hidapi.hid_enumerate(vendorId ?? 0, productId ?? 0);

    var current = pointer;
    while (current.address != nullptr.address) {
      final info = current.ref;

      if (usagePage != null && usagePage != info.usage_page) {
        // Skip device
        current = info.next;
        continue;
      }

      if (usage != null && usage != info.usage) {
        // Skip device
        current = info.next;
        continue;
      }

      final device = HidDeviceDesktop(hidapi: _hidapi, info: info);

      // Listen for connection open/close
      device.onOpen(() => _onDeviceOpen(device));
      device.onClose(() => _onDeviceClose(device));

      devices.add(device);

      current = info.next;
    }

    _hidapi.hid_free_enumeration(pointer);

    _exitIfPossible();

    return devices;
  }

  void _onDeviceOpen(HidDevice device) {
    _openDevices.add(device);
  }

  void _onDeviceClose(HidDevice device) {
    _openDevices.remove(device);
    _exitIfPossible();
  }

  void _exitIfPossible() {
    // No more devices open. Free hidapi resources.
    if (_openDevices.isEmpty) {
      _exit();
    }
  }

  void _exit() async {
    if (_hidapi.hid_exit() == -1) {
      throw HidException('HidApi did not exit correctly.');
    }
  }
}

/// Main public API entry point
class Hid {
  static final HidPlatform _platform = HidPlatform.instance;

  /// Initialize HID support (call this on app startup)
  static Future<void> init() async {
    // Initialization is handled by hid_enumerate automatically
  }

  /// Get list of connected HID devices
  ///
  /// Optional parameters to filter devices:
  /// - [vendorId]: USB vendor ID (if not specified, all vendors are included)
  /// - [productId]: USB product ID (if not specified, all products are included)
  /// - [usagePage]: HID usage page (if not specified, all usage pages are included)
  /// - [usage]: HID usage (if not specified, all usages are included)
  static Future<List<HidDevice>> getDevices({
    int? vendorId,
    int? productId,
    int? usagePage,
    int? usage,
  }) async {
    return _platform.getDevices(
      vendorId: vendorId,
      productId: productId,
      usagePage: usagePage,
      usage: usage,
    );
  }

  /// Get HID API version (hidapi 0.15.0+)
  static Future<Map<String, int>> getVersion() async {
    final lib = NativeLibrary(DynamicLibrary.open('hidapi.dll'));
    final versionPtr = lib.hid_version();
    return {
      'major': versionPtr.ref.major,
      'minor': versionPtr.ref.minor,
      'patch': versionPtr.ref.patch,
    };
  }

  /// Get a device by vendor ID and product ID
  ///
  /// Returns the first matching device, or null if no device found
  static Future<HidDevice?> getDevice({
    required int vendorId,
    required int productId,
  }) async {
    final devices = await getDevices(vendorId: vendorId, productId: productId);

    return devices.isNotEmpty ? devices.first : null;
  }
}
