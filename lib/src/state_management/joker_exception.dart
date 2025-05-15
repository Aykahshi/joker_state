class JokerException implements Exception {
  final String message;

  JokerException(this.message);

  @override
  String toString() {
    return '---[JokerException] -> $message---';
  }
}
