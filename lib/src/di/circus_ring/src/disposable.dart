/// Interface for disposable resources
abstract class Disposable {
  /// Dispose the resource
  void dispose();
}

/// Interface for asynchronous disposable resources
abstract class AsyncDisposable {
  /// Dispose the resource asynchronously
  Future<void> dispose();
}
