import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'hid_device.dart';

abstract class HidPlatform extends PlatformInterface {
  /// Constructs a HidPlatform.
  HidPlatform() : super(token: _token);

  static final Object _token = Object();

  static HidPlatform _instance = DesktopHidPlatform();

  /// The default instance of [HidPlatform] to use.
  ///
  /// Defaults to [DesktopHidPlatform].
  static HidPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [HidPlatform] when
  /// they register themselves.
  static set instance(HidPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Get list of connected HID devices
  ///
  /// Optional parameters to filter devices by:
  /// - [vendorId]: USB vendor ID
  /// - [productId]: USB product ID
  /// - [usagePage]: HID usage page
  /// - [usage]: HID usage
  Future<List<HidDevice>> getDevices({
    int? vendorId,
    int? productId,
    int? usagePage,
    int? usage,
  });
}

class DesktopHidPlatform extends HidPlatform {
  late final _hidDesktopImpl = _HidDesktopImpl();

  @override
  Future<List<HidDevice>> getDevices({
    int? vendorId,
    int? productId,
    int? usagePage,
    int? usage,
  }) =>
      _hidDesktopImpl.getDevices(
        vendorId: vendorId,
        productId: productId,
        usagePage: usagePage,
        usage: usage,
      );
}

// Platform-specific implementation will be injected here
class _HidDesktopImpl {
  Future<List<HidDevice>> getDevices({
    int? vendorId,
    int? productId,
    int? usagePage,
    int? usage,
  }) {
    throw UnimplementedError('getDevices() has not been implemented.');
  }
}
