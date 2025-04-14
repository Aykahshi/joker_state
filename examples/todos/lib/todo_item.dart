class TodoItem {
  final String id;
  final String text;
  bool completed;

  TodoItem({
    required this.id,
    required this.text,
    this.completed = false,
  });

  TodoItem copyWith({String? id, String? text, bool? completed}) {
    return TodoItem(
      id: this.id,
      text: text ?? this.text,
      completed: completed ?? this.completed,
    );
  }
}
