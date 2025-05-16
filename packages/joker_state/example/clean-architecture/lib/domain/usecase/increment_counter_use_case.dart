import '../entity/counter.dart';
import '../repository/counter_repository.dart';

// Use case to increment the counter.
class IncrementCounterUseCase {
  final CounterRepository _repository;

  IncrementCounterUseCase(this._repository);

  // Executes the use case.
  Future<Counter> execute() {
    return _repository.incrementCounter();
  }
}
