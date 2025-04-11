import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/joker_state.dart';

void main() {
  group('JokerStage', () {
    setUp(() {
      Circus.fireAll();
    });

    testWidgets('should display initial value of joker',
        (WidgetTester tester) async {
      // Arrange
      final joker = Joker<String>('Hello');

      // Act
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: JokerStage<String>(
            joker: joker,
            builder: (context, value) => Text(value),
          ),
        ),
      );

      // Assert
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('should update when joker value changes',
        (WidgetTester tester) async {
      // Arrange
      final joker = Joker<int>(10);

      // Act - build the widget
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: JokerStage<int>(
            joker: joker,
            builder: (context, value) => Text('Count: $value'),
          ),
        ),
      );

      // Initial state
      expect(find.text('Count: 10'), findsOneWidget);

      // Update joker
      joker.trick(20);
      await tester.pump();

      // Assert
      expect(find.text('Count: 20'), findsOneWidget);
    });

    testWidgets('should dispose joker when autoDispose is true',
        (WidgetTester tester) async {
      // Arrange
      final joker = Joker<int>(42);
      // Act - build and then remove widget
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: JokerStage<int>(
            joker: joker,
            autoDispose: true,
            builder: (context, value) => Text('$value'),
          ),
        ),
      );

      await tester.pumpWidget(Container()); // Remove widget

      // Assert
      expect(() => joker.trick(100), throwsA(isInstanceOf<FlutterError>()));
    });

    testWidgets('should not dispose joker when autoDispose is false',
        (WidgetTester tester) async {
      // Arrange
      final joker = Joker<int>(42);
      // Act - build and then remove widget
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: JokerStage<int>(
            joker: joker,
            autoDispose: false,
            builder: (context, value) => Text('$value'),
          ),
        ),
      );

      await tester.pumpWidget(Container()); // Remove widget

      // Assert
      expect(joker.state, 42);
    });

    testWidgets('should handle CircusRing integrated jokers',
        (WidgetTester tester) async {
      // Arrange - register joker in CircusRing
      final joker = Joker<String>('Registered', tag: 'test-joker');
      Circus.hire<Joker<String>>(joker, tag: 'test-joker');

      // Verify joker is registered
      expect(Circus.isHired<Joker<String>>('test-joker'), isTrue);

      // Act - build with registered joker
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: JokerStage<String>(
            joker: joker,
            builder: (context, value) => Text(value),
          ),
        ),
      );

      // Assert
      expect(find.text('Registered'), findsOneWidget);

      // Update joker
      joker.trick('Updated');
      await tester.pump();

      expect(find.text('Updated'), findsOneWidget);

      // Remove widget
      await tester.pumpWidget(Container());

      // Joker should still be registered (not auto-disposed)
      expect(Circus.isHired<Joker<String>>('test-joker'), isFalse);
    });

    testWidgets(
        'should properly unregister CircusRing jokers when autoDispose=true',
        (WidgetTester tester) async {
      // Arrange - register joker in CircusRing
      final joker = Joker<int>(42, tag: 'auto-remove');
      Circus.hire<Joker<int>>(joker, tag: 'auto-remove');

      // Act - build with registered joker and autoDispose=true
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: JokerStage<int>(
            joker: joker,
            autoDispose: true,
            builder: (context, value) => Text('$value'),
          ),
        ),
      );

      // Initial check
      expect(find.text('42'), findsOneWidget);
      expect(Circus.isHired<Joker<int>>('auto-remove'), isTrue);

      // Remove widget
      await tester.pumpWidget(Container());
      await tester.pump(); // Ensure dispose completes

      // Joker should be unregistered
      expect(Circus.isHired<Joker<int>>('auto-remove'), isFalse);
    });

    testWidgets('should handle joker without tag', (WidgetTester tester) async {
      // Arrange - joker without tag
      final joker = Joker<String>('No tag');

      // Act - build and then remove
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: JokerStage<String>(
            joker: joker,
            autoDispose: true,
            builder: (context, value) => Text(value),
          ),
        ),
      );

      expect(find.text('No tag'), findsOneWidget);

      // Should not crash when removed (even though joker has no tag)
      await tester.pumpWidget(Container());
    });

    testWidgets('should handle multiple stages with same joker',
        (WidgetTester tester) async {
      // Arrange - single joker used by multiple stages
      final joker = Joker<int>(10);

      // Act - build multiple stages
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              JokerStage<int>(
                joker: joker,
                autoDispose: false,
                // Important: only one should auto-dispose
                builder: (context, value) => Text('First: $value'),
              ),
              JokerStage<int>(
                joker: joker,
                autoDispose: true,
                builder: (context, value) => Text('Second: $value'),
              ),
            ],
          ),
        ),
      );

      // Initial state
      expect(find.text('First: 10'), findsOneWidget);
      expect(find.text('Second: 10'), findsOneWidget);

      // Update joker
      joker.trick(20);
      await tester.pump();

      // Both should update
      expect(find.text('First: 20'), findsOneWidget);
      expect(find.text('Second: 20'), findsOneWidget);
    });

    testWidgets('should work correctly with manual jokers',
        (WidgetTester tester) async {
      // Arrange - manual joker (autoNotify=false)
      final joker = Joker<int>(5, autoNotify: false);

      // Act - build with manual joker
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: JokerStage<int>(
            joker: joker,
            builder: (context, value) => Text('Value: $value'),
          ),
        ),
      );

      // Initial state
      expect(find.text('Value: 5'), findsOneWidget);

      // Update without notification
      joker.whisper(10);
      await tester.pump();

      // Should not update yet
      expect(find.text('Value: 5'), findsOneWidget);

      // Now send notification
      joker.yell();
      await tester.pump();

      // Should update now
      expect(find.text('Value: 10'), findsOneWidget);
    });
  });
}

// Helper widget for testing joker switching
class _JokerSwitcher extends StatefulWidget {
  final Joker<String> initialJoker;
  final Joker<String> secondJoker;

  _JokerSwitcher({
    required this.initialJoker,
    required this.secondJoker,
  });

  @override
  _JokerSwitcherState createState() => _JokerSwitcherState();

  void switchJokers() {
    _JokerSwitcherState.instance?.switchJokers();
  }
}

class _JokerSwitcherState extends State<_JokerSwitcher> {
  static _JokerSwitcherState? instance;
  late Joker<String> currentJoker;

  @override
  void initState() {
    super.initState();
    currentJoker = widget.initialJoker;
    instance = this;
  }

  @override
  void dispose() {
    if (instance == this) {
      instance = null;
    }
    super.dispose();
  }

  void switchJokers() {
    setState(() {
      currentJoker = currentJoker == widget.initialJoker
          ? widget.secondJoker
          : widget.initialJoker;
    });
  }

  @override
  Widget build(BuildContext context) {
    return JokerStage<String>(
      joker: currentJoker,
      builder: (context, value) => Text(value),
    );
  }
}
