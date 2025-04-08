class CircusRingException implements Exception {
  final String message;

  CircusRingException(this.message);

  @override
  String toString() {
    return 'CircusRingException: $message';
  }
}
