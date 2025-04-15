import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/joker_state.dart';

void main() {
  group('JokerTroupe', () {
    setUp(() {
      Circus.fireAll();
    });

    testWidgets('should display initial values with correct types',
        (WidgetTester tester) async {
      // Arrange
      final joker1 = Joker<int>(10);
      final joker2 = Joker<String>('test');

      // Act
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: JokerTroupe<(int, String)>(
            jokers: [joker1, joker2],
            converter: (values) => (values[0] as int, values[1] as String),
            builder: (context, values) {
              final (count, text) = values;
              return Column(
                children: [
                  Text('Count: $count'),
                  Text('Text: $text'),
                ],
              );
            },
          ),
        ),
      );

      // Assert
      expect(find.text('Count: 10'), findsOneWidget);
      expect(find.text('Text: test'), findsOneWidget);
    });

    testWidgets('should update when any joker changes',
        (WidgetTester tester) async {
      // Arrange
      final joker1 = Joker<int>(1);
      final joker2 = Joker<bool>(false);

      // Act - build the widget
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: JokerTroupe<(int, bool)>(
            jokers: [joker1, joker2],
            converter: (values) => (values[0] as int, values[1] as bool),
            builder: (context, values) {
              final (count, isActive) = values;
              return Column(
                children: [
                  Text('Count: $count'),
                  Text('Active: ${isActive ? 'Yes' : 'No'}'),
                ],
              );
            },
          ),
        ),
      );

      // Initial state
      expect(find.text('Count: 1'), findsOneWidget);
      expect(find.text('Active: No'), findsOneWidget);

      // Update first joker
      joker1.trick(10);
      await tester.pump();

      // Check updated state
      expect(find.text('Count: 10'), findsOneWidget);

      // Update second joker
      joker2.trick(true);
      await tester.pump();

      // Check updated state
      expect(find.text('Active: Yes'), findsOneWidget);
    });

    testWidgets('should provide properly typed values to builder',
        (WidgetTester tester) async {
      // Arrange
      final joker1 = Joker<int>(42);
      final joker2 = Joker<String>('hello');
      final joker3 = Joker<bool>(true);

      bool builderCalled = false;
      late int intValue;
      late String stringValue;
      late bool boolValue;

      // Act - build widget
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: JokerTroupe<(int, String, bool)>(
            jokers: [joker1, joker2, joker3],
            converter: (values) =>
                (values[0] as int, values[1] as String, values[2] as bool),
            builder: (context, values) {
              builderCalled = true;
              final (a, b, c) = values;
              intValue = a;
              stringValue = b;
              boolValue = c;
              return Text('$a, $b, $c');
            },
          ),
        ),
      );

      // Assert
      expect(builderCalled, isTrue);
      expect(intValue, equals(42));
      expect(stringValue, equals('hello'));
      expect(boolValue, isTrue);
      expect(find.text('42, hello, true'), findsOneWidget);
    });

    testWidgets('should dispose jokers when autoDispose is true',
        (WidgetTester tester) async {
      // Arrange - Using DisposableTracker to tracking dispose calls
      final joker1 = _DisposableTracker<int>(1);
      final joker2 = _DisposableTracker<String>('test');

      // Act - build and then remove widget
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: JokerTroupe<(int, String)>(
            jokers: [joker1, joker2],
            autoDispose: true,
            converter: (values) => (values[0] as int, values[1] as String),
            builder: (context, values) => Text('${values.$1}, ${values.$2}'),
          ),
        ),
      );

      await tester.pumpWidget(Container()); // Remove widget
      await tester.pump(); // Ensure dispose completes

      // Assert
      expect(joker1.isDisposed, isTrue);
      expect(joker2.isDisposed, isTrue);
    });

    testWidgets('should not dispose jokers when autoDispose is false',
        (WidgetTester tester) async {
      // Arrange - Using DisposableTracker to tracking dispose calls
      final joker1 = _DisposableTracker<int>(1);
      final joker2 = _DisposableTracker<String>('test');

      // Act - build and then remove widget
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: JokerTroupe<(int, String)>(
            jokers: [joker1, joker2],
            autoDispose: false,
            converter: (values) => (values[0] as int, values[1] as String),
            builder: (context, values) => Text('${values.$1}, ${values.$2}'),
          ),
        ),
      );

      await tester.pumpWidget(Container()); // Remove widget
      await tester.pump(); // Ensure any dispose would complete

      // Assert - should not be disposed
      expect(joker1.isDisposed, isFalse);
      expect(joker2.isDisposed, isFalse);

      // Verify jokers still work
      joker1.trick(100);
      joker2.trick('updated');

      expect(joker1.state, equals(100));
      expect(joker2.state, equals('updated'));
    });

    testWidgets('should handle CircusRing registered jokers',
        (WidgetTester tester) async {
      // Arrange - register jokers in CircusRing
      final joker1 = Joker<int>(10, tag: 'joker1');
      final joker2 = Joker<String>('hello', tag: 'joker2');

      Circus.hire<Joker<int>>(joker1, tag: 'joker1');
      Circus.hire<Joker<String>>(joker2, tag: 'joker2');

      // Act - build with registered jokers
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: JokerTroupe<(int, String)>(
            jokers: [joker1, joker2],
            converter: (values) => (values[0] as int, values[1] as String),
            builder: (context, values) => Text('${values.$1}, ${values.$2}'),
          ),
        ),
      );

      // Assert
      expect(find.text('10, hello'), findsOneWidget);

      // Update through original jokers
      joker1.trick(20);
      await tester.pump();

      expect(find.text('20, hello'), findsOneWidget);

      // Check jokers are still registered
      expect(Circus.isHired<Joker<int>>('joker1'), isTrue);
      expect(Circus.isHired<Joker<String>>('joker2'), isTrue);

      // Remove widget
      await tester.pumpWidget(Container());
      await tester.pump();

      // Check jokers were removed from CircusRing
      expect(Circus.isHired<Joker<int>>('joker1'), isFalse);
      expect(Circus.isHired<Joker<String>>('joker2'), isFalse);
    });

    testWidgets('should properly convert complex record types',
        (WidgetTester tester) async {
      // Arrange
      final joker1 = Joker<int>(42);
      final joker2 = Joker<String>('hello');
      final joker3 = Joker<bool>(true);
      final joker4 = Joker<double>(3.14);

      // Act - build with complex record type
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: JokerTroupe<(int, String, (bool, double))>(
            jokers: [joker1, joker2, joker3, joker4],
            converter: (values) => (
              values[0] as int,
              values[1] as String,
              (values[2] as bool, values[3] as double)
            ),
            builder: (context, values) {
              final (count, message, (isActive, rating)) = values;
              return Column(
                children: [
                  Text('Count: $count'),
                  Text('Message: $message'),
                  Text('Active: $isActive'),
                  Text('Rating: $rating'),
                ],
              );
            },
          ),
        ),
      );

      // Assert
      expect(find.text('Count: 42'), findsOneWidget);
      expect(find.text('Message: hello'), findsOneWidget);
      expect(find.text('Active: true'), findsOneWidget);
      expect(find.text('Rating: 3.14'), findsOneWidget);
    });
  });
}

// Helper Tracker to tracking dispose calls
class _DisposableTracker<T> extends Joker<T> {
  bool isDisposed = false;

  // ignore: use_super_parameters
  _DisposableTracker(T initialValue, {String? tag})
      : super(initialValue, tag: tag);

  @override
  void dispose() {
    isDisposed = true;
    super.dispose();
  }
}
