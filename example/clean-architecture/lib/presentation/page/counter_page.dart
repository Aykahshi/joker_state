import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:joker_state/joker_state.dart';

import '../../domain/entity/counter.dart';
import '../event/counter_cues.dart';
import '../presenter/counter_presenter.dart';
import '../widget/counter_display.dart';

// The main page for the counter feature.
class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> with CueGateMixin {
  // Get the presenter instance from CircusRing.
  final _presenter = Circus.find<CounterPresenter>();

  // Get the Joker<Counter> instance for listening (optional).
  // Note: UI updates are handled by CounterDisplay observing the Joker.
  final _counterState = Circus.spotlight<Counter>(tag: COUNTER_JOKER_TAG);

  // Subscription for listening to RingCueMaster events.
  StreamSubscription? _milestoneSubscription;

  // JokerListener cancellation callback.
  VoidCallback? _jokerListenerCancel;

  @override
  void initState() {
    super.initState();

    // Initialize the state via the presenter.
    _presenter.initialize();

    // Listen for milestone events using RingCueMaster.
    _milestoneSubscription = Circus.onCue<CounterMilestoneReachedCue>((cue) {
      log('[Cue Received] Milestone reached: ${cue.milestoneValue}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Milestone ${cue.milestoneValue} reached via CueMaster!')),
        );
      }
    });

    // Re-introduce JokerListener - listening directly to Joker<Counter>.
    _jokerListenerCancel = _counterState.listenWhen(
      listener: (Counter? previous, Counter current) {
        log('[Joker Listener] State changed: ${previous?.value} -> ${current.value}');
        // Perform side effects based on state change.
        if (mounted && (current.value == 3 || current.value == 7)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Lucky number ${current.value} via JokerListener!')),
          );
        }
      },
      // Only trigger listener if the value actually changed.
      shouldListen: (prev, curr) => prev?.value != curr.value,
    );
  }

  // Debounced increment function - calls the presenter.
  void _debouncedIncrement() {
    debounceTrigger(() {
      _presenter.increment();
    }, const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    // Cancel subscriptions and listeners.
    _milestoneSubscription?.cancel();
    _jokerListenerCancel?.call();
    // CueGateMixin handles CueGate disposal automatically.
    // Presenter disposal is handled by CircusRing if fenix=true or managed elsewhere.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JokerState Clean Architecture'),
      ),
      body: const Center(
        // CounterDisplay now handles observing the state.
        child: CounterDisplay(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _debouncedIncrement,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
