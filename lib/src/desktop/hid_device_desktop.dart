import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../hid_device.dart';
import '../hid_exception.dart';
import 'hidapi_ffi.dart' as ffi;

/// Desktop implementation of HidDevice
class HidDeviceDesktop extends HidDevice {
  final String _path;
  final int _vendorId;
  final int _productId;
  final String _serialNumber;
  final int _releaseNumber;
  final String _manufacturer;
  final String _productName;
  final int _usagePage;
  final int _usage;
  final int _interfaceNumber;
  final int _busType;
  Pointer<ffi.HidDeviceHandle>? _deviceHandle;
  StreamController<int>? _inputStreamController;

  /// Create a new HidDeviceDesktop from device info
  HidDeviceDesktop(ffi.HidDeviceInfo info)
    : _path = _copyUtf8String(info.path),
      _vendorId = info.vendor_id,
      _productId = info.product_id,
      _serialNumber = _copyWideString(info.serial_number),
      _releaseNumber = info.release_number,
      _manufacturer = _copyWideString(info.manufacturer_string),
      _productName = _copyWideString(info.product_string),
      _usagePage = info.usage_page,
      _usage = info.usage,
      _interfaceNumber = info.interface_number,
      _busType = info.bus_type;

  static String _copyUtf8String(Pointer<Utf8> pointer) {
    if (pointer == nullptr) {
      return '';
    }

    return pointer.toDartString();
  }

  static String _copyWideString(Pointer<Utf16> pointer) {
    if (pointer == nullptr) {
      return '';
    }

    return pointer.toDartString();
  }

  @override
  String get id => path;

  @override
  String get path => _path;

  @override
  int get vendorId => _vendorId;

  @override
  int get productId => _productId;

  @override
  String get serialNumber => _serialNumber;

  @override
  int get releaseNumber => _releaseNumber;

  @override
  String get manufacturer => _manufacturer;

  @override
  String get productName => _productName;

  @override
  int get usagePage => _usagePage;

  @override
  int get usage => _usage;

  @override
  int get interfaceNumber => _interfaceNumber;

  @override
  int get busType => _busType;

  @override
  bool get isOpen => _deviceHandle != null && _deviceHandle != nullptr;

  /// Open the device
  @override
  Future<void> open() async {
    if (isOpen) return;

    try {
      final pathPtr = path.toNativeUtf8();
      try {
        _deviceHandle = ffi.HidApiFFI.hid_open_path(pathPtr);

        if (_deviceHandle == nullptr) {
          throw HidException('Failed to open device: ${_getErrorString()}');
        }

        // Set nonblocking mode for better control
        ffi.HidApiFFI.hid_set_nonblocking(_deviceHandle!, 0);
      } finally {
        malloc.free(pathPtr);
      }
    } catch (e) {
      _deviceHandle = null;
      if (e is HidException) rethrow;
      throw HidException('Failed to open device: $e');
    }
  }

  /// Close the device
  @override
  Future<void> close() async {
    if (!isOpen) return;

    try {
      // Close input stream if active
      if (_inputStreamController != null) {
        await _inputStreamController!.close();
        _inputStreamController = null;
      }

      if (_deviceHandle != null && _deviceHandle != nullptr) {
        ffi.HidApiFFI.hid_close(_deviceHandle!);
      }
    } finally {
      _deviceHandle = null;
    }
  }

  /// Send an output report to the device
  @override
  Future<void> sendReport(Uint8List data, {int reportId = 0x00}) async {
    if (!isOpen) {
      throw HidException('Device is not open');
    }

    try {
      final buffer = malloc<Uint8>(data.length);
      try {
        // Copy data to native buffer
        buffer.asTypedList(data.length).setAll(0, data);

        // Write to device
        final result = ffi.HidApiFFI.hid_write(
          _deviceHandle!,
          buffer,
          data.length,
        );

        if (result < 0) {
          throw HidException('Failed to write to device: ${_getErrorString()}');
        }

        if (result != data.length) {
          throw HidException(
            'Failed to write all bytes: wrote $result of ${data.length}',
          );
        }
      } finally {
        malloc.free(buffer);
      }
    } catch (e) {
      if (e is HidException) rethrow;
      throw HidException('Failed to send report: $e');
    }
  }

  /// Receive an input report from the device
  @override
  Future<Uint8List> receiveReport(int reportLength, {Duration? timeout}) async {
    if (!isOpen) {
      throw HidException('Device is not open');
    }

    try {
      final buffer = malloc<Uint8>(reportLength);
      try {
        int result;

        if (timeout != null) {
          result = ffi.HidApiFFI.hid_read_timeout(
            _deviceHandle!,
            buffer,
            reportLength,
            timeout.inMilliseconds,
          );
        } else {
          result = ffi.HidApiFFI.hid_read(_deviceHandle!, buffer, reportLength);
        }

        if (result < 0) {
          throw HidException(
            'Failed to read from device: ${_getErrorString()}',
          );
        }

        // Return only the bytes that were actually read
        return Uint8List.fromList(buffer.asTypedList(result).toList());
      } finally {
        malloc.free(buffer);
      }
    } catch (e) {
      if (e is HidException) rethrow;
      throw HidException('Failed to receive report: $e');
    }
  }

  /// Get a feature report from the device
  @override
  Future<Uint8List> getFeatureReport(
    int reportLength, {
    int reportId = 0x00,
  }) async {
    if (!isOpen) {
      throw HidException('Device is not open');
    }

    try {
      final buffer = malloc<Uint8>(reportLength);
      try {
        // Set the report ID in the first byte
        buffer[0] = reportId;

        final result = ffi.HidApiFFI.hid_get_feature_report(
          _deviceHandle!,
          buffer,
          reportLength,
        );

        if (result < 0) {
          throw HidException(
            'Failed to get feature report: ${_getErrorString()}',
          );
        }

        return Uint8List.fromList(buffer.asTypedList(result).toList());
      } finally {
        malloc.free(buffer);
      }
    } catch (e) {
      if (e is HidException) rethrow;
      throw HidException('Failed to get feature report: $e');
    }
  }

  /// Send a feature report to the device
  @override
  Future<void> sendFeatureReport(Uint8List data, {int reportId = 0x00}) async {
    if (!isOpen) {
      throw HidException('Device is not open');
    }

    try {
      final buffer = malloc<Uint8>(data.length);
      try {
        buffer.asTypedList(data.length).setAll(0, data);

        final result = ffi.HidApiFFI.hid_send_feature_report(
          _deviceHandle!,
          buffer,
          data.length,
        );

        if (result < 0) {
          throw HidException(
            'Failed to send feature report: ${_getErrorString()}',
          );
        }
      } finally {
        malloc.free(buffer);
      }
    } catch (e) {
      if (e is HidException) rethrow;
      throw HidException('Failed to send feature report: $e');
    }
  }

  /// Get the HID report descriptor (hidapi 0.15.0+)
  @override
  Future<Uint8List> getReportDescriptor() async {
    if (!isOpen) {
      throw HidException('Device is not open');
    }

    try {
      // Allocate buffer for report descriptor (typically max 4KB)
      const maxDescSize = 4096;
      final buffer = malloc<Uint8>(maxDescSize);
      try {
        final result = ffi.HidApiFFI.hid_get_report_descriptor(
          _deviceHandle!,
          buffer,
          maxDescSize,
        );

        if (result < 0) {
          throw HidException(
            'Failed to get report descriptor: ${_getErrorString()}',
          );
        }

        return Uint8List.fromList(buffer.asTypedList(result).toList());
      } finally {
        malloc.free(buffer);
      }
    } catch (e) {
      if (e is HidException) rethrow;
      throw HidException('Failed to get report descriptor: $e');
    }
  }

  /// Stream of input reports as individual bytes
  @override
  Stream<int> inputStream() {
    _inputStreamController ??= StreamController<int>(
      onListen: () => _startInputReading(),
      onCancel: () => _stopInputReading(),
    );

    return _inputStreamController!.stream;
  }

  void _startInputReading() {
    // Implementation would continuously read from device
    // For now, this is a placeholder
  }

  void _stopInputReading() {
    // Implementation would stop reading
  }

  /// Get an indexed string from the device
  @override
  Future<String> getIndexedString(int index, {int maxLength = 256}) async {
    if (!isOpen) {
      throw HidException('Device is not open');
    }

    try {
      final buffer = malloc<Uint16>(maxLength);
      final bufferPtr = buffer.cast<Utf16>();
      try {
        final result = ffi.HidApiFFI.hid_get_indexed_string(
          _deviceHandle!,
          index,
          bufferPtr,
          maxLength,
        );

        if (result < 0) {
          throw HidException(
            'Failed to get indexed string: ${_getErrorString()}',
          );
        }

        return bufferPtr.toDartString();
      } finally {
        malloc.free(buffer);
      }
    } catch (e) {
      if (e is HidException) rethrow;
      throw HidException('Failed to get indexed string: $e');
    }
  }

  /// Get the number of input reports on the device
  @override
  Future<int> getInputReportLength() async {
    // This would typically be obtained from the report descriptor
    // For now, return a default value
    return 64;
  }

  /// Get the number of output reports on the device
  @override
  Future<int> getOutputReportLength() async {
    // This would typically be obtained from the report descriptor
    return 64;
  }

  /// Get the number of feature reports on the device
  @override
  Future<int> getFeatureReportLength() async {
    // This would typically be obtained from the report descriptor
    return 64;
  }

  String _getErrorString() {
    if (!isOpen) return 'Device not open';

    try {
      final errorPtr = ffi.HidApiFFI.hid_error(_deviceHandle!);
      if (errorPtr == nullptr) return 'Unknown error';
      return errorPtr.toDartString();
    } catch (e) {
      return 'Failed to get error string: $e';
    }
  }
}
