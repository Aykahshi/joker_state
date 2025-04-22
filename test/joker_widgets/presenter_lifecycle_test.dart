import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/joker_state.dart';
import 'package:joker_state/src/state_management/presenter/presenter.dart';

// Helper class for testing Presenter lifecycle
class LifecyclePresenter extends Presenter<int> {
  List<String> lifecycleEvents = [];

  LifecyclePresenter(int initial, {String? tag, bool keepAlive = false})
      : super(initial, tag: tag, keepAlive: keepAlive);

  @override
  void onInit() {
    super.onInit();
    lifecycleEvents.add('onInit');
  }

  @override
  void onReady() {
    super.onReady();
    lifecycleEvents.add('onReady');
  }

  @override
  void onDone() {
    lifecycleEvents.add('onDone');
    super.onDone();
  }
}

// --- Test Widgets ---

class _ManagedByStatefulWidget extends StatefulWidget {
  final LifecyclePresenter presenter;
  const _ManagedByStatefulWidget({required this.presenter});

  @override
  State<_ManagedByStatefulWidget> createState() =>
      _ManagedByStatefulWidgetState();
}

class _ManagedByStatefulWidgetState extends State<_ManagedByStatefulWidget> {
  // Note: Presenter is created outside and passed in for this test structure
  // to easily access the presenter instance after disposal.
  // Alternatively, create it here and use a callback for events.

  @override
  Widget build(BuildContext context) {
    return Text('State: ${widget.presenter.state}');
  }

  @override
  void dispose() {
    widget.presenter
        .dispose(); // Manually dispose when stateful widget disposes
    super.dispose();
  }
}

void main() {
  group('Presenter Lifecycle', () {
    setUp(() {
      // Clean up CircusRing before each test
      Circus.fireAll();
    });

    testWidgets(
        'Lifecycle methods called correctly when managed by StatefulWidget',
        (tester) async {
      final presenter = LifecyclePresenter(0);

      // Presenter constructor calls onInit synchronously
      expect(presenter.lifecycleEvents, contains('onInit'));
      expect(presenter.lifecycleEvents, isNot(contains('onReady')));
      expect(presenter.lifecycleEvents, isNot(contains('onDone')));

      await tester.pumpWidget(
          MaterialApp(home: _ManagedByStatefulWidget(presenter: presenter)));

      // onReady is called after the first frame
      await tester.pump(); // Pump the frame for addPostFrameCallback
      expect(presenter.lifecycleEvents, contains('onReady'));
      expect(presenter.lifecycleEvents, isNot(contains('onDone')));

      // Remove the widget, triggering state's dispose, which calls presenter.dispose()
      await tester.pumpWidget(Container());
      await tester.pump(); // Process dispose related tasks

      // onDone is called during dispose
      expect(presenter.lifecycleEvents, contains('onDone'));
      expect(presenter.isDisposed, isTrue);

      // Verify the order roughly
      expect(
          presenter.lifecycleEvents, equals(['onInit', 'onReady', 'onDone']));
    });

    testWidgets('Lifecycle methods called correctly when managed by CircusRing',
        (tester) async {
      // Hire the presenter - constructor runs, onInit runs, onReady scheduled
      final presenter = Circus.hire<LifecyclePresenter>(
          LifecyclePresenter(10, tag: 'circusManaged'),
          tag: 'circusManaged');

      expect(presenter.lifecycleEvents, contains('onInit'));
      expect(presenter.lifecycleEvents, isNot(contains('onReady')));
      expect(presenter.lifecycleEvents, isNot(contains('onDone')));
      expect(presenter.isDisposed, isFalse);

      // Pump a frame to allow onReady to execute
      // Need a widget context for addPostFrameCallback to schedule properly if test runs headless
      await tester.pumpWidget(Container());
      await tester.pump();

      expect(presenter.lifecycleEvents, contains('onReady'));
      expect(presenter.lifecycleEvents, isNot(contains('onDone')));

      // Fire the presenter from CircusRing - should trigger dispose -> onDone
      final removed = Circus.fire<LifecyclePresenter>(tag: 'circusManaged');
      expect(removed, isTrue);

      // onDone should be called
      expect(presenter.lifecycleEvents, contains('onDone'));
      expect(presenter.isDisposed, isTrue);

      // Verify the order roughly
      expect(
          presenter.lifecycleEvents, equals(['onInit', 'onReady', 'onDone']));
    });

    testWidgets('onReady is not called if disposed before frame callback',
        (tester) async {
      // Hire the presenter - onInit runs, onReady scheduled
      final presenter = Circus.hire<LifecyclePresenter>(
          LifecyclePresenter(20, tag: 'quickDispose'),
          tag: 'quickDispose');
      expect(presenter.lifecycleEvents, equals(['onInit']));

      // Immediately fire before pumping a frame
      final removed = Circus.fire<LifecyclePresenter>(tag: 'quickDispose');
      expect(removed, isTrue);
      expect(presenter.isDisposed, isTrue);
      expect(presenter.lifecycleEvents, contains('onDone'));

      // Pump a frame AFTER disposal
      await tester.pumpWidget(Container());
      await tester.pump();

      // Assert: onReady should NOT have been called
      expect(presenter.lifecycleEvents, isNot(contains('onReady')));
      expect(presenter.lifecycleEvents,
          equals(['onInit', 'onDone'])); // Verify order
    });
  });
}
