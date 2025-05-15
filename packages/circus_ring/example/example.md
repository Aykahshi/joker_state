```dart
import 'package:circus_ring/circus_ring.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Ring.hire('This is Example');

    return MaterialApp(
      title: 'CircusRing Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ExampleScreen(),
    );
  }
}

class ExampleScreen extends StatelessWidget {
  const ExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final example = Ring.find<String>();

    return Scaffold(
      body: Center(
        child: Text(
          example,
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
```
