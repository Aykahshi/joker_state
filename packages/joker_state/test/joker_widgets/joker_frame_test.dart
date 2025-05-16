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
      joker.trick(const UserModel(name: 'Dan', age: 41));
      await tester.pump();
      expect(buildCalls, 1);

      // Changed selected value -> rebuild
      joker.trick(const UserModel(name: 'Ed', age: 41));
      await tester.pump();
      expect(find.text('Name: Ed'), findsOneWidget);
      expect(buildCalls, 2);
    });

    testWidgets('Joker with keepAlive=false should dispose after frame removal',
        (tester) async {
      // Arrange
      final joker = Joker<UserModel>(
        const UserModel(name: 'DisposeMe', age: 0),
        keepAlive: false,
      );
      expect(joker.isDisposed, isFalse);

      final widget = joker.focusOn<String>(
        selector: (user) => user.name,
        builder: (context, name) => Text(name),
      );

      await tester.pumpWidget(MaterialApp(home: widget));
      expect(joker.isDisposed, isFalse);

      // Act: Remove widget
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle(); // Wait for dispose timer

      // Assert: Joker should be disposed
      expect(joker.isDisposed, isTrue);
    });

    testWidgets(
        'Joker with keepAlive=true should NOT dispose after frame removal',
        (tester) async {
      // Arrange
      final joker = Joker<UserModel>(
        const UserModel(name: 'KeepMe', age: 0),
        keepAlive: true,
      );
      expect(joker.isDisposed, isFalse);

      final widget = joker.focusOn<String>(
        selector: (user) => user.name,
        builder: (context, name) => Text(name),
      );

      await tester.pumpWidget(MaterialApp(home: widget));
      expect(joker.isDisposed, isFalse);

      // Act: Remove widget
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle(); // Wait potential dispose time

      // Assert: Joker should NOT be disposed
      expect(joker.isDisposed, isFalse);
      expect(() => joker.trick(const UserModel(name: 'Still Alive', age: 1)),
          returnsNormally);
      expect(joker.state.name, 'Still Alive');
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
