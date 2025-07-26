/// List utility functions
class ListHelper {
  /// Group list by key function
  static Map<K, List<T>> groupBy<T, K>(
      List<T> list, K Function(T item) keyFunction) {
    final groups = <K, List<T>>{};

    for (final item in list) {
      final key = keyFunction(item);
      groups.putIfAbsent(key, () => []).add(item);
    }

    return groups;
  }

  /// Sort list by key function
  static List<T> sortBy<T, K extends Comparable<K>>(
      List<T> list, K Function(T item) keyFunction,
      {bool ascending = true}) {
    final sorted = List<T>.from(list);
    sorted.sort((a, b) {
      final comparison = keyFunction(a).compareTo(keyFunction(b));
      return ascending ? comparison : -comparison;
    });
    return sorted;
  }

  /// Sort list by multiple key functions
  static List<T> sortByMultiple<T>(
      List<T> list, List<Comparable Function(T item)> keyFunctions,
      {List<bool> ascending = const []}) {
    final sorted = List<T>.from(list);
    sorted.sort((a, b) {
      for (int i = 0; i < keyFunctions.length; i++) {
        final keyFunction = keyFunctions[i];
        final isAscending = i < ascending.length ? ascending[i] : true;

        final comparison = keyFunction(a).compareTo(keyFunction(b));
        if (comparison != 0) {
          return isAscending ? comparison : -comparison;
        }
      }
      return 0;
    });
    return sorted;
  }

  /// Filter list by condition
  static List<T> filter<T>(List<T> list, bool Function(T item) condition) {
    return list.where(condition).toList();
  }

  /// Map list with index
  static List<R> mapIndexed<T, R>(
      List<T> list, R Function(int index, T item) transform) {
    return List.generate(list.length, (index) => transform(index, list[index]));
  }

  /// Find first item matching condition
  static T? findFirst<T>(List<T> list, bool Function(T item) condition) {
    try {
      return list.firstWhere(condition);
    } catch (e) {
      return null;
    }
  }

  /// Find last item matching condition
  static T? findLast<T>(List<T> list, bool Function(T item) condition) {
    for (int i = list.length - 1; i >= 0; i--) {
      if (condition(list[i])) {
        return list[i];
      }
    }
    return null;
  }

  /// Check if any item matches condition
  static bool any<T>(List<T> list, bool Function(T item) condition) {
    return list.any(condition);
  }

  /// Check if all items match condition
  static bool all<T>(List<T> list, bool Function(T item) condition) {
    return list.every(condition);
  }

  /// Count items matching condition
  static int count<T>(List<T> list, bool Function(T item) condition) {
    return list.where(condition).length;
  }

  /// Remove duplicates while preserving order
  static List<T> distinct<T>(List<T> list) {
    final seen = <T>{};
    final result = <T>[];

    for (final item in list) {
      if (seen.add(item)) {
        result.add(item);
      }
    }

    return result;
  }

  /// Remove duplicates by key function
  static List<T> distinctBy<T, K>(
      List<T> list, K Function(T item) keyFunction) {
    final seen = <K>{};
    final result = <T>[];

    for (final item in list) {
      final key = keyFunction(item);
      if (seen.add(key)) {
        result.add(item);
      }
    }

    return result;
  }

  /// Chunk list into smaller lists
  static List<List<T>> chunk<T>(List<T> list, int chunkSize) {
    if (chunkSize <= 0) throw ArgumentError('Chunk size must be positive');

    final result = <List<T>>[];
    for (int i = 0; i < list.length; i += chunkSize) {
      result.add(list.sublist(i, (i + chunkSize).clamp(0, list.length)));
    }

    return result;
  }

  /// Flatten nested lists
  static List<T> flatten<T>(List<List<T>> list) {
    return list.expand((sublist) => sublist).toList();
  }

  /// Zip two lists together
  static List<R> zip<T, U, R>(
      List<T> list1, List<U> list2, R Function(T, U) combine) {
    final length = list1.length < list2.length ? list1.length : list2.length;
    return List.generate(
        length, (index) => combine(list1[index], list2[index]));
  }

  /// Get random item from list
  static T? random<T>(List<T> list) {
    if (list.isEmpty) return null;
    return list[DateTime.now().millisecondsSinceEpoch % list.length];
  }

  /// Get random items from list
  static List<T> randomItems<T>(List<T> list, int count) {
    if (count <= 0) return [];
    if (count >= list.length) return List.from(list);

    final shuffled = List<T>.from(list);
    shuffled.shuffle();
    return shuffled.take(count).toList();
  }

  /// Shuffle list
  static List<T> shuffle<T>(List<T> list) {
    final shuffled = List<T>.from(list);
    shuffled.shuffle();
    return shuffled;
  }

  /// Reverse list
  static List<T> reverse<T>(List<T> list) {
    return list.reversed.toList();
  }

  /// Take first n items
  static List<T> take<T>(List<T> list, int count) {
    return list.take(count).toList();
  }

  /// Take last n items
  static List<T> takeLast<T>(List<T> list, int count) {
    if (count <= 0) return [];
    if (count >= list.length) return List.from(list);
    return list.sublist(list.length - count);
  }

  /// Skip first n items
  static List<T> skip<T>(List<T> list, int count) {
    return list.skip(count).toList();
  }

  /// Skip last n items
  static List<T> skipLast<T>(List<T> list, int count) {
    if (count <= 0) return List.from(list);
    if (count >= list.length) return [];
    return list.sublist(0, list.length - count);
  }

  /// Get items between start and end indices
  static List<T> slice<T>(List<T> list, int start, [int? end]) {
    final endIndex = end ?? list.length;
    return list.sublist(start, endIndex.clamp(0, list.length));
  }

  /// Insert item at specific index
  static List<T> insert<T>(List<T> list, int index, T item) {
    final result = List<T>.from(list);
    result.insert(index, item);
    return result;
  }

  /// Remove item at specific index
  static List<T> removeAt<T>(List<T> list, int index) {
    final result = List<T>.from(list);
    result.removeAt(index);
    return result;
  }

  /// Remove items matching condition
  static List<T> removeWhere<T>(List<T> list, bool Function(T item) condition) {
    final result = List<T>.from(list);
    result.removeWhere(condition);
    return result;
  }

  /// Replace item at specific index
  static List<T> replaceAt<T>(List<T> list, int index, T item) {
    final result = List<T>.from(list);
    result[index] = item;
    return result;
  }

  /// Swap items at two indices
  static List<T> swap<T>(List<T> list, int index1, int index2) {
    final result = List<T>.from(list);
    final temp = result[index1];
    result[index1] = result[index2];
    result[index2] = temp;
    return result;
  }

  /// Move item from one index to another
  static List<T> move<T>(List<T> list, int fromIndex, int toIndex) {
    final result = List<T>.from(list);
    final item = result.removeAt(fromIndex);
    result.insert(toIndex, item);
    return result;
  }

  /// Get unique items by comparing function
  static List<T> unique<T>(List<T> list, bool Function(T a, T b) equals) {
    final result = <T>[];

    for (final item in list) {
      if (!result.any((existing) => equals(existing, item))) {
        result.add(item);
      }
    }

    return result;
  }

  /// Partition list into two lists based on condition
  static List<List<T>> partition<T>(
      List<T> list, bool Function(T item) condition) {
    final trueList = <T>[];
    final falseList = <T>[];

    for (final item in list) {
      if (condition(item)) {
        trueList.add(item);
      } else {
        falseList.add(item);
      }
    }

    return [trueList, falseList];
  }

  /// Get items that appear in both lists
  static List<T> intersection<T>(List<T> list1, List<T> list2) {
    final set2 = list2.toSet();
    return list1.where((item) => set2.contains(item)).toList();
  }

  /// Get items that appear in either list
  static List<T> union<T>(List<T> list1, List<T> list2) {
    final result = <T>[];
    result.addAll(list1);
    result.addAll(list2);
    return distinct(result);
  }

  /// Get items that appear in first list but not in second
  static List<T> difference<T>(List<T> list1, List<T> list2) {
    final set2 = list2.toSet();
    return list1.where((item) => !set2.contains(item)).toList();
  }

  /// Check if lists have same elements (order doesn't matter)
  static bool hasSameElements<T>(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;

    final set1 = list1.toSet();
    final set2 = list2.toSet();

    return set1.length == set2.length &&
        set1.every((item) => set2.contains(item));
  }

  /// Get most frequent item
  static T? mostFrequent<T>(List<T> list) {
    if (list.isEmpty) return null;

    final frequency = <T, int>{};
    for (final item in list) {
      frequency[item] = (frequency[item] ?? 0) + 1;
    }

    return frequency.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Get items with their frequencies
  static Map<T, int> frequencies<T>(List<T> list) {
    final frequency = <T, int>{};
    for (final item in list) {
      frequency[item] = (frequency[item] ?? 0) + 1;
    }
    return frequency;
  }

  /// Check if list is sorted
  static bool isSorted<T extends Comparable<T>>(List<T> list,
      {bool ascending = true}) {
    for (int i = 1; i < list.length; i++) {
      final comparison = list[i - 1].compareTo(list[i]);
      if (ascending && comparison > 0) return false;
      if (!ascending && comparison < 0) return false;
    }
    return true;
  }

  /// Get indices of items matching condition
  static List<int> indicesWhere<T>(
      List<T> list, bool Function(T item) condition) {
    final indices = <int>[];
    for (int i = 0; i < list.length; i++) {
      if (condition(list[i])) {
        indices.add(i);
      }
    }
    return indices;
  }

  /// Get first index of item matching condition
  static int? indexWhere<T>(List<T> list, bool Function(T item) condition) {
    for (int i = 0; i < list.length; i++) {
      if (condition(list[i])) {
        return i;
      }
    }
    return null;
  }

  /// Get last index of item matching condition
  static int? lastIndexWhere<T>(List<T> list, bool Function(T item) condition) {
    for (int i = list.length - 1; i >= 0; i--) {
      if (condition(list[i])) {
        return i;
      }
    }
    return null;
  }
}
