import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/src/di/circus_ring/circus_ring.dart';
import 'package:joker_state/src/state_management/joker/joker.dart';
import 'package:joker_state/src/state_management/joker_stage/joker_stage.dart';

void main() {
  group('JokerStage Widget', () {
    late Joker<int> joker;

    setUp(() {
      joker = Joker<int>(42);
      Circus.fireAll();
    });

    testWidgets('should display joker value', (WidgetTester tester) async {
      // Arrange
      bool builderCalled = false;

      // Act - build widget
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: JokerStage<int>(
          joker: joker,
          builder: (context, value, child) {
            builderCalled = true;
            return Text('Value: $value');
          },
        ),
      ));

      // Assert
      expect(builderCalled, isTrue);
      expect(find.text('Value: 42'), findsOneWidget);
    });

    testWidgets('should rebuild when joker value changes',
        (WidgetTester tester) async {
      // Arrange - build widget
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: JokerStage<int>(
          joker: joker,
          builder: (context, value, child) {
            return Text('Value: $value');
          },
        ),
      ));

      // Initial state
      expect(find.text('Value: 42'), findsOneWidget);

      // Act - change joker value
      joker.trick(100);
      await tester.pump();

      // Assert
      expect(find.text('Value: 100'), findsOneWidget);
      expect(find.text('Value: 42'), findsNothing);
    });

    testWidgets('should pass child widget to builder',
        (WidgetTester tester) async {
      // Arrange
      final childWidget = Container(key: Key('child'));
      Widget? passedChild;

      // Act - build widget
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: JokerStage<int>(
          joker: joker,
          builder: (context, value, child) {
            passedChild = child;
            return Column(children: [
              Text('Value: $value'),
              if (child != null) child,
            ]);
          },
          child: childWidget,
        ),
      ));

      // Assert
      expect(passedChild, equals(childWidget));
      expect(find.byKey(Key('child')), findsOneWidget);
    });

    testWidgets('should dispose joker when autoDispose is true',
        (WidgetTester tester) async {
      // Arrange
      final localJoker = Joker<String>('test');
      bool listenerCalled = false;

      localJoker.addListener(() {
        listenerCalled = true;
      });

      // Act - build and dispose widget
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: JokerStage<String>(
          joker: localJoker,
          autoDispose: true,
          builder: (context, value, _) => Text(value),
        ),
      ));

      // Dispose widget
      await tester.pumpWidget(Container());

      // Try to update joker after disposal
      try {
        localJoker.trick('updated');
        fail('Joker should be disposed and throw exception');
      } catch (e) {
        // Expected
      }

      expect(listenerCalled, isFalse);
    });

    testWidgets('should not dispose joker when autoDispose is false',
        (WidgetTester tester) async {
      // Arrange
      final localJoker = Joker<String>('test');

      // Act - build and dispose widget
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: JokerStage<String>(
          joker: localJoker,
          autoDispose: false,
          builder: (context, value, _) => Text(value),
        ),
      ));

      // Dispose widget
      await tester.pumpWidget(Container());

      // Update joker after widget disposal
      localJoker.trick('updated');

      // Assert - joker should still work
      expect(localJoker.value, equals('updated'));
    });

    testWidgets('should handle CircusRing registered jokers correctly',
        (WidgetTester tester) async {
      // Arrange - register joker in CircusRing
      final taggedJoker = Joker<int>(100, tag: 'counter');
      Circus.hire(taggedJoker, tag: 'counter');

      // Act - build widget with registered joker
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: JokerStage<int>(
          joker: taggedJoker,
          builder: (context, value, _) => Text('Value: $value'),
        ),
      ));

      // Check initial display
      expect(find.text('Value: 100'), findsOneWidget);

      // Dispose widget
      await tester.pumpWidget(Container());

      // Assert - joker should be removed from CircusRing
      expect(Circus.tryFind<Joker<int>>('counter'), isNull);
    });

    testWidgets('should handle joker with null tag',
        (WidgetTester tester) async {
      // Arrange - joker with null tag
      final untaggedJoker = Joker<int>(200);

      // Act - build widget with untagged joker
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: JokerStage<int>(
          joker: untaggedJoker,
          builder: (context, value, _) => Text('Value: $value'),
        ),
      ));

      // Check initial display
      expect(find.text('Value: 200'), findsOneWidget);

      // Dispose widget should not crash with null tag
      await tester.pumpWidget(Container());
    });

    testWidgets('should not dispose CircusRing joker if autoDispose is false',
        (WidgetTester tester) async {
      // Arrange - register joker in CircusRing
      final taggedJoker = Joker<int>(100, tag: 'persistent');
      Circus.hire(taggedJoker, tag: 'persistent');

      // Act - build widget with autoDispose = false
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: JokerStage<int>(
          joker: taggedJoker,
          autoDispose: false,
          builder: (context, value, _) => Text('Value: $value'),
        ),
      ));

      // Dispose widget
      await tester.pumpWidget(Container());

      // Assert - joker should still be in CircusRing
      expect(Circus.isHired<Joker<int>>('persistent'), isTrue);

      // Clean up
      Circus.fire<Joker<int>>(tag: 'persistent');
    });

    testWidgets('should handle edge case - using tag for CircusRing lookup',
        (WidgetTester tester) async {
      // This test ensures the dispose logic properly uses tag for CircusRing operations

      // Arrange - register a joker with a specific tag
      final tag = 'special_tag';
      final jokerA = Joker<String>('Joker A', tag: tag);
      Circus.hire(jokerA, tag: tag);

      // Act - create JokerWatcher with this joker
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: JokerStage<String>(
          joker: jokerA,
          builder: (context, value, _) => Text(value),
        ),
      ));

      // Verify initial state
      expect(find.text('Joker A'), findsOneWidget);
      expect(Circus.isHired<Joker<String>>(tag), isTrue);

      // Dispose widget
      await tester.pumpWidget(Container());

      // Assert - joker should be removed from CircusRing using the correct tag
      expect(Circus.isHired<Joker<String>>(tag), isFalse);
    });
  });
}
