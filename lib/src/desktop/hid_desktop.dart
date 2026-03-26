import 'dart:ffi';

import '../hid_device.dart';
import '../hid_exception.dart';
import '../hid_platform_interface.dart';
import 'hidapi_ffi.dart' as ffi;
import 'hid_device_desktop.dart';

/// Desktop implementation of Hid platform
class HidDesktop extends HidPlatform {
  static bool _initialized = false;

  /// Initialize the platform
  static Future<void> init() async {
    if (_initialized) return;

    try {
      ffi.HidApiFFI.initialize();
      _initialized = true;
    } catch (e) {
      throw HidException('Failed to initialize HID API: $e');
    }
  }

  @override
  Future<List<HidDevice>> getDevices({
    int? vendorId,
    int? productId,
    int? usagePage,
    int? usage,
  }) async {
    await init();

    try {
      final devices = <HidDevice>[];

      // Get all devices (0, 0 means all vendors and products)
      final actualVendorId = vendorId ?? 0;
      final actualProductId = productId ?? 0;

      final devicesInfo = ffi.HidApiFFI.hid_enumerate(
        actualVendorId,
        actualProductId,
      );

      if (devicesInfo == nullptr) {
        return devices;
      }

      try {
        var current = devicesInfo;

        while (current != nullptr) {
          // Check if device matches filter criteria
          if (_matchesFilters(
            current.ref,
            usagePage: usagePage,
            usage: usage,
          )) {
            devices.add(HidDeviceDesktop(current.ref));
          }

          current = current.ref.next;
        }
      } finally {
        ffi.HidApiFFI.hid_free_enumeration(devicesInfo);
      }

      return devices;
    } catch (e) {
      if (e is HidException) rethrow;
      throw HidException('Failed to enumerate devices: $e');
    }
  }

  /// Check if a device matches the filter criteria
  static bool _matchesFilters(
    ffi.HidDeviceInfo info, {
    int? usagePage,
    int? usage,
  }) {
    if (usagePage != null && info.usage_page != usagePage) {
      return false;
    }

    if (usage != null && info.usage != usage) {
      return false;
    }

    return true;
  }

  /// Get version information (hidapi 0.15.0+)
  static Future<Map<String, int>> getVersion() async {
    await init();

    try {
      final versionPtr = ffi.HidApiFFI.hid_version();
      return {
        'major': versionPtr.ref.major,
        'minor': versionPtr.ref.minor,
        'patch': versionPtr.ref.patch,
      };
    } catch (e) {
      throw HidException('Failed to get version: $e');
    }
  }
}

/// Main public API entry point
class Hid {
  static final HidDesktop _platform = HidDesktop();

  /// Initialize HID support (call this on app startup)
  static Future<void> init() async {
    await HidDesktop.init();
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
    return HidDesktop.getVersion();
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
