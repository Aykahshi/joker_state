import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/joker_state.dart';
import 'package:joker_state/src/state_management/presenter/presenter.dart'; // Import Presenter

// Define a unique class for testing type-based lookup without tag
class UniqueType {
  final String value;
  UniqueType(this.value);
}

// Helper class for testing Presenter lifecycle and usage
class TestPresenter<T> extends Presenter<T> {
  bool initCalled = false;
  bool readyCalled = false;
  bool doneCalled = false;

  TestPresenter(T initial, {String? tag, bool keepAlive = false})
      : super(initial, tag: tag, keepAlive: keepAlive);

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
    debugPrint(
        ">>> [TestPresenter] onDone CALLED, setting doneCalled = true for ${tag ?? runtimeType}");
    doneCalled = true;
    super.onDone();
  }
}

void main() {
  setUp(() async {
    // Reset CircusRing before each test
    await Circus.fireAll();
    // Removed Circus.config call, logging now tied to kDebugMode
    // Circus.config(enableLogs: false);
  });

  group('CircusRing Basic Functionality', () {
    test('should be a singleton', () {
      // Arrange
      final instance1 = CircusRing();
      final instance2 = CircusRing();

      // Assert
      expect(instance1, same(instance2));
      expect(CircusRing.instance, same(instance1));
      expect(Circus, same(instance1));
    });
  });

  group('CircusRing Hiring (Registration)', () {
    test('hire should register a synchronous singleton', () {
      // Arrange
      final testInstance = _TestClass('test');

      // Act
      final result = Circus.hire<_TestClass>(testInstance);

      // Assert
      expect(result, equals(testInstance));
      expect(Circus.find<_TestClass>(), equals(testInstance));
      expect(Circus.isHired<_TestClass>(), isTrue);
    });

    test('hire should register a singleton with tag', () {
      // Arrange
      final testInstance1 = _TestClass('test1');
      final testInstance2 = _TestClass('test2');

      // Act
      Circus.hire<_TestClass>(testInstance1, tag: 'tag1');
      Circus.hire<_TestClass>(testInstance2, tag: 'tag2');

      // Assert
      expect(Circus.find<_TestClass>('tag1'), equals(testInstance1));
      expect(Circus.find<_TestClass>('tag2'), equals(testInstance2));
    });

    test('hire should throw when registering Joker without tag', () {
      // Arrange
      final jokerInstance = Joker<String>('test');

      // Act & Assert
      expect(() => Circus.hire<Joker<String>>(jokerInstance),
          throwsA(isA<CircusRingException>()));
    });

    test('hire should allow registering Joker with tag', () {
      // Arrange
      final jokerInstance = Joker<String>('test');

      // Act & Assert
      expect(() => Circus.hire<Joker<String>>(jokerInstance, tag: 'myJoker'),
          returnsNormally);
      expect(Circus.isHired<Joker<String>>('myJoker'), isTrue);
    });

    test('hire should replace existing instance and dispose non-joker', () {
      // Arrange
      final testInstance1 = _DisposableObject();
      final testInstance2 = _DisposableObject();

      // Act
      Circus.hire<_DisposableObject>(testInstance1);
      Circus.hire<_DisposableObject>(testInstance2,
          allowReplace: true); // Add allowReplace

      // Assert
      expect(Circus.find<_DisposableObject>(), equals(testInstance2));
      expect(
          testInstance1.isDisposed, isTrue); // Old instance should be disposed
      expect(testInstance2.isDisposed, isFalse); // New instance should not
    });

    test('hire should replace existing Joker instance AND dispose old one', () {
      // Arrange
      final joker1 = Joker<int>(1, tag: 'joker');
      final joker2 = Joker<int>(2, tag: 'joker');

      Circus.hire<Joker<int>>(joker1, tag: 'joker');
      expect(joker1.isDisposed, isFalse);

      // Act
      Circus.hire<Joker<int>>(joker2,
          tag: 'joker', allowReplace: true); // Add allowReplace

      // Assert
      expect(Circus.find<Joker<int>>('joker'), equals(joker2));
      // CircusRing replacement logic SHOULD NOW dispose the replaced Joker
      expect(joker1.isDisposed, isTrue);
      expect(joker2.isDisposed, isFalse);

      // No manual cleanup needed for joker1
    });

    testWidgets(
        'hire should replace existing Presenter instance AND dispose old one (direct check)',
        (WidgetTester tester) async {
      // Arrange
      final presenter1 = TestPresenter<int>(1, tag: 'presenter');
      final presenter2 = TestPresenter<int>(2, tag: 'presenter');

      Circus.hire<TestPresenter<int>>(presenter1, tag: 'presenter');
      expect(presenter1.isDisposed, isFalse,
          reason: "Presenter1 should not be disposed initially");
      expect(presenter1.doneCalled, isFalse,
          reason: "Presenter1 onDone should not be called initially");

      // Act
      Circus.hire<TestPresenter<int>>(presenter2,
          tag: 'presenter', allowReplace: true); // Add allowReplace

      // Assert IMMEDIATELY after replacement
      // Check isDisposed first, as it's set after onDone is called.
      expect(presenter1.isDisposed, isTrue,
          reason: "Presenter1 should be disposed after replacement");
      expect(presenter1.doneCalled, isTrue,
          reason: "Presenter1 onDone should be called during replacement");

      // Also check Circus state and presenter2 state
      expect(Circus.find<TestPresenter<int>>('presenter'), equals(presenter2),
          reason: "Circus should now hold presenter2");
      expect(presenter2.isDisposed, isFalse,
          reason: "Presenter2 should not be disposed");
    });

    test('hireAsync should register an asynchronous singleton', () async {
      // Arrange
      builder() async => _TestClass('async');

      // Act
      final result = await Circus.hireAsync<_TestClass>(builder);

      // Assert
      expect(result.value, equals('async'));
      expect((await Circus.findAsync<_TestClass>()).value, equals('async'));
    });

    test('hireLazily should register a lazy singleton', () {
      // Arrange
      int count = 0;
      builder() {
        count++;
        return _TestClass('lazy');
      }

      // Act
      Circus.hireLazily<_TestClass>(builder);

      // Assert - Instance should not be created yet
      expect(count, equals(0));

      // Act - Access the instance
      final instance = Circus.find<_TestClass>();

      // Assert - Instance should be created only once
      expect(count, equals(1));
      expect(instance.value, equals('lazy'));

      // Access again should not create a new instance
      final instance2 = Circus.find<_TestClass>();
      expect(count, equals(1));
      expect(instance2, same(instance));
    });

    test('hireLazilyAsync should register an async lazy singleton', () async {
      // Arrange
      int count = 0;
      builder() async {
        count++;
        return _TestClass('async lazy');
      }

      // Act
      Circus.hireLazilyAsync<_TestClass>(builder);

      // Assert - Instance should not be created yet
      expect(count, equals(0));

      // Act - Access the instance
      final instance = await Circus.findAsync<_TestClass>();

      // Assert - Instance should be created
      expect(count, equals(1));
      expect(instance.value, equals('async lazy'));

      // Access again should not create a new instance
      final instance2 = await Circus.findAsync<_TestClass>();
      expect(count, equals(1));
      expect(instance2, same(instance));
    });

    test('fenix rebirth after dispose returns new instance', () {
      int counter = 0;

      Circus.hireLazily<int>(() {
        counter++;
        return counter;
      }, tag: 'auto', fenix: true);

      final first = Circus.find<int>('auto');
      expect(first, 1);

      Circus.fire<int>(tag: 'auto');
      final reborn = Circus.find<int>('auto');
      expect(reborn, 2);
    });

    test('contract should register a factory', () {
      // Arrange
      int count = 0;
      builder() {
        count++;
        return _TestClass('factory');
      }

      // Act
      Circus.contract<_TestClass>(builder);

      // Assert - Each access should create new instance
      final instance1 = Circus.find<_TestClass>();
      expect(count, equals(1));
      expect(instance1.value, equals('factory'));

      final instance2 = Circus.find<_TestClass>();
      expect(count, equals(2));
      expect(instance2.value, equals('factory'));
      expect(instance2, isNot(same(instance1)));
    });

    test('appoint should register a singleton (alias for hire)', () {
      // Arrange
      final testInstance = _TestClass('appointed');

      // Act
      final result = Circus.appoint<_TestClass>(testInstance);

      // Assert
      expect(result, equals(testInstance));
      expect(Circus.find<_TestClass>(), equals(testInstance));
    });

    test('draft should create instance without registration', () {
      // Arrange
      builder() => _TestClass('draft');

      // Act
      final result = Circus.draft<_TestClass>(builder: builder);

      // Assert
      expect(result.value, equals('draft'));
      expect(Circus.isHired<_TestClass>(), isFalse);
      expect(
          () => Circus.find<_TestClass>(), throwsA(isA<CircusRingException>()));
    });
  });

  group('CircusRing Finding', () {
    test('find should retrieve registered instance', () {
      // Arrange
      final testInstance = _TestClass('test');
      Circus.hire<_TestClass>(testInstance);

      // Act
      final result = Circus.find<_TestClass>();

      // Assert
      expect(result, equals(testInstance));
    });

    test('find should throw when instance not found', () {
      // Act & Assert
      expect(
          () => Circus.find<_TestClass>(), throwsA(isA<CircusRingException>()));
    });

    test('findAsync should retrieve registered instance synchronously',
        () async {
      // Arrange
      final testInstance = _TestClass('test');
      Circus.hire<_TestClass>(testInstance);

      // Act
      final result = await Circus.findAsync<_TestClass>();

      // Assert
      expect(result, equals(testInstance));
    });

    test('findAsync should create and return async lazy instance', () async {
      // Arrange
      Circus.hireLazilyAsync<_TestClass>(() async => _TestClass('async'));

      // Act
      final result = await Circus.findAsync<_TestClass>();

      // Assert
      expect(result.value, equals('async'));
    });

    test('tryFind should return null when instance not found', () {
      // Act
      final result = Circus.tryFind<_TestClass>();

      // Assert
      expect(result, isNull);
    });

    test('tryFindAsync should return null when instance not found', () async {
      // Act
      final result = await Circus.tryFindAsync<_TestClass>();

      // Assert
      expect(result, isNull);
    });

    test('find should throw when asking for async instance synchronously', () {
      // Arrange
      Circus.hireLazilyAsync<_TestClass>(() async => _TestClass('async'));

      // Act & Assert
      expect(
          () => Circus.find<_TestClass>(), throwsA(isA<CircusRingException>()));
    });
  });

  group('CircusRing Firing (Deletion & Disposal)', () {
    test('fire should delete an instance', () {
      // Arrange
      final testInstance = _TestClass('test');
      Circus.hire<_TestClass>(testInstance);

      // Act
      final result = Circus.fire<_TestClass>();

      // Assert
      expect(result, isTrue);
      expect(Circus.isHired<_TestClass>(), isFalse);
    });

    test('fire should dispose DisposableObject', () {
      // Arrange
      final disposable = _DisposableObject();
      Circus.hire<_DisposableObject>(disposable);
      expect(disposable.isDisposed, isFalse);

      // Act
      final result = Circus.fire<_DisposableObject>();

      // Assert
      expect(result, isTrue);
      expect(disposable.isDisposed, isTrue);
      expect(Circus.isHired<_DisposableObject>(), isFalse);
    });

    test('fire should dispose Joker instance', () {
      // Arrange
      final joker = Joker<int>(10, tag: 'myJoker');
      Circus.hire<Joker<int>>(joker, tag: 'myJoker');
      expect(joker.isDisposed, isFalse);

      // Act
      final result = Circus.fire<Joker<int>>(tag: 'myJoker');

      // Assert
      expect(result, isTrue);
      expect(Circus.isHired<Joker<int>>('myJoker'), isFalse);
      // Joker SHOULD NOW BE disposed by CircusRing.fire
      expect(joker.isDisposed, isTrue);
      // No manual cleanup needed
    });

    testWidgets(
        'fire should dispose Presenter instance and call onDone (widget test)',
        (WidgetTester tester) async {
      // Arrange
      final presenter = TestPresenter<int>(10, tag: 'myPresenter');
      Circus.hire<TestPresenter<int>>(presenter, tag: 'myPresenter');
      expect(presenter.isDisposed, isFalse);
      expect(presenter.doneCalled, isFalse);

      // Act
      final result = Circus.fire<TestPresenter<int>>(tag: 'myPresenter');
      expect(result, isTrue);

      // Use tester.pumpAndSettle() to ensure all work is done
      await tester.pumpAndSettle();

      // Diagnostic log right before expect
      final isDisposedAfterSettle = presenter.isDisposed;
      final doneCalledAfterSettle = presenter.doneCalled;
      debugPrint(
          ">>> [Test Check] After pumpAndSettle: isDisposed=$isDisposedAfterSettle, doneCalled=$doneCalledAfterSettle for ${presenter.tag ?? presenter.runtimeType}");

      // Assert
      expect(Circus.isHired<TestPresenter<int>>('myPresenter'), isFalse);
      expect(isDisposedAfterSettle, isTrue); // Check the captured value
      expect(doneCalledAfterSettle, isTrue); // Check the captured value
    });

    test('fireAsync should delete an instance asynchronously', () async {
      // Arrange
      final testInstance = _TestClass('test');
      Circus.hire<_TestClass>(testInstance);

      // Act
      final result = await Circus.fireAsync<_TestClass>();

      // Assert
      expect(result, isTrue);
      expect(Circus.isHired<_TestClass>(), isFalse);
    });

    test('fireAsync should dispose AsyncDisposableObject', () async {
      // Arrange
      final disposable = _AsyncDisposableObject();
      Circus.hire<_AsyncDisposableObject>(disposable);
      expect(disposable.isDisposed, isFalse);

      // Act
      final result = await Circus.fireAsync<_AsyncDisposableObject>();

      // Assert
      expect(result, isTrue);
      expect(disposable.isDisposed, isTrue);
      expect(Circus.isHired<_AsyncDisposableObject>(), isFalse);
    });

    test('fireAsync should dispose regular DisposableObject too', () async {
      // Arrange
      final disposable = _DisposableObject();
      Circus.hire<_DisposableObject>(disposable);
      expect(disposable.isDisposed, isFalse);

      // Act
      final result = await Circus.fireAsync<_DisposableObject>();

      // Assert
      expect(result, isTrue);
      expect(disposable.isDisposed, isTrue);
      expect(Circus.isHired<_DisposableObject>(), isFalse);
    });

    test('fireAsync should dispose Joker instance', () async {
      // Arrange
      final joker = Joker<int>(10, tag: 'myJokerAsync');
      Circus.hire<Joker<int>>(joker, tag: 'myJokerAsync');
      expect(joker.isDisposed, isFalse);

      // Act
      final result = await Circus.fireAsync<Joker<int>>(tag: 'myJokerAsync');

      // Assert
      expect(result, isTrue);
      expect(Circus.isHired<Joker<int>>('myJokerAsync'), isFalse);
      // Joker SHOULD NOW BE disposed by fireAsync
      expect(joker.isDisposed, isTrue);
      // No manual cleanup needed
    });

    testWidgets(
        'fireAsync should dispose Presenter instance and call onDone (widget test)',
        (WidgetTester tester) async {
      // Arrange
      final presenter = TestPresenter<int>(10, tag: 'myPresenterAsync');
      Circus.hire<TestPresenter<int>>(presenter, tag: 'myPresenterAsync');
      expect(presenter.isDisposed, isFalse);
      expect(presenter.doneCalled, isFalse);

      // Act
      final result =
          await Circus.fireAsync<TestPresenter<int>>(tag: 'myPresenterAsync');
      expect(result, isTrue);

      // Use pumpAndSettle AND an extra pump
      await tester.pumpAndSettle();
      await tester.pump(); // Extra pump

      // Assert
      expect(Circus.isHired<TestPresenter<int>>('myPresenterAsync'), isFalse);
      expect(presenter.isDisposed, isTrue); // Should be disposed
      expect(presenter.doneCalled, isTrue); // onDone should be called
    });

    testWidgets(
        'fireAll should delete all instances and dispose Jokers/Presenters too (widget test)',
        (WidgetTester tester) async {
      // Arrange
      final disposable = _DisposableObject();
      final asyncDisposable = _AsyncDisposableObject();
      final joker = Joker<int>(1, tag: 'joker');
      final presenter = TestPresenter<String>('hello', tag: 'presenter');
      final normal = _TestClass('test');

      Circus.hire<_DisposableObject>(disposable);
      Circus.hire<_AsyncDisposableObject>(asyncDisposable);
      Circus.hire<Joker<int>>(joker, tag: 'joker');
      Circus.hire<TestPresenter<String>>(presenter, tag: 'presenter');
      Circus.hire<_TestClass>(normal);

      expect(disposable.isDisposed, isFalse);
      expect(asyncDisposable.isDisposed, isFalse);
      expect(joker.isDisposed, isFalse);
      expect(presenter.isDisposed, isFalse);
      expect(presenter.doneCalled, isFalse);

      // Act and Assert within runAsync
      await tester.runAsync(() async {
        await Circus.fireAll(); // Perform the async action

        // Add delay *inside* runAsync before pumping
        await Future.delayed(
            const Duration(milliseconds: 10)); // Try a slightly longer delay

        // Pump after the action within runAsync
        await tester.pumpAndSettle();
        await tester.pump(); // Extra pump

        // Assertions
        expect(Circus.isHired<_DisposableObject>(), isFalse);
        expect(Circus.isHired<_AsyncDisposableObject>(), isFalse);
        expect(Circus.isHired<Joker<int>>('joker'), isFalse);
        expect(Circus.isHired<TestPresenter<String>>('presenter'), isFalse);
        expect(Circus.isHired<_TestClass>(), isFalse);

        expect(disposable.isDisposed, isTrue);
        expect(asyncDisposable.isDisposed, isTrue);
        // Joker and Presenter SHOULD NOW BE disposed by fireAll
        expect(joker.isDisposed, isTrue);
        expect(presenter.isDisposed, isTrue);
        expect(presenter.doneCalled, isTrue); // Check assertion here
      });
    });
  });

  group('CircusRing Tag-based Operations', () {
    test('findByTag should retrieve instance by tag', () {
      // Arrange
      final testInstance = _TestClass('test');
      Circus.hire<_TestClass>(testInstance, tag: 'myTag');

      // Act
      final result = Circus.findByTag('myTag');

      // Assert
      expect(result, equals(testInstance));
    });

    test('tryFindByTag should return null when tag not found', () {
      // Act
      final result = Circus.tryFindByTag('nonExistentTag');

      // Assert
      expect(result, isNull);
    });

    test('fireByTag should delete instance and dispose non-Joker', () {
      // Arrange
      final disposable = _DisposableObject();
      Circus.hire<_DisposableObject>(disposable, tag: 'myTag');
      expect(disposable.isDisposed, isFalse);

      // Act
      final result = Circus.fireByTag('myTag');

      // Assert
      expect(result, isTrue);
      expect(Circus.tryFindByTag('myTag'), isNull);
      expect(disposable.isDisposed, isTrue);
    });

    test('fireByTag should delete instance AND dispose Joker', () {
      // Arrange
      final joker = Joker<String>('hello', tag: 'jokerTag');
      Circus.hire<Joker<String>>(joker, tag: 'jokerTag');
      expect(joker.isDisposed, isFalse);

      // Act
      final result = Circus.fireByTag('jokerTag');

      // Assert
      expect(result, isTrue);
      expect(Circus.tryFindByTag('jokerTag'), isNull);
      // Joker SHOULD NOW BE disposed by fireByTag
      expect(joker.isDisposed, isTrue);
      // No manual cleanup needed
    });

    testWidgets(
        'fireByTag should delete instance AND dispose Presenter, calling onDone (widget test)',
        (WidgetTester tester) async {
      // Arrange
      final presenter = TestPresenter<String>('hello', tag: 'presenterTag');
      Circus.hire<TestPresenter<String>>(presenter, tag: 'presenterTag');
      expect(presenter.isDisposed, isFalse);
      expect(presenter.doneCalled, isFalse);

      // Act and Assert within runAsync
      await tester.runAsync(() async {
        final result = Circus.fireByTag('presenterTag'); // fireByTag is sync
        expect(result, isTrue);

        // Add delay *inside* runAsync before pumping
        await Future.delayed(const Duration(milliseconds: 10));

        // Use pumpAndSettle AND an extra pump
        await tester.pumpAndSettle();
        await tester.pump(); // Extra pump

        // Assert
        expect(Circus.tryFindByTag('presenterTag'), isNull);
        expect(presenter.isDisposed, isTrue); // Should be disposed
        expect(presenter.doneCalled, isTrue); // Check assertion here
      });
    });

    test('fireByTag should return false if tag not found', () {
      // Act
      final result = Circus.fireByTag('nonExistentTag');
      // Assert
      expect(result, isFalse);
    });
  });

  group('CircusRing dependency binding', () {
    setUp(() {
      Circus.fireAll(); // Clear all registrations
    });

    test('bindDependency prevents firing dependency being used', () {
      // Arrange
      final api = _ApiService();
      final repo = _UserRepository(api);

      // Register both
      Circus.hire<_ApiService>(api, tag: 'api');
      Circus.hire<_UserRepository>(repo, tag: 'repo');

      // Build dependency
      Circus.bindDependency<_UserRepository, _ApiService>(
          tagT: 'repo', tagD: 'api');

      // Try removing ApiService while still being used
      expect(
        () => Circus.fire<_ApiService>(tag: 'api'),
        throwsA(isA<CircusRingException>()),
      );
      // Try removing ApiService by tag
      expect(
        () => Circus.fireByTag('api'),
        throwsA(isA<CircusRingException>()),
      );
      // Try removing ApiService async
      expect(
        () => Circus.fireAsync<_ApiService>(tag: 'api'),
        throwsA(isA<CircusRingException>()),
      );
    });

    test('bindDependency is cleared when dependent is disposed', () {
      // Arrange & Register
      final api = _ApiService();
      final repo = _UserRepository(api);

      Circus.hire<_ApiService>(api, tag: 'api');
      Circus.hire<_UserRepository>(repo, tag: 'repo');
      Circus.bindDependency<_UserRepository, _ApiService>(
          tagT: 'repo', tagD: 'api');

      // Remove Repo
      final removed = Circus.fire<_UserRepository>(tag: 'repo');
      expect(removed, isTrue); // Can be removed

      // Now ApiService should be safe to remove
      final removedApi = Circus.fire<_ApiService>(tag: 'api');
      expect(removedApi, isTrue);
    });

    test('multiple dependents tracked correctly', () {
      final api = _ApiService();
      final userRepo = _UserRepository(api);
      final postRepo = _PostRepository(api);

      Circus.hire<_ApiService>(api, tag: 'api');
      Circus.hire(userRepo, tag: 'user');
      Circus.hire(postRepo, tag: 'post');

      Circus.bindDependency<_UserRepository, _ApiService>(
          tagT: 'user', tagD: 'api');
      Circus.bindDependency<_PostRepository, _ApiService>(
          tagT: 'post', tagD: 'api');

      // Remove one dependent
      Circus.fire<_UserRepository>(tag: 'user');

      // Still cannot remove api yet
      expect(() => Circus.fire<_ApiService>(tag: 'api'),
          throwsA(isA<CircusRingException>()));

      // Remove second
      final ok = Circus.fire<_PostRepository>(tag: 'post');
      expect(ok, isTrue);

      // Now can remove api
      final removed = Circus.fire<_ApiService>(tag: 'api');
      expect(removed, isTrue);
    });

    test('fireAsync should throw if instance is depended on', () async {
      final api = _ApiService();
      final repo = _UserRepository(api);

      Circus.hire<_ApiService>(api, tag: 'api');
      Circus.hire<_UserRepository>(repo, tag: 'repo');

      Circus.bindDependency<_UserRepository, _ApiService>(
        tagT: 'repo',
        tagD: 'api',
      );

      // Use expectLater for async throws check
      await expectLater(
        Circus.fireAsync<_ApiService>(tag: 'api'),
        throwsA(isA<CircusRingException>()),
      );
    });

    test('fireAsync should cleanup dependencies after removal', () async {
      final api = _ApiService();
      final repo = _UserRepository(api);

      Circus.hire<_ApiService>(api, tag: 'api');
      Circus.hire<_UserRepository>(repo, tag: 'repo');
      Circus.bindDependency<_UserRepository, _ApiService>(
        tagT: 'repo',
        tagD: 'api',
      );

      // Remove dependent first
      final repoRemoved = Circus.fire<_UserRepository>(tag: 'repo');
      expect(repoRemoved, isTrue);

      // Now async remove ok
      final ok = await Circus.fireAsync<_ApiService>(tag: 'api');
      expect(ok, isTrue);
    });
  });
}

class _ApiService {}

class _UserRepository {
  final _ApiService api;

  _UserRepository(this.api);
}

class _PostRepository {
  final _ApiService api;

  _PostRepository(this.api);
}

// Test classes used in tests
class _TestClass {
  final String value;

  _TestClass(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TestClass &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

class _DisposableObject implements Disposable {
  bool isDisposed = false;

  @override
  void dispose() {
    isDisposed = true;
  }
}

class _AsyncDisposableObject implements AsyncDisposable {
  bool isDisposed = false;

  @override
  Future<void> dispose() async {
    isDisposed = true;
  }
}
