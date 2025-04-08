/// Interface for disposable resources
abstract class Disposable {
  void dispose();
}

/// Interface for asynchronous disposable resources
abstract class AsyncDisposable {
  Future<void> dispose();
}
