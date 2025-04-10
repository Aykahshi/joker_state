import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/src/di/circus_ring/circus_ring.dart';
import 'package:joker_state/src/state_management/joker/joker.dart';

void main() {
  setUp(() {
    // Reset CircusRing before each test
    Circus.fireAll();
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

    test('should enable and disable logs', () {
      // Arrange & Act
      Circus.config(enableLogs: true);

      // We don't have direct access to _enableLogs, but we can test that
      // the configuration doesn't throw an exception
      expect(() => Circus.config(enableLogs: false), returnsNormally);
    });
  });

  group('CircusRing Hiring (Registration)', () {
    test('hire should register a synchronous singleton', () {
      // Arrange
      final testInstance = TestClass('test');

      // Act
      final result = Circus.hire<TestClass>(testInstance);

      // Assert
      expect(result, equals(testInstance));
      expect(Circus.find<TestClass>(), equals(testInstance));
      expect(Circus.isHired<TestClass>(), isTrue);
    });

    test('hire should register a singleton with tag', () {
      // Arrange
      final testInstance1 = TestClass('test1');
      final testInstance2 = TestClass('test2');

      // Act
      Circus.hire<TestClass>(testInstance1, tag: 'tag1');
      Circus.hire<TestClass>(testInstance2, tag: 'tag2');

      // Assert
      expect(Circus.find<TestClass>('tag1'), equals(testInstance1));
      expect(Circus.find<TestClass>('tag2'), equals(testInstance2));
    });

    test('hire should throw when registering Joker without tag', () {
      // Arrange
      final jokerInstance = Joker<String>('test');

      // Act & Assert
      expect(() => Circus.hire<Joker<String>>(jokerInstance),
          throwsA(isA<CircusRingException>()));
    });

    test('hire should replace existing instance', () {
      // Arrange
      final testInstance1 = TestClass('test1');
      final testInstance2 = TestClass('test2');

      // Act
      Circus.hire<TestClass>(testInstance1);
      Circus.hire<TestClass>(testInstance2);

      // Assert
      expect(Circus.find<TestClass>(), equals(testInstance2));
    });

    test('hireAsync should register an asynchronous singleton', () async {
      // Arrange
      final builder = () async => TestClass('async');

      // Act
      final result = await Circus.hireAsync<TestClass>(builder);

      // Assert
      expect(result.value, equals('async'));
      expect((await Circus.findAsync<TestClass>()).value, equals('async'));
    });

    test('hireLazily should register a lazy singleton', () {
      // Arrange
      int count = 0;
      final builder = () {
        count++;
        return TestClass('lazy');
      };

      // Act
      Circus.hireLazily<TestClass>(builder);

      // Assert - Instance should not be created yet
      expect(count, equals(0));

      // Act - Access the instance
      final instance = Circus.find<TestClass>();

      // Assert - Instance should be created only once
      expect(count, equals(1));
      expect(instance.value, equals('lazy'));

      // Access again should not create a new instance
      final instance2 = Circus.find<TestClass>();
      expect(count, equals(1));
      expect(instance2, same(instance));
    });

    test('hireLazilyAsync should register an async lazy singleton', () async {
      // Arrange
      int count = 0;
      final builder = () async {
        count++;
        return TestClass('async lazy');
      };

      // Act
      Circus.hireLazilyAsync<TestClass>(builder);

      // Assert - Instance should not be created yet
      expect(count, equals(0));

      // Act - Access the instance
      final instance = await Circus.findAsync<TestClass>();

      // Assert - Instance should be created
      expect(count, equals(1));
      expect(instance.value, equals('async lazy'));

      // Access again should not create a new instance
      final instance2 = await Circus.findAsync<TestClass>();
      expect(count, equals(1));
      expect(instance2, same(instance));
    });

    test('contract should register a factory', () {
      // Arrange
      int count = 0;
      final builder = () {
        count++;
        return TestClass('factory');
      };

      // Act
      Circus.contract<TestClass>(builder);

      // Assert - Each access should create new instance
      final instance1 = Circus.find<TestClass>();
      expect(count, equals(1));
      expect(instance1.value, equals('factory'));

      final instance2 = Circus.find<TestClass>();
      expect(count, equals(2));
      expect(instance2.value, equals('factory'));
      expect(instance2, isNot(same(instance1)));
    });

    test('appoint should register a singleton (alias for hire)', () {
      // Arrange
      final testInstance = TestClass('appointed');

      // Act
      final result = Circus.appoint<TestClass>(testInstance);

      // Assert
      expect(result, equals(testInstance));
      expect(Circus.find<TestClass>(), equals(testInstance));
    });

    test('draft should create instance without registration', () {
      // Arrange
      final builder = () => TestClass('draft');

      // Act
      final result = Circus.draft<TestClass>(builder: builder);

      // Assert
      expect(result.value, equals('draft'));
      expect(Circus.isHired<TestClass>(), isFalse);
      expect(
          () => Circus.find<TestClass>(), throwsA(isA<CircusRingException>()));
    });
  });

  group('CircusRing Finding', () {
    test('find should retrieve registered instance', () {
      // Arrange
      final testInstance = TestClass('test');
      Circus.hire<TestClass>(testInstance);

      // Act
      final result = Circus.find<TestClass>();

      // Assert
      expect(result, equals(testInstance));
    });

    test('find should throw when instance not found', () {
      // Act & Assert
      expect(
          () => Circus.find<TestClass>(), throwsA(isA<CircusRingException>()));
    });

    test('findAsync should retrieve registered instance synchronously',
        () async {
      // Arrange
      final testInstance = TestClass('test');
      Circus.hire<TestClass>(testInstance);

      // Act
      final result = await Circus.findAsync<TestClass>();

      // Assert
      expect(result, equals(testInstance));
    });

    test('findAsync should create and return async lazy instance', () async {
      // Arrange
      Circus.hireLazilyAsync<TestClass>(() async => TestClass('async'));

      // Act
      final result = await Circus.findAsync<TestClass>();

      // Assert
      expect(result.value, equals('async'));
    });

    test('tryFind should return null when instance not found', () {
      // Act
      final result = Circus.tryFind<TestClass>();

      // Assert
      expect(result, isNull);
    });

    test('tryFindAsync should return null when instance not found', () async {
      // Act
      final result = await Circus.tryFindAsync<TestClass>();

      // Assert
      expect(result, isNull);
    });

    test('find should throw when asking for async instance synchronously', () {
      // Arrange
      Circus.hireLazilyAsync<TestClass>(() async => TestClass('async'));

      // Act & Assert
      expect(
          () => Circus.find<TestClass>(), throwsA(isA<CircusRingException>()));
    });
  });

  group('CircusRing Disposing', () {
    test('fire should delete an instance', () {
      // Arrange
      final testInstance = TestClass('test');
      Circus.hire<TestClass>(testInstance);

      // Act
      final result = Circus.fire<TestClass>();

      // Assert
      expect(result, isTrue);
      expect(Circus.isHired<TestClass>(), isFalse);
    });

    test('fire should dispose DisposableObject', () {
      // Arrange
      final disposable = DisposableObject();
      Circus.hire<DisposableObject>(disposable);

      // Act
      Circus.fire<DisposableObject>();

      // Assert
      expect(disposable.isDisposed, isTrue);
    });

    test('fireAsync should delete an instance asynchronously', () async {
      // Arrange
      final testInstance = TestClass('test');
      Circus.hire<TestClass>(testInstance);

      // Act
      final result = await Circus.fireAsync<TestClass>();

      // Assert
      expect(result, isTrue);
      expect(Circus.isHired<TestClass>(), isFalse);
    });

    test('fireAsync should dispose AsyncDisposableObject', () async {
      // Arrange
      final disposable = AsyncDisposableObject();
      Circus.hire<AsyncDisposableObject>(disposable);

      // Act
      await Circus.fireAsync<AsyncDisposableObject>();

      // Assert
      expect(disposable.isDisposed, isTrue);
    });

    test('fireAll should delete all instances', () {
      // Arrange
      Circus.hire<TestClass>(TestClass('test1'));
      Circus.hire<String>('test2');

      // Act
      Circus.fireAll();

      // Assert
      expect(Circus.isHired<TestClass>(), isFalse);
      expect(Circus.isHired<String>(), isFalse);
    });

    test('fireAllAsync should delete all instances asynchronously', () async {
      // Arrange
      Circus.hire<TestClass>(TestClass('test1'));
      Circus.hire<String>('test2');

      // Act
      await Circus.fireAllAsync();

      // Assert
      expect(Circus.isHired<TestClass>(), isFalse);
      expect(Circus.isHired<String>(), isFalse);
    });
  });

  group('CircusRing Tag-based Operations', () {
    test('findByTag should retrieve instance by tag', () {
      // Arrange
      final testInstance = TestClass('test');
      Circus.hire<TestClass>(testInstance, tag: 'myTag');

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

    test('fireByTag should delete instance by tag', () {
      // Arrange
      Circus.hire<TestClass>(TestClass('test'), tag: 'myTag');

      // Act
      final result = Circus.fireByTag('myTag');

      // Assert
      expect(result, isTrue);
      expect(Circus.tryFindByTag('myTag'), isNull);
    });
  });
}

// Test classes used in tests
class TestClass {
  final String value;

  TestClass(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestClass &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

class DisposableObject implements Disposable {
  bool isDisposed = false;

  @override
  void dispose() {
    isDisposed = true;
  }
}

class AsyncDisposableObject implements AsyncDisposable {
  bool isDisposed = false;

  @override
  Future<void> dispose() async {
    isDisposed = true;
  }
}

class TestChangeNotifier extends ChangeNotifier {
  bool isDisposed = false;

  @override
  void dispose() {
    isDisposed = true;
    super.dispose();
  }
}
