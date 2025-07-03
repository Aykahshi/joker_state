import 'dart:collection';

/// A collection of utility functions for equality checks.

/// Checks if two objects are deeply equal.
///
/// This function performs a recursive comparison of nested collections (List, Map, Set)
/// and handles cyclical object references to prevent infinite loops.
///
/// - For [List]s, it checks if they have the same length and if each element
///   at the same index is deeply equal.
/// - For [Map]s, it checks if they have the same length and if the value for
///   each key is deeply equal.
/// - For [Set]s, it checks if they have the same length and if they contain
///   the same elements, regardless of order.
/// - For all other types, it uses the standard `==` operator.
/// - It correctly handles cycles in the object graph.
bool isDeeplyEqual(dynamic a, dynamic b) {
  // Use a Set to keep track of visited pairs to detect cycles.
  final visited = HashSet<List<dynamic>>(
      hashCode: (p) => identityHashCode(p[0]) ^ identityHashCode(p[1]),
      equals: (p1, p2) => identical(p1[0], p2[0]) && identical(p1[1], p2[1]));
  return _isDeeplyEqualRecursive(a, b, visited);
}

bool _isDeeplyEqualRecursive(
    dynamic a, dynamic b, HashSet<List<dynamic>> visited) {
  if (identical(a, b)) return true;

  // If this pair has been visited, we have a cycle.
  final pair = [a, b];
  if (visited.contains(pair)) return true;

  // Add the pair to the visited set for this recursive path.
  visited.add(pair);

  try {
    if (a is List) {
      if (b is! List || a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_isDeeplyEqualRecursive(a[i], b[i], visited)) return false;
      }
      return true;
    }

    if (a is Map) {
      if (b is! Map || a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key) ||
            !_isDeeplyEqualRecursive(a[key], b[key], visited)) {
          return false;
        }
      }
      return true;
    }

    if (a is Set) {
      if (b is! Set || a.length != b.length) return false;
      final bCopy = Set.of(b); // Create a mutable copy.
      for (final valA in a) {
        final found = bCopy.firstWhere(
            (valB) => _isDeeplyEqualRecursive(valA, valB, visited),
            orElse: () => null);
        if (found != null) {
          bCopy.remove(found);
        } else {
          return false; // No matching element found for valA.
        }
      }
      return true;
    }

    return a == b;
  } finally {
    // Remove the pair after the check is complete for this path.
    visited.remove(pair);
  }
}
