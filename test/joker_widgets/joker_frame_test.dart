import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/joker_state.dart';

// Helper class for testing Presenter lifecycle and usage
class TestPresenter<T> extends Presenter<T> {
  bool initCalled = false;
  bool readyCalled = false;
  bool doneCalled = false;

  TestPresenter(super.initial, {super.tag, super.keepAlive});

  @override
  void onInit() {
    super.onInit();
    initCalled = true;
  }

  @override
  void onReady() {
    super.onReady();
    readyCalled = true;
  }

  @override
  void onDone() {
    doneCalled = true;
    super.onDone();
  }

  // Helper to modify state for testing
  void updateState(T newState) {
    trick(newState);
  }

  // Example of method specific to a potential User model
  void updateUserModel(UserModel Function(UserModel) updater) {
    if (state is UserModel) {
      trick(updater(state as UserModel) as T);
    }
  }
}

void main() {
  group('JokerFrame', () {
    setUp(() {
      // Clean up CircusRing before each test
      // Circus.fireAll();
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

    testWidgets('presenter.focusOn() extension should create JokerFrame',
        (WidgetTester tester) async {
      // Arrange
      final presenter = TestPresenter<UserModel>(
          const UserModel(name: 'Focus User', age: 50));
      int buildCount = 0;

      // Act: Use the focusOn extension
      await tester.pumpWidget(
        MaterialApp(
          home: presenter.focusOn<int>(
            selector: (user) => user.age,
            builder: (context, age) {
              buildCount++;
              return Text('Age: $age');
            },
          ),
        ),
      );

      // Assert initial state
      expect(find.text('Age: 50'), findsOneWidget);
      expect(buildCount, 1);
      expect(presenter.initCalled, isTrue);
      await tester.pump(); // for onReady
      expect(presenter.readyCalled, isTrue);

      // Act: Update non-selected part (name)
      presenter.updateUserModel(
          (user) => UserModel(name: 'New Name', age: user.age));
      await tester.pump();

      // Assert: Should not rebuild
      expect(buildCount, 1);

      // Act: Update selected part (age)
      presenter.updateUserModel((user) => UserModel(name: user.name, age: 51));
      await tester.pump();

      // Assert: Should rebuild
      expect(find.text('Age: 51'), findsOneWidget);
      expect(buildCount, 2);

      // Remove widget
      await tester.pumpWidget(Container());
      await tester.pump();
      expect(presenter.doneCalled, isTrue);
      expect(presenter.isDisposed, isTrue);
    });
  });
}

// --- Helper Class --- //

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
