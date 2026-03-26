// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:ffi';

import 'package:ffi/ffi.dart';

/// FFI bindings for hidapi 0.15.0
///
/// This provides low-level access to hidapi functions for HID device communication

// ===== Constants =====

/// Bus type constants
const int HID_BUS_TYPE_USB = 0;
const int HID_BUS_TYPE_BLUETOOTH = 1;
const int HID_BUS_TYPE_I2C = 2;
const int HID_BUS_TYPE_SPI = 3;

/// Maximum length for strings
const int HID_MAX_STRLEN = 256;

// ===== FFI Type Definitions =====

/// hid_device_info structure
final class HidDeviceInfo extends Struct {
  external Pointer<Utf8> path;
  @Uint16()
  external int vendor_id;
  @Uint16()
  external int product_id;
  external Pointer<Utf16> serial_number;
  @Uint16()
  external int release_number;
  external Pointer<Utf16> manufacturer_string;
  external Pointer<Utf16> product_string;
  @Uint16()
  external int usage_page;
  @Uint16()
  external int usage;
  @Int32()
  external int interface_number;
  @Int32()
  external int bus_type;
  external Pointer<HidDeviceInfo> next;
}

/// hid_device opaque struct (we only use the pointer)
typedef HidDeviceHandle = Void;

/// hid_device_open function signature
typedef HidDeviceOpenNative =
    Pointer<HidDeviceHandle> Function(
      Int32 vendor_id,
      Int32 product_id,
      Pointer<Utf16> serial_number,
    );

typedef HidDeviceOpen =
    Pointer<HidDeviceHandle> Function(
      int vendor_id,
      int product_id,
      Pointer<Utf16> serial_number,
    );

/// hid_device_open_path function signature
typedef HidDeviceOpenPathNative =
    Pointer<HidDeviceHandle> Function(Pointer<Utf8> path);
typedef HidDeviceOpenPath =
    Pointer<HidDeviceHandle> Function(Pointer<Utf8> path);

/// hid_device_close function signature
typedef HidDeviceCloseNative = Void Function(Pointer<HidDeviceHandle> device);
typedef HidDeviceClose = void Function(Pointer<HidDeviceHandle> device);

/// hid_write function signature
typedef HidWriteNative =
    Int32 Function(
      Pointer<HidDeviceHandle> device,
      Pointer<Uint8> data,
      Size length,
    );
typedef HidWrite =
    int Function(
      Pointer<HidDeviceHandle> device,
      Pointer<Uint8> data,
      int length,
    );

/// hid_read function signature
typedef HidReadNative =
    Int32 Function(
      Pointer<HidDeviceHandle> device,
      Pointer<Uint8> buf,
      Size length,
    );
typedef HidRead =
    int Function(
      Pointer<HidDeviceHandle> device,
      Pointer<Uint8> buf,
      int length,
    );

/// hid_read_timeout function signature
typedef HidReadTimeoutNative =
    Int32 Function(
      Pointer<HidDeviceHandle> device,
      Pointer<Uint8> buf,
      Size length,
      Int32 milliseconds,
    );
typedef HidReadTimeout =
    int Function(
      Pointer<HidDeviceHandle> device,
      Pointer<Uint8> buf,
      int length,
      int milliseconds,
    );

/// hid_set_nonblocking function signature
typedef HidSetNonblockingNative =
    Int32 Function(Pointer<HidDeviceHandle> device, Int32 nonblock);
typedef HidSetNonblocking =
    int Function(Pointer<HidDeviceHandle> device, int nonblock);

/// hid_send_feature_report function signature
typedef HidSendFeatureReportNative =
    Int32 Function(
      Pointer<HidDeviceHandle> device,
      Pointer<Uint8> data,
      Size length,
    );
typedef HidSendFeatureReport =
    int Function(
      Pointer<HidDeviceHandle> device,
      Pointer<Uint8> data,
      int length,
    );

/// hid_get_feature_report function signature
typedef HidGetFeatureReportNative =
    Int32 Function(
      Pointer<HidDeviceHandle> device,
      Pointer<Uint8> buf,
      Size length,
    );
typedef HidGetFeatureReport =
    int Function(
      Pointer<HidDeviceHandle> device,
      Pointer<Uint8> buf,
      int length,
    );

/// hid_enumerate function signature
typedef HidEnumerateNative =
    Pointer<HidDeviceInfo> Function(Int32 vendor_id, Int32 product_id);
typedef HidEnumerate =
    Pointer<HidDeviceInfo> Function(int vendor_id, int product_id);

/// hid_free_enumeration function signature
typedef HidFreeEnumerationNative = Void Function(Pointer<HidDeviceInfo> devs);
typedef HidFreeEnumeration = void Function(Pointer<HidDeviceInfo> devs);

/// hid_get_manufacturer_string function signature
typedef HidGetManufacturerStringNative =
    Int32 Function(
      Pointer<HidDeviceHandle> device,
      Pointer<Utf16> string,
      Size max_length,
    );
typedef HidGetManufacturerString =
    int Function(
      Pointer<HidDeviceHandle> device,
      Pointer<Utf16> string,
      int max_length,
    );

/// hid_get_product_string function signature
typedef HidGetProductStringNative =
    Int32 Function(
      Pointer<HidDeviceHandle> device,
      Pointer<Utf16> string,
      Size max_length,
    );
typedef HidGetProductString =
    int Function(
      Pointer<HidDeviceHandle> device,
      Pointer<Utf16> string,
      int max_length,
    );

/// hid_get_serial_number_string function signature
typedef HidGetSerialNumberStringNative =
    Int32 Function(
      Pointer<HidDeviceHandle> device,
      Pointer<Utf16> string,
      Size max_length,
    );
typedef HidGetSerialNumberString =
    int Function(
      Pointer<HidDeviceHandle> device,
      Pointer<Utf16> string,
      int max_length,
    );

/// hid_get_indexed_string function signature
typedef HidGetIndexedStringNative =
    Int32 Function(
      Pointer<HidDeviceHandle> device,
      Int32 string_index,
      Pointer<Utf16> string,
      Size max_length,
    );
typedef HidGetIndexedString =
    int Function(
      Pointer<HidDeviceHandle> device,
      int string_index,
      Pointer<Utf16> string,
      int max_length,
    );

/// hid_error function signature (returns Utf16 error string)
typedef HidErrorNative =
    Pointer<Utf16> Function(Pointer<HidDeviceHandle> device);
typedef HidError = Pointer<Utf16> Function(Pointer<HidDeviceHandle> device);

/// hid_version function signature (hidapi 0.15.0+)
typedef HidVersionNative = Pointer<HidVersionStruct> Function();
typedef HidVersion = Pointer<HidVersionStruct> Function();

/// hid_version_struct (hidapi 0.15.0+)
final class HidVersionStruct extends Struct {
  @Int32()
  external int major;
  @Int32()
  external int minor;
  @Int32()
  external int patch;
}

/// hid_get_report_descriptor function signature (hidapi 0.15.0+)
typedef HidGetReportDescriptorNative =
    Int32 Function(
      Pointer<HidDeviceHandle> device,
      Pointer<Uint8> buf,
      Size buf_size,
    );
typedef HidGetReportDescriptor =
    int Function(
      Pointer<HidDeviceHandle> device,
      Pointer<Uint8> buf,
      int buf_size,
    );

/// Main class for FFI bindings
class HidApiFFI {
  static late final DynamicLibrary _lib;
  static bool _initialized = false;

  static late final HidDeviceOpen hid_open;
  static late final HidDeviceOpenPath hid_open_path;
  static late final HidDeviceClose hid_close;
  static late final HidWrite hid_write;
  static late final HidRead hid_read;
  static late final HidReadTimeout hid_read_timeout;
  static late final HidSetNonblocking hid_set_nonblocking;
  static late final HidSendFeatureReport hid_send_feature_report;
  static late final HidGetFeatureReport hid_get_feature_report;
  static late final HidEnumerate hid_enumerate;
  static late final HidFreeEnumeration hid_free_enumeration;
  static late final HidGetManufacturerString hid_get_manufacturer_string;
  static late final HidGetProductString hid_get_product_string;
  static late final HidGetSerialNumberString hid_get_serial_number_string;
  static late final HidGetIndexedString hid_get_indexed_string;
  static late final HidError hid_error;
  static late final HidVersion hid_version;

  // hidapi 0.15.0+ functions
  static late final HidGetReportDescriptor hid_get_report_descriptor;

  /// Initialize the FFI bindings
  /// This must be called before using any other functions
  static void initialize() {
    if (_initialized) {
      return;
    }

    final attemptedLibraries = <String>[];

    // On Windows, load the hidapi.dll directly since it's a separate shared library
    if (_isWindows()) {
      try {
        _lib = DynamicLibrary.open('hidapi.dll');
      } on ArgumentError catch (error) {
        attemptedLibraries.add('hidapi.dll');
        throw ArgumentError(
          'Failed to load hidapi.dll. Tried ${attemptedLibraries.join(', ')}. $error',
        );
      }
    } else {
      try {
        _lib = _loadFromCurrentProcess();
      } on ArgumentError {
        try {
          _lib = _loadFromKnownLibraryNames(attemptedLibraries);
        } on ArgumentError catch (error) {
          final attempted = attemptedLibraries.isEmpty
              ? 'current process symbols'
              : 'current process symbols, ${attemptedLibraries.join(', ')}';
          throw ArgumentError(
            'Failed to load hidapi symbols. Tried $attempted. $error',
          );
        }
      }
    }

    _bindFunctions();
    _initialized = true;
  }

  static DynamicLibrary _loadFromCurrentProcess() {
    if (_isWindows()) {
      return DynamicLibrary.executable();
    }

    return DynamicLibrary.process();
  }

  static DynamicLibrary _loadFromKnownLibraryNames(
    List<String> attemptedLibraries,
  ) {
    final candidates = _libraryCandidates();
    Object? lastError;

    for (final candidate in candidates) {
      attemptedLibraries.add(candidate);
      try {
        return DynamicLibrary.open(candidate);
      } on ArgumentError catch (error) {
        lastError = error;
      }
    }

    throw lastError ?? ArgumentError('No hidapi library candidates available');
  }

  static List<String> _libraryCandidates() {
    if (_isWindows()) {
      return const ['hidapi.dll'];
    }

    if (_isMacOS()) {
      return const ['libhidapi.dylib'];
    }

    if (_isLinux()) {
      return const ['libhidapi-hidraw.so.0', 'libhidapi-libusb.so.0'];
    }

    throw UnsupportedError('Unsupported platform');
  }

  static void _bindFunctions() {
    hid_open = _lib
        .lookup<NativeFunction<HidDeviceOpenNative>>('hid_open')
        .asFunction();
    hid_open_path = _lib
        .lookup<NativeFunction<HidDeviceOpenPathNative>>('hid_open_path')
        .asFunction();
    hid_close = _lib
        .lookup<NativeFunction<HidDeviceCloseNative>>('hid_close')
        .asFunction();
    hid_write = _lib
        .lookup<NativeFunction<HidWriteNative>>('hid_write')
        .asFunction();
    hid_read = _lib
        .lookup<NativeFunction<HidReadNative>>('hid_read')
        .asFunction();
    hid_read_timeout = _lib
        .lookup<NativeFunction<HidReadTimeoutNative>>('hid_read_timeout')
        .asFunction();
    hid_set_nonblocking = _lib
        .lookup<NativeFunction<HidSetNonblockingNative>>('hid_set_nonblocking')
        .asFunction();
    hid_send_feature_report = _lib
        .lookup<NativeFunction<HidSendFeatureReportNative>>(
          'hid_send_feature_report',
        )
        .asFunction();
    hid_get_feature_report = _lib
        .lookup<NativeFunction<HidGetFeatureReportNative>>(
          'hid_get_feature_report',
        )
        .asFunction();
    hid_enumerate = _lib
        .lookup<NativeFunction<HidEnumerateNative>>('hid_enumerate')
        .asFunction();
    hid_free_enumeration = _lib
        .lookup<NativeFunction<HidFreeEnumerationNative>>(
          'hid_free_enumeration',
        )
        .asFunction();
    hid_get_manufacturer_string = _lib
        .lookup<NativeFunction<HidGetManufacturerStringNative>>(
          'hid_get_manufacturer_string',
        )
        .asFunction();
    hid_get_product_string = _lib
        .lookup<NativeFunction<HidGetProductStringNative>>(
          'hid_get_product_string',
        )
        .asFunction();
    hid_get_serial_number_string = _lib
        .lookup<NativeFunction<HidGetSerialNumberStringNative>>(
          'hid_get_serial_number_string',
        )
        .asFunction();
    hid_get_indexed_string = _lib
        .lookup<NativeFunction<HidGetIndexedStringNative>>(
          'hid_get_indexed_string',
        )
        .asFunction();
    hid_error = _lib
        .lookup<NativeFunction<HidErrorNative>>('hid_error')
        .asFunction();
    hid_version = _lib
        .lookup<NativeFunction<HidVersionNative>>('hid_version')
        .asFunction();

    // hidapi 0.15.0+ functions
    hid_get_report_descriptor = _lib
        .lookup<NativeFunction<HidGetReportDescriptorNative>>(
          'hid_get_report_descriptor',
        )
        .asFunction();
  }

  static bool _isWindows() =>
      Abi.current() == Abi.windowsX64 || Abi.current() == Abi.windowsArm64;
  static bool _isMacOS() =>
      Abi.current() == Abi.macosX64 || Abi.current() == Abi.macosArm64;
  static bool _isLinux() =>
      Abi.current() == Abi.linuxX64 || Abi.current() == Abi.linuxArm64;
}
