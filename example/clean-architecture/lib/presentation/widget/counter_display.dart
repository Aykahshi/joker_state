import 'package:flutter/material.dart';
import 'package:joker_state/joker_state.dart';

import '../../domain/entity/counter.dart';
import '../presenter/counter_presenter.dart';

// Displays the current counter value and a milestone message.
class CounterDisplay extends StatelessWidget {
  const CounterDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    // Observe the Joker<Counter> state directly using the tag.
    return Circus.spotlight<Counter>(tag: COUNTER_JOKER_TAG).observe<int>(
      // Select the integer value from the Counter state.
      selector: (counter) => counter.value,
      builder: (context, count) {
        // Handle the error state indicated by value -1
        if (count == -1) {
          return const Center(
            child: Text(
              'Error loading counter!',
              style: TextStyle(color: Colors.red, fontSize: 18),
            ),
          );
        }
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$count',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            // Use JokerReveal to show a message conditionally.
            (count >= 10 && count % 10 == 0).reveal(
              whenTrue: Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text('🎉 Milestone $count reached! 🎉'),
              ),
              // Provide an empty widget when false.
              whenFalse: const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}
