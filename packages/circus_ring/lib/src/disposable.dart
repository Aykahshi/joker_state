/// Interface for disposable resources
/// If you want to auto dispose your instance by CircusRing, you can mix this in
interface class Disposable {
  /// Dispose the resource
  void dispose() {}
}

/// Interface for asynchronous disposable resources
interface class AsyncDisposable {
  /// Dispose the resource asynchronously
  Future<void> dispose() async {}
}
