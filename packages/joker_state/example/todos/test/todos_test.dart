import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joker_state/joker_state.dart';
import 'package:joker_state_todo_example/main.dart';
import 'package:joker_state_todo_example/todo_item.dart';

void main() {
  // Add setUp and tearDown for state isolation
  setUp(() async {
    // Ensure clean state before each test
    await Circus.fireAll();
    // Initialize necessary Jokers if main() isn't run
    Circus.summon<List<TodoItem>>([], tag: 'todos');
  });

  tearDown(() async {
    // Clean up after each test
    await Circus.fireAll();
  });

  testWidgets('displays empty message when no todos', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('There are no todos - add some!'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('adds a todo item and displays it', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Buy eggs');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Buy eggs'), findsOneWidget);
    expect(find.byType(ListTile), findsOneWidget);
  });

  testWidgets('checkbox toggles completion correctly', (tester) async {
    await tester.pumpWidget(const MyApp());

    final todosJoker = Circus.spotlight<List<TodoItem>>(tag: 'todos');
    todosJoker.trick([TodoItem(id: '1', text: 'Write test')]);

    await tester.pumpAndSettle();

    Checkbox checkbox = tester.widget(find.byType(Checkbox));
    expect(checkbox.value, false);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    checkbox = tester.widget(find.byType(Checkbox));
    expect(checkbox.value, true);
  });

  testWidgets('delete button removes todo item from list', (tester) async {
    await tester.pumpWidget(const MyApp());

    final joker = Circus.spotlight<List<TodoItem>>(tag: 'todos');
    joker.trick([TodoItem(id: 'delete_me', text: 'To be deleted')]);

    await tester.pumpAndSettle();

    expect(find.text('To be deleted'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(find.text('To be deleted'), findsNothing);
    expect(joker.state.isEmpty, true);
  });

  testWidgets('multiple todos display correctly', (tester) async {
    await tester.pumpWidget(const MyApp());

    final todos = [
      TodoItem(id: 'a', text: 'Milk'),
      TodoItem(id: 'b', text: 'Eggs'),
      TodoItem(id: 'c', text: 'Bread'),
    ];

    final joker = Circus.spotlight<List<TodoItem>>(tag: 'todos');
    joker.trick(todos);
    await tester.pumpAndSettle();

    for (final todo in todos) {
      expect(find.text(todo.text), findsOneWidget);
    }

    expect(find.byType(ListTile), findsNWidgets(3));
  });
}
