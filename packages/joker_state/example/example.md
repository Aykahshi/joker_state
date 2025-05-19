```dart
import 'package:flutter/material.dart';
import 'package:joker_state/joker_state.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final counter = Joker<int>(0);

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('JokerState Counter Demo')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('You have pushed the button this many times:'),
              // Rebuild only when the state changes
              counter.perform(
                builder: (context, count) => Text('$count'),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          // Update the state
          onPressed: () => counter.state += 1,
          tooltip: 'Increment',
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}
```