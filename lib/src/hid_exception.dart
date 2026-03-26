/// Exception class for HID operations
class HidException implements Exception {
  /// The error message
  final String message;

  HidException(this.message);

  @override
  String toString() => 'HidException: $message';
}
