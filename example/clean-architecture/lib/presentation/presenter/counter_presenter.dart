// ignore_for_file: avoid_print

import 'package:joker_state/joker_state.dart';

import '../../domain/entity/counter.dart';
import '../../domain/usecase/get_counter_use_case.dart';
import '../../domain/usecase/increment_counter_use_case.dart';
import '../event/counter_cues.dart';

// Tag for the counter state Joker instance in CircusRing.
// ignore: constant_identifier_names
const String COUNTER_JOKER_TAG = 'counter_state';

// Handles presentation logic for the counter feature.
class CounterPresenter implements Disposable {
  final GetCounterUseCase _getCounterUseCase;
  final IncrementCounterUseCase _incrementCounterUseCase;
  // Hold the Joker instance for state updates.
  final Joker<Counter> _counterState;

  CounterPresenter(
    this._getCounterUseCase,
    this._incrementCounterUseCase,
    this._counterState,
  );

  // Initializes the counter state by fetching the initial value.
  Future<void> initialize() async {
    try {
      final initialCounter = await _getCounterUseCase.execute();
      _counterState.trick(initialCounter); // Update state via Joker
    } catch (e) {
      // Handle potential errors during initialization
      _counterState.trick(const Counter(value: -1)); // Indicate error state
      Circus.logger.severe('Failed to initialize counter: $e');
    }
  }

  // Increments the counter and updates the state.
  Future<void> increment() async {
    try {
      final newCounter = await _incrementCounterUseCase.execute();
      _counterState.trick(newCounter); // Update state via Joker

      // Send cues after successful update
      Circus.cue(CounterIncrementedCue(newCounter.value));
      if (newCounter.value % 5 == 0 && newCounter.value != 0) {
        Circus.cue(CounterMilestoneReachedCue(newCounter.value));
      }
    } catch (e) {
      // Handle potential errors during increment
      Circus.logger.warning('Failed to increment counter: $e');
      // Optionally update state to reflect error, or keep current state
    }
  }

  // Dispose method for potential cleanup (if needed later).
  @override
  void dispose() {
    // No resources to dispose in this simple presenter currently.
    Circus.logger.info('CounterPresenter disposed.');
  }
}

// Extension for easy access to logger (if not already globally available)
extension CircusLoggerExtension on CircusRing {
  Logger get logger => find<Logger>(); // Assumes Logger is registered
}

// Dummy Logger class for example purposes if not using a logging package
class Logger {
  void severe(String message) => print('[SEVERE] $message');
  void warning(String message) => print('[WARNING] $message');
  void info(String message) => print('[INFO] $message');
}
