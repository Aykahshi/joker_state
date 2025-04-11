import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/joker_state.dart';

void main() {
  group('JokerFrame', () {
    testWidgets('rebuilds when selected value changes', (tester) async {
      final joker = Joker<Map<String, dynamic>>({'count': 0});
      await tester.pumpWidget(
        MaterialApp(
          home: JokerFrame<Map<String, dynamic>, int>(
            joker: joker,
            selector: (state) => state['count'] as int,
            builder: (context, count) {
              return Text('$count', textDirection: TextDirection.ltr);
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      // Update count
      joker.trick({'count': 1});
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('does not rebuild when selected value is unchanged',
        (tester) async {
      final joker = Joker<Map<String, dynamic>>({'count': 0});
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: JokerFrame<Map<String, dynamic>, int>(
            joker: joker,
            selector: (state) => state['count'] as int,
            builder: (context, count) {
              buildCount++;
              return Text('$count', textDirection: TextDirection.ltr);
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
      expect(buildCount, 1);

      // Trick to different key
      joker.trick({'count': 0, 'unused': true});
      await tester.pump();

      // Should not rebuild
      expect(buildCount, 1);
    });

    testWidgets('handles custom object with overridden equality',
        (tester) async {
      final joker = Joker<_UserModel>(const _UserModel(name: 'Alice', age: 20));
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: JokerFrame<_UserModel, String>(
            joker: joker,
            selector: (user) => user.name,
            builder: (context, name) {
              buildCount++;
              return Text('User: $name', textDirection: TextDirection.ltr);
            },
          ),
        ),
      );

      expect(find.text('User: Alice'), findsOneWidget);
      expect(buildCount, 1);

      // Age change only (name unchanged)
      joker.trick(const _UserModel(name: 'Alice', age: 25));
      await tester.pump();
      // Should not rebuild
      expect(buildCount, 1);

      // Name change
      joker.trick(const _UserModel(name: 'Bob', age: 25));
      await tester.pump();
      expect(find.text('User: Bob'), findsOneWidget);
      expect(buildCount, 2);
    });

    testWidgets('observe() builds and reacts only on selector change',
        (tester) async {
      final joker = Joker<_UserModel>(const _UserModel(name: 'Dan', age: 40));
      int buildCalls = 0;

      final widget = joker.observe<String>(
        selector: (user) => user.name,
        builder: (context, name) {
          buildCalls++;
          return Text('Name: $name', textDirection: TextDirection.ltr);
        },
      );

      await tester.pumpWidget(MaterialApp(home: widget));

      expect(find.text('Name: Dan'), findsOneWidget);
      expect(buildCalls, 1);

      // Unchanged name -> no rebuild
      joker.trick(const _UserModel(name: 'Dan', age: 41));
      await tester.pump();
      expect(buildCalls, 1);

      // Changed name -> rebuild
      joker.trick(const _UserModel(name: 'Ed', age: 41));
      await tester.pump();
      expect(find.text('Name: Ed'), findsOneWidget);
      expect(buildCalls, 2);
    });

    testWidgets('autoDispose should dispose Joker when removed',
        (tester) async {
      final joker = _DisposableUserJoker();

      final widget = joker.observe<String>(
        selector: (user) => user.name,
        builder: (context, name) => Text(name),
        autoDispose: true,
      );

      await tester.pumpWidget(MaterialApp(home: widget));
      expect(joker.isDisposed, isFalse);

      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();

      expect(joker.isDisposed, isTrue);
    });
  });
}

/// Helper Joker for dispose test
class _DisposableUserJoker extends Joker<_UserModel> {
  bool isDisposed = false;

  _DisposableUserJoker() : super(const _UserModel(name: 'Init', age: 0));

  @override
  void dispose() {
    isDisposed = true;
    super.dispose();
  }
}

class _UserModel {
  final String name;
  final int age;

  const _UserModel({required this.name, required this.age});

  /// Custom equality based on value
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _UserModel &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          age == other.age;

  @override
  int get hashCode => name.hashCode ^ age.hashCode;
}
