import '../helpers/list_helper.dart';

/// List extensions for convenient methods
extension ListExtensions<T> on List<T> {
  /// Group list by key function
  Map<K, List<T>> groupBy<K>(K Function(T item) keyFunction) {
    return ListHelper.groupBy(this, keyFunction);
  }

  /// Sort list by key function
  List<T> sortBy<K extends Comparable<K>>(K Function(T item) keyFunction,
      {bool ascending = true}) {
    return ListHelper.sortBy(this, keyFunction, ascending: ascending);
  }

  /// Sort list by multiple key functions
  List<T> sortByMultiple(List<Comparable Function(T item)> keyFunctions,
      {List<bool> ascending = const []}) {
    return ListHelper.sortByMultiple(this, keyFunctions, ascending: ascending);
  }

  /// Filter list by condition
  List<T> filter(bool Function(T item) condition) {
    return where(condition).toList();
  }

  /// Get first item or null if empty
  T? get firstOrNull => isEmpty ? null : first;

  /// Get last item or null if empty
  T? get lastOrNull => isEmpty ? null : last;

  /// Get item at index or null if out of bounds
  T? getAt(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  /// Add item if not null
  void addIfNotNull(T? item) {
    if (item != null) add(item);
  }

  /// Add all items that are not null
  void addAllNotNull(Iterable<T?> items) {
    for (final item in items) {
      addIfNotNull(item);
    }
  }

  /// Remove all items that match condition
  void removeWhereAll(bool Function(T item) condition) {
    removeWhere(condition);
  }

  /// Remove first item that matches condition
  bool removeFirstWhere(bool Function(T item) condition) {
    final index = indexWhere(condition);
    if (index != -1) {
      removeAt(index);
      return true;
    }
    return false;
  }

  /// Replace first item that matches condition
  bool replaceFirstWhere(bool Function(T item) condition, T newItem) {
    final index = indexWhere(condition);
    if (index != -1) {
      this[index] = newItem;
      return true;
    }
    return false;
  }

  /// Replace all items that match condition
  void replaceWhere(bool Function(T item) condition, T newItem) {
    for (int i = 0; i < length; i++) {
      if (condition(this[i])) {
        this[i] = newItem;
      }
    }
  }

  /// Transform list to map
  Map<K, V> toMap<K, V>(
      K Function(T item) keyFunction, V Function(T item) valueFunction) {
    return Map.fromEntries(
      map((item) => MapEntry(keyFunction(item), valueFunction(item))),
    );
  }

  /// Transform list to map with multiple values per key
  Map<K, List<V>> toMapWithList<K, V>(
      K Function(T item) keyFunction, V Function(T item) valueFunction) {
    final map = <K, List<V>>{};
    for (final item in this) {
      final key = keyFunction(item);
      final value = valueFunction(item);
      map.putIfAbsent(key, () => []).add(value);
    }
    return map;
  }

  /// Get unique items based on key function
  List<T> uniqueBy<K>(K Function(T item) keyFunction) {
    final seen = <K>{};
    return where((item) => seen.add(keyFunction(item))).toList();
  }

  /// Get items that appear more than once
  List<T> duplicatesBy<K>(K Function(T item) keyFunction) {
    final seen = <K>{};
    final duplicates = <K>{};
    for (final item in this) {
      final key = keyFunction(item);
      if (!seen.add(key)) {
        duplicates.add(key);
      }
    }
    return where((item) => duplicates.contains(keyFunction(item))).toList();
  }

  /// Partition list into two lists based on condition
  (List<T>, List<T>) partition(bool Function(T item) condition) {
    final trueList = <T>[];
    final falseList = <T>[];
    for (final item in this) {
      if (condition(item)) {
        trueList.add(item);
      } else {
        falseList.add(item);
      }
    }
    return (trueList, falseList);
  }

  /// Get items in chunks of specified size
  List<List<T>> chunked(int chunkSize) {
    if (chunkSize <= 0) return [this];
    final chunks = <List<T>>[];
    for (int i = 0; i < length; i += chunkSize) {
      chunks.add(sublist(i, (i + chunkSize).clamp(0, length)));
    }
    return chunks;
  }

  /// Get items with indices
  List<(int, T)> withIndices() {
    return asMap().entries.map((entry) => (entry.key, entry.value)).toList();
  }

  /// Get items that are not null
  List<T> whereNotNull() {
    return where((item) => item != null).cast<T>().toList();
  }

  /// Get items that are not empty (for strings)
  List<T> whereNotEmpty() {
    return where((item) => item.toString().isNotEmpty).toList();
  }

  /// Get items that are not blank (for strings)
  List<T> whereNotBlank() {
    return where((item) => item.toString().trim().isNotEmpty).toList();
  }

  /// Shuffle list in place
  void shuffleInPlace() {
    shuffle();
  }

  /// Get random item or null if empty
  T? get randomOrNull {
    if (isEmpty) return null;
    return this[DateTime.now().millisecondsSinceEpoch % length];
  }

  /// Get random items (with replacement)
  List<T> randomItems(int count) {
    if (isEmpty) return [];
    final result = <T>[];
    for (int i = 0; i < count; i++) {
      result.add(this[DateTime.now().millisecondsSinceEpoch % length]);
    }
    return result;
  }

  /// Get random items (without replacement)
  List<T> randomItemsUnique(int count) {
    if (isEmpty) return [];
    final shuffled = List<T>.from(this)..shuffle();
    return shuffled.take(count).toList();
  }

  /// Check if all items match condition
  bool all(bool Function(T item) condition) {
    return every(condition);
  }

  /// Check if any item matches condition
  bool any(bool Function(T item) condition) {
    return this.any(condition);
  }

  /// Check if none of the items match condition
  bool none(bool Function(T item) condition) {
    return !any(condition);
  }

  /// Count items that match condition
  int count(bool Function(T item) condition) {
    return where(condition).length;
  }

  /// Get sum of numeric values
  num sum(num Function(T item) selector) {
    return fold(0, (sum, item) => sum + selector(item));
  }

  /// Get average of numeric values
  double average(num Function(T item) selector) {
    if (isEmpty) return 0;
    return sum(selector) / length;
  }

  /// Get minimum value
  T? minBy<K extends Comparable<K>>(K Function(T item) selector) {
    if (isEmpty) return null;
    return reduce((a, b) => selector(a).compareTo(selector(b)) <= 0 ? a : b);
  }

  /// Get maximum value
  T? maxBy<K extends Comparable<K>>(K Function(T item) selector) {
    if (isEmpty) return null;
    return reduce((a, b) => selector(a).compareTo(selector(b)) >= 0 ? a : b);
  }
}
