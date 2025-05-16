import '../../domain/entity/counter.dart';
import '../../domain/repository/counter_repository.dart';

// In-memory implementation of the CounterRepository.
class CounterRepositoryImpl implements CounterRepository {
  // Simple in-memory storage for the counter value.
  int _currentValue = 0;

  @override
  Future<Counter> getCounter() async {
    // Simulate network delay or database access time
    await Future.delayed(const Duration(milliseconds: 100));
    return Counter(value: _currentValue);
  }

  @override
  Future<Counter> incrementCounter() async {
    // Simulate network delay or database access time
    await Future.delayed(const Duration(milliseconds: 100));
    _currentValue++;
    return Counter(value: _currentValue);
  }
}
