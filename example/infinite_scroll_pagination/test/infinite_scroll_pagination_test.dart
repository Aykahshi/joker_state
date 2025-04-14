import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state_infinite_scroll_pagination_example/main.dart';

Future<void> scrollToVisibleItem(WidgetTester tester, String text) async {
  final scrollable = find.byType(Scrollable);

  const scrollOffset = Offset(0, -300);
  const maxScrolls = 30;

  for (int i = 0; i < maxScrolls; i++) {
    if (find.text(text).evaluate().isNotEmpty) {
      return;
    }

    await tester.drag(scrollable, scrollOffset);
    await tester.pumpAndSettle();

    await tester.pump(const Duration(milliseconds: 100));
  }

  throw Exception('Item "$text" not found after scrolling');
}

void main() {
  testWidgets('initially loads 20 items and displays one of them',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Item 1'), findsOneWidget);
  });

  testWidgets('loads more items after scroll to bottom',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    await scrollToVisibleItem(tester, 'Item 40');

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Item 40'), findsOneWidget);
  });

  testWidgets('loads all items until 100 and shows End of list',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    await scrollToVisibleItem(tester, 'Item 100');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Item 100'), findsOneWidget);
    expect(find.text('End of list'), findsOneWidget);
  });

  testWidgets('does not load more after reaching 100 items',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    await scrollToVisibleItem(tester, 'End of list');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    await scrollToVisibleItem(tester, 'End of list');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Item 100'), findsOneWidget);
    expect(find.text('End of list'), findsOneWidget);
  });
}
