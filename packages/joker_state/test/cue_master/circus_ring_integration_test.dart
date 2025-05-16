import 'dart:async';

import 'package:circus_ring/circus_ring.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/cue_master.dart';

class IntegrationTestCue extends Cue {
  final String message;
  IntegrationTestCue(this.message);
}

class AnotherIntegrationCue extends Cue {
  final int id;
  AnotherIntegrationCue(this.id);
}

void main() {
  group('CircusRing CueMaster Extension Tests', () {
    tearDown(() async {
      await Circus.fireAll();
    });

    test('getCueMaster should return a CueMaster instance', () {
      final bus = Circus.getCueMaster();
      expect(bus, isA<CueMaster>());
      expect(bus, isA<RingCueMaster>());
    });

    test('getCueMaster should return the same instance for the same tag', () {
      final bus1 = Circus.getCueMaster(tag: 'test_bus');
      final bus2 = Circus.getCueMaster(tag: 'test_bus');
      expect(bus1, same(bus2));
    });

    test('getCueMaster should return different instances for different tags',
        () {
      final bus1 = Circus.getCueMaster(tag: 'bus_A');
      final bus2 = Circus.getCueMaster(tag: 'bus_B');
      expect(bus1, isNot(same(bus2)));
    });

    test('onCue and sendCue should work with default CueMaster', () async {
      final completer = Completer<IntegrationTestCue>();
      Circus.onCue<IntegrationTestCue>((cue) {
        completer.complete(cue);
      });

      final sentCue = IntegrationTestCue('hello default');
      Circus.sendCue(sentCue);

      final receivedCue =
          await completer.future.timeout(Duration(milliseconds: 100));
      expect(receivedCue.message, 'hello default');
    });

    test('onCue and sendCue should work with tagged CueMaster', () async {
      final tag = 'tagged_bus_comm';
      final completer = Completer<IntegrationTestCue>();
      Circus.onCue<IntegrationTestCue>((cue) {
        completer.complete(cue);
      }, tag: tag);

      final sentCue = IntegrationTestCue('hello tagged');
      Circus.sendCue(sentCue, tag: tag);

      final receivedCue =
          await completer.future.timeout(Duration(milliseconds: 100));
      expect(receivedCue.message, 'hello tagged');

      // Ensure it doesn't go to default bus
      bool receivedOnDefault = false;
      final subDefault =
          Circus.onCue<IntegrationTestCue>((_) => receivedOnDefault = true);
      await Future.delayed(Duration(milliseconds: 20));
      expect(receivedOnDefault, isFalse);
      subDefault.cancel();
    });

    test('disposeCueMaster should remove and dispose the CueMaster', () {
      final tag = 'disposable_bus_test';
      final bus = Circus.getCueMaster(tag: tag)
          as RingCueMaster; // Cast for isDisposed check

      expect(Circus.isHired<CueMaster>(tag), isTrue);
      expect(bus.isDisposed, isFalse);

      final success = Circus.disposeCueMaster(tag: tag);
      expect(success, isTrue);
      expect(Circus.isHired<CueMaster>(tag), isFalse);
      expect(bus.isDisposed, isTrue,
          reason:
              "RingCueMaster's dispose should be called by CircusRing.fire");
    });

    test('disposeCueMaster for non-existent tag should return false', () {
      expect(Circus.disposeCueMaster(tag: 'non_existent_bus'), isFalse);
    });

    test('CircusRing.fireAll should dispose all managed CueMasters', () async {
      final busDefault = Circus.getCueMaster() as RingCueMaster;
      final busTagged =
          Circus.getCueMaster(tag: 'another_tagged') as RingCueMaster;

      expect(busDefault.isDisposed, isFalse);
      expect(busTagged.isDisposed, isFalse);

      await Circus.fireAll(); // This is the method being tested

      expect(busDefault.isDisposed, isTrue);
      expect(busTagged.isDisposed, isTrue);
      expect(Circus.isHired<CueMaster>(), isFalse);
      expect(Circus.isHired<CueMaster>('another_tagged'), isFalse);
    });

    test('defaultCueMaster getter should provide the default CueMaster', () {
      final bus1 = Circus.defaultCueMaster;
      final bus2 = Circus.getCueMaster(); // Default tag
      expect(bus1, same(bus2));
    });

    test(
        'getCueMaster with allowReplace=true should replace and dispose old instance',
        () async {
      final tag = 'replaceable_bus_ext';
      final oldBus = Circus.getCueMaster(tag: tag) as RingCueMaster;

      StreamSubscription? oldSub;
      Completer<void> oldStreamDone = Completer();
      oldSub = oldBus.on<String>().listen(
        (_) {},
        onDone: () {
          if (!oldStreamDone.isCompleted) oldStreamDone.complete();
        },
      );

      final newBus =
          Circus.getCueMaster(tag: tag, allowReplace: true) as RingCueMaster;

      expect(newBus, isNot(same(oldBus)));
      expect(oldBus.isDisposed, isTrue,
          reason:
              "Old instance should be disposed by hire's replacement logic");
      await expectLater(oldStreamDone.future, completes,
          reason: "Old bus stream should be closed");

      oldSub
          .cancel(); // Cancel the subscription to the old (now disposed) stream.

      // Verify new bus is working
      final newBusCompleter = Completer<String>();
      newBus.listen<String>((data) => newBusCompleter.complete(data));
      Circus.sendCue('hello new', tag: tag);
      expect(await newBusCompleter.future, 'hello new');
    });
  });
}
