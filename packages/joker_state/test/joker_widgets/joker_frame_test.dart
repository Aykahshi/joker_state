import 'package:circus_ring/circus_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/joker_state.dart';

void main() {
  group('JokerFrame', () {
    setUp(() async {
      await Circus.fireAll();
    });

    testWidgets('focusOn() extension builds and reacts correctly',
        (tester) async {
      final joker = Joker<UserModel>(const UserModel(name: 'Dan', age: 40));
      int buildCalls = 0;

      // Use the observe extension method
      final widget = joker.focusOn<String>(
        selector: (user) => user.name,
        builder: (context, name) {
          buildCalls++;
          return Text('Name: $name');
        },
      );

      await tester.pumpWidget(MaterialApp(home: widget));

      expect(find.text('Name: Dan'), findsOneWidget);
      expect(buildCalls, 1);

      // Unchanged selected value -> no rebuild
      joker.value = const UserModel(name: 'Dan', age: 41);
      await tester.pump();
      expect(buildCalls, 1);

      // Changed selected value -> rebuild
      joker.value = const UserModel(name: 'Ed', age: 41);
      await tester.pump();
      expect(find.text('Name: Ed'), findsOneWidget);
      expect(buildCalls, 2);
    });

    testWidgets('Joker should dispose after frame removal and no other listeners exist',
        (tester) async {
      // Arrange
      final joker = Joker<UserModel>(
        const UserModel(name: 'DisposeMe', age: 0),
      );

      final widget = joker.focusOn<String>(
        selector: (user) => user.name,
        builder: (context, name) => Text(name),
      );

      await tester.pumpWidget(MaterialApp(home: widget));

      // Act: Remove widget
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle(); // Wait for dispose timer

      // Assert: Joker should be disposed
      expect(() => joker.value, throwsA(isA<JokerException>()));
      expect(() => joker.addListener(() {}), throwsA(isA<JokerException>()));
    });

    testWidgets(
        'Joker should NOT dispose after frame removal IF other listeners exist',
        (tester) async {
      // Arrange
      final joker = Joker<UserModel>(
        const UserModel(name: 'KeepMe', age: 0),
      );
      void myListener() {}
      joker.addListener(myListener); // Add an external listener

      final widget = joker.focusOn<String>(
        selector: (user) => user.name,
        builder: (context, name) => Text(name),
      );

      await tester.pumpWidget(MaterialApp(home: widget));

      // Act: Remove widget
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle(); // Wait potential dispose time

      // Assert: Joker should NOT be disposed because myListener still exists
      expect(() => joker.value = const UserModel(name: 'Still Alive', age: 1), returnsNormally);
      expect(joker.value.name, 'Still Alive');

      // Clean up external listener
      joker.removeListener(myListener);
      // Now, Joker should dispose as JokerFrame (widget) and myListener are gone.
      await tester.pumpAndSettle(); // Allow potential dispose to happen
      expect(() => joker.value, throwsA(isA<JokerException>()));
      expect(() => joker.addListener(() {}), throwsA(isA<JokerException>()));
    });
  });
}

class UserModel {
  final String name;
  final int age;

  const UserModel({required this.name, required this.age});

  /// Custom equality based on value
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          name == other.name && // Only name matters for equality in some tests
          age == other.age;

  @override
  int get hashCode => name.hashCode ^ age.hashCode;
}
