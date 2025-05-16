// Represents the counter data model.
class Counter {
  final int value;

  const Counter({required this.value});

  // Creates a copy with optional value change.
  Counter copyWith({int? value}) {
    return Counter(
      value: value ?? this.value,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Counter &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}
