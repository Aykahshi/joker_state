import '../entity/counter.dart';

// Abstract interface for counter data operations.
abstract class CounterRepository {
  // Gets the current counter value.
  Future<Counter> getCounter();

  // Increments the counter value.
  Future<Counter> incrementCounter();
}
