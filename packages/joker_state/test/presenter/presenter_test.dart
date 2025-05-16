import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/joker_state.dart';

class TestState {
  final int value;
  const TestState(this.value);
}

class TestAutoDisposePresenter extends Presenter<TestState> {
  TestAutoDisposePresenter(
    super.initial, {
    super.autoNotify = true,
    super.keepAlive = false,
  });
}

void main() {
  setUp(() => TestWidgetsFlutterBinding.ensureInitialized());

  testWidgets('Presenter onInit/onReady/onDone follow widget lifecycle',
      (tester) async {
    final log = <String>[];
    final presenter = _SpyPresenter(
      onInitCb: () => log.add('init'),
      onReadyCb: () => log.add('ready'),
      onDoneCb: () => log.add('done'),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: presenter.perform(
          builder: (_, state) => Text('State: ${state.value}'),
        ),
      ),
    ));

    expect(log, contains('init'));

    await tester.pump();
    expect(log, contains('ready'));

    await tester.pumpWidget(Container());
    await tester.pump();
    expect(presenter.isDisposed, true);
    expect(log, contains('done'));
  });

  testWidgets('Presenter effect on runOnInit & on state change',
      (tester) async {
    final log = <String>[];
    final presenter = TestAutoDisposePresenter(const TestState(1));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: presenter.effect(
          child: Container(),
          effect: (s, _) => log.add('effect:${s.value}'),
          runOnInit: true,
        ),
      ),
    ));

    await tester.pump();
    expect(log, contains('effect:1'));

    presenter.trick(const TestState(20));
    await tester.pump();
    expect(log.last, 'effect:20');

    await tester.pumpWidget(Container());
    await tester.pump();
    expect(presenter.isDisposed, true);
  });

  testWidgets('Presenter effect only triggers with effectWhen', (tester) async {
    final log = <String>[];
    final presenter = TestAutoDisposePresenter(const TestState(1));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: presenter.effect(
          child: Container(),
          effect: (s, _) => log.add('effect:${s.value}'),
          runOnInit: false,
          effectWhen: (prev, val) => (prev.value ~/ 5) != (val.value ~/ 5),
        ),
      ),
    ));

    expect(log, isEmpty);

    for (var i = 2; i <= 4; i++) {
      presenter.trick(TestState(i));
      await tester.pump();
      expect(log, isEmpty);
    }

    presenter.trick(const TestState(5));
    await tester.pump();
    expect(log.single, 'effect:5');
  });

  testWidgets('Presenter focusOn and focusOnMulti rebuild and dispose',
      (tester) async {
    final presenter = TestAutoDisposePresenter(const TestState(5));
    var foCount = 0, foMCount = 0;
    await tester.pumpWidget(MaterialApp(
      home: Column(
        children: [
          presenter.focusOn<int>(
              selector: (s) => s.value,
              builder: (_, v) {
                foCount++;
                return Text('Value $v');
              }),
          presenter.focusOnMulti(
            selectors: [(s) => s.value, (s) => s.value + 1],
            builder: (_, list) {
              foMCount++;
              return Text('VS: ${list[0]}, ${list[1]}');
            },
          ),
        ],
      ),
    ));

    expect(find.text('Value 5'), findsOneWidget);
    expect(find.text('VS: 5, 6'), findsOneWidget);
    expect(foCount, 1);
    expect(foMCount, 1);

    presenter.trick(const TestState(6));
    await tester.pump();
    expect(find.text('Value 6'), findsOneWidget);
    expect(find.text('VS: 6, 7'), findsOneWidget);
    expect(foCount, 2);
    expect(foMCount, 2);

    await tester.pumpWidget(Container());
    await tester.pump();
    expect(presenter.isDisposed, true);
  });

  testWidgets('PresenterTroupe autoDispose all included presenters',
      (tester) async {
    final name = TestAutoDisposePresenter(const TestState(10));
    final age = TestAutoDisposePresenter(const TestState(20));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: [name, age].troupe<(TestState, TestState)>(
          converter: (l) => (l[0] as TestState, l[1] as TestState),
          builder: (context, data) => Text('${data.$1.value},${data.$2.value}'),
        ),
      ),
    ));
    expect(name.isDisposed, false);
    expect(age.isDisposed, false);

    await tester.pumpWidget(Container());
    await tester.pump();
    expect(name.isDisposed, true);
    expect(age.isDisposed, true);
  });

  testWidgets('should auto dispose when perform widget is removed',
      (tester) async {
    final presenter = TestAutoDisposePresenter(const TestState(0));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: presenter.perform(
            builder: (_, state) => Text('State: ${state.value}')),
      ),
    ));
    expect(presenter.hasListeners, true);
    expect(presenter.isDisposed, false);

    await tester.pumpWidget(Container());
    await tester.pump(); // 等一幀讓 autoDispose 觸發
    expect(presenter.isDisposed, true);
  });

  testWidgets('should not auto dispose if keepAlive is true', (tester) async {
    final presenter =
        TestAutoDisposePresenter(const TestState(0), keepAlive: true);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: presenter.perform(
            builder: (_, state) => Text('State: ${state.value}')),
      ),
    ));
    expect(presenter.hasListeners, true);
    await tester.pumpWidget(Container());
    await tester.pump();
    expect(presenter.isDisposed, false);
  });

  testWidgets('should auto dispose when effect is removed', (tester) async {
    final presenter = TestAutoDisposePresenter(const TestState(0));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: presenter.effect(
          child: Container(),
          effect: (_, __) {},
        ),
      ),
    ));
    expect(presenter.hasListeners, true);
    expect(presenter.isDisposed, false);

    await tester.pumpWidget(Container());
    await tester.pump();
    expect(presenter.isDisposed, true);
  });

  testWidgets('should auto dispose for troupe when all widgets removed',
      (tester) async {
    final p1 = TestAutoDisposePresenter(const TestState(1));
    final p2 = TestAutoDisposePresenter(const TestState(2));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: [p1, p2].troupe<(TestState, TestState)>(
          converter: (values) =>
              (values[0] as TestState, values[1] as TestState),
          builder: (context, rec) => Text('${rec.$1.value}, ${rec.$2.value}'),
        ),
      ),
    ));
    expect(p1.isDisposed, false);
    expect(p2.isDisposed, false);

    await tester.pumpWidget(Container());
    await tester.pump();
    expect(p1.isDisposed, true);
    expect(p2.isDisposed, true);
  });

  testWidgets('should work with focusOn & focusOnMulti and auto dispose',
      (tester) async {
    final presenter = TestAutoDisposePresenter(const TestState(42));
    int focusBuildCount = 0, multiBuildCount = 0;

    await tester.pumpWidget(MaterialApp(
      home: Column(
        children: [
          presenter.focusOn<int>(
            selector: (s) => s.value,
            builder: (_, v) {
              focusBuildCount++;
              return Text('Value $v');
            },
          ),
          presenter.focusOnMulti(
            selectors: [(s) => s.value, (s) => s.value + 1],
            builder: (_, list) {
              multiBuildCount++;
              return Text('VS: ${list[0]}, ${list[1]}');
            },
          ),
        ],
      ),
    ));

    expect(find.text('Value 42'), findsOneWidget);
    expect(find.text('VS: 42, 43'), findsOneWidget);
    expect(focusBuildCount, 1);
    expect(multiBuildCount, 1);

    presenter.trick(TestState(99));
    await tester.pump();
    expect(find.text('Value 99'), findsOneWidget);
    expect(find.text('VS: 99, 100'), findsOneWidget);
    expect(focusBuildCount, 2);
    expect(multiBuildCount, 2);

    await tester.pumpWidget(Container());
    await tester.pump();
    expect(presenter.isDisposed, true);
  });
}

class _SpyPresenter extends Presenter<TestState> {
  final void Function()? onInitCb;
  final void Function()? onReadyCb;
  final void Function()? onDoneCb;
  _SpyPresenter({this.onInitCb, this.onReadyCb, this.onDoneCb})
      : super(const TestState(9));

  @override
  void onInit() {
    super.onInit();
    onInitCb?.call();
  }

  @override
  void onReady() {
    super.onReady();
    onReadyCb?.call();
  }

  @override
  void onDone() {
    super.onDone();
    onDoneCb?.call();
  }
}
