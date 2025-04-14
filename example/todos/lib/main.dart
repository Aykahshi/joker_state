import 'package:flutter/material.dart';
import 'package:joker_state/joker_state.dart';

import 'todo_item.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Joker TODO App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const TodoScreen(),
    );
  }
}

class TodoScreen extends StatelessWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // You can create a new instance of Joker by calling summon without context!
    final todosJoker = Circus.summon<List<TodoItem>>(
      [],
      tag: 'todos',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Joker TODO App'),
        backgroundColor: Colors.blue,
      ),
      body: todosJoker.perform(
        // Disable auto-dispose to make testing easier
        autoDispose: false,
        builder: (context, todos) {
          if (todos.isEmpty) {
            return const Center(
              child: Text('There are no todos - add some!'),
            );
          }

          return ListView.builder(
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];
              return TodoListItem(todo: todo);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTodoDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTodoDialog(BuildContext context) {
    final textController = TextEditingController();
    final todosJoker = Circus.spotlight<List<TodoItem>>(tag: 'todos');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Todo'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(hintText: 'Enter a todo'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                _addTodo(todosJoker, text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addTodo(Joker<List<TodoItem>> todosJoker, String text) {
    todosJoker.trickWith((currentTodos) {
      final newTodo = TodoItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
      );

      return [...currentTodos, newTodo];
    });
  }
}

class TodoListItem extends StatelessWidget {
  final TodoItem todo;

  const TodoListItem({
    super.key,
    required this.todo,
  });

  @override
  Widget build(BuildContext context) {
    final todosJoker = Circus.spotlight<List<TodoItem>>(tag: 'todos');

    return ListTile(
      leading: Checkbox(
        value: todo.completed,
        onChanged: (value) {
          _toggleTodoCompletion(todosJoker, todo);
        },
      ),
      title: Text(
        todo.text,
        style: TextStyle(
          decoration: todo.completed ? TextDecoration.lineThrough : null,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () => _deleteTodo(todosJoker, todo),
      ),
    );
  }

  void _toggleTodoCompletion(
    Joker<List<TodoItem>> todosJoker,
    TodoItem todo,
  ) {
    todosJoker.trickWith(
      (currentTodos) => currentTodos.map((item) {
        if (item.id == todo.id) {
          return item.copyWith(completed: !item.completed);
        }
        return item;
      }).toList(),
    );
  }

  void _deleteTodo(
    Joker<List<TodoItem>> todosJoker,
    TodoItem todo,
  ) {
    todosJoker.trickWith(
      (currentTodos) =>
          currentTodos.where((item) => item.id != todo.id).toList(),
    );
  }
}
