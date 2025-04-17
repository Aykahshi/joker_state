import '../entity/counter.dart';
import '../repository/counter_repository.dart';

// Use case to get the current counter value.
class GetCounterUseCase {
  final CounterRepository _repository;

  GetCounterUseCase(this._repository);

  // Executes the use case.
  Future<Counter> execute() {
    return _repository.getCounter();
  }
}
