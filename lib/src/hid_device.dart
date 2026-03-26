import 'dart:typed_data';

/// Abstract class representing a HID device
abstract class HidDevice {
  // ===== Device Properties =====

  /// Unique identifier for the device (usually the path)
  String get id;

  /// Platform-specific device path
  String get path;

  /// USB vendor ID
  int get vendorId;

  /// USB product ID
  int get productId;

  /// Device serial number
  String get serialNumber;

  /// Device release number (in binary-coded decimal format)
  int get releaseNumber;

  /// Manufacturer name string
  String get manufacturer;

  /// Product name string
  String get productName;

  /// HID usage page
  int get usagePage;

  /// HID usage
  int get usage;

  /// USB interface number
  int get interfaceNumber;

  /// Bus type (0=USB, 1=Bluetooth, 2=I2C, 3=SPI)
  int get busType;

  /// Check if device is currently open
  bool get isOpen;

  // ===== Connection Management =====

  /// Open the device for communication
  Future<void> open();

  /// Close the device
  Future<void> close();

  // ===== Data Read/Write =====

  /// Send an output report to the device
  ///
  /// [data] The report data to send (includes report ID as first byte if needed)
  /// [reportId] The report ID (default is 0x00)
  Future<void> sendReport(Uint8List data, {int reportId = 0x00});

  /// Receive an input report from the device
  ///
  /// [reportLength] Expected length of the report
  /// [timeout] Optional timeout for waiting for data
  Future<Uint8List> receiveReport(int reportLength, {Duration? timeout});

  /// Get a feature report from the device
  ///
  /// [reportLength] Expected length of the report
  /// [reportId] The report ID to request (default is 0x00)
  Future<Uint8List> getFeatureReport(int reportLength, {int reportId = 0x00});

  /// Send a feature report to the device
  ///
  /// [data] The report data to send
  /// [reportId] The report ID (default is 0x00)
  Future<void> sendFeatureReport(Uint8List data, {int reportId = 0x00});

  /// Get the HID report descriptor
  ///
  /// Returns the raw report descriptor bytes
  Future<Uint8List> getReportDescriptor();

  /// Stream of input reports as individual bytes
  Stream<int> inputStream();

  /// Get an indexed string from the device
  ///
  /// [index] The string index to retrieve
  /// [maxLength] Maximum length of the string (default is 256)
  Future<String> getIndexedString(int index, {int maxLength = 256});

  /// Get the number of input reports on the device
  Future<int> getInputReportLength();

  /// Get the number of output reports on the device
  Future<int> getOutputReportLength();

  /// Get the number of feature reports on the device
  Future<int> getFeatureReportLength();
}
