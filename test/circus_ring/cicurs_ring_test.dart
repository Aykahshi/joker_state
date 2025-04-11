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

    test('hire should replace existing instance', () {
      // Arrange
      final testInstance1 = _TestClass('test1');
      final testInstance2 = _TestClass('test2');

      // Act
      Circus.hire<_TestClass>(testInstance1);
      Circus.hire<_TestClass>(testInstance2);

      // Assert
      expect(Circus.find<_TestClass>(), equals(testInstance2));
    });

    test('hireAsync should register an asynchronous singleton', () async {
      // Arrange
      final builder = () async => _TestClass('async');

      // Act
      final result = await Circus.hireAsync<_TestClass>(builder);

      // Assert
      expect(result.value, equals('async'));
      expect((await Circus.findAsync<_TestClass>()).value, equals('async'));
    });

    test('hireLazily should register a lazy singleton', () {
      // Arrange
      int count = 0;
      final builder = () {
        count++;
        return _TestClass('lazy');
      };

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
      final builder = () async {
        count++;
        return _TestClass('async lazy');
      };

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

    test('contract should register a factory', () {
      // Arrange
      int count = 0;
      final builder = () {
        count++;
        return _TestClass('factory');
      };

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
      final builder = () => _TestClass('draft');

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

  group('CircusRing Disposing', () {
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

      // Act
      Circus.fire<_DisposableObject>();

      // Assert
      expect(disposable.isDisposed, isTrue);
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

      // Act
      await Circus.fireAsync<_AsyncDisposableObject>();

      // Assert
      expect(disposable.isDisposed, isTrue);
    });

    test('fireAll should delete all instances', () {
      // Arrange
      Circus.hire<_TestClass>(_TestClass('test1'));
      Circus.hire<String>('test2');

      // Act
      Circus.fireAll();

      // Assert
      expect(Circus.isHired<_TestClass>(), isFalse);
      expect(Circus.isHired<String>(), isFalse);
    });

    test('fireAllAsync should delete all instances asynchronously', () async {
      // Arrange
      Circus.hire<_TestClass>(_TestClass('test1'));
      Circus.hire<String>('test2');

      // Act
      await Circus.fireAllAsync();

      // Assert
      expect(Circus.isHired<_TestClass>(), isFalse);
      expect(Circus.isHired<String>(), isFalse);
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

    test('fireByTag should delete instance by tag', () {
      // Arrange
      Circus.hire<_TestClass>(_TestClass('test'), tag: 'myTag');

      // Act
      final result = Circus.fireByTag('myTag');

      // Assert
      expect(result, isTrue);
      expect(Circus.tryFindByTag('myTag'), isNull);
    });
  });

  group('CircusRing dependency binding', () {
    setUp(() {
      Circus.fireAll(); // 清除所有註冊
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
      expect(removed, isTrue); // 可以移除

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

      expect(
        () => Circus.fireAsync<_ApiService>(tag: 'api'),
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
