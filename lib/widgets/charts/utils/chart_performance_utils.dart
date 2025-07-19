import 'dart:async';

import 'package:flutter/material.dart';

/// Performance optimization utilities cho chart system
/// Cung cấp các helper methods để tối ưu performance
class ChartPerformanceUtils {
  // Static cache for memoization
  static final Map<String, dynamic> _memoizationCache = {};

  /// Debounce function để tránh gọi function quá nhiều lần
  static Function debounce(Function func, Duration wait) {
    Timer? timer;
    return (List<dynamic> args) {
      timer?.cancel();
      timer = Timer(wait, () => func(args));
    };
  }

  /// Throttle function để giới hạn tần suất gọi function
  static Function throttle(Function func, Duration wait) {
    DateTime? lastCall;
    return (List<dynamic> args) {
      final now = DateTime.now();
      if (lastCall == null || now.difference(lastCall!) >= wait) {
        lastCall = now;
        func(args);
      }
    };
  }

  /// Memoization helper cho expensive computations
  static T memoize<T>(T Function() computation, {String? key}) {
    final cacheKey = key ?? computation.toString();

    if (_memoizationCache.containsKey(cacheKey)) {
      return _memoizationCache[cacheKey] as T;
    }

    final result = computation();
    _memoizationCache[cacheKey] = result;
    return result;
  }

  /// Clear memoization cache
  static void clearMemoizationCache() {
    _memoizationCache.clear();
  }

  /// Kiểm tra xem có nên rebuild widget hay không
  static bool shouldRebuild<T>(T oldValue, T newValue) {
    return oldValue != newValue;
  }

  /// Lazy loading helper cho large datasets
  static List<T> lazyLoad<T>(
    List<T> data, {
    int initialCount = 10,
    int incrementCount = 10,
  }) {
    return data.take(initialCount).toList();
  }

  /// Virtual scrolling helper cho large lists
  static List<T> getVisibleItems<T>(
    List<T> items,
    double scrollOffset,
    double itemHeight,
    double viewportHeight,
  ) {
    final startIndex = (scrollOffset / itemHeight).floor();
    final endIndex = ((scrollOffset + viewportHeight) / itemHeight).ceil();

    return items.sublist(
      startIndex.clamp(0, items.length),
      endIndex.clamp(0, items.length),
    );
  }

  /// Optimize chart data để giảm số lượng data points
  static List<Map<String, dynamic>> optimizeChartData(
    List<Map<String, dynamic>> data, {
    int maxPoints = 100,
    String valueKey = 'value',
    String labelKey = 'label',
  }) {
    if (data.length <= maxPoints) return data;

    final optimized = <Map<String, dynamic>>[];
    final step = data.length / maxPoints;

    for (int i = 0; i < maxPoints; i++) {
      final index = (i * step).floor();
      if (index < data.length) {
        optimized.add(data[index]);
      }
    }

    return optimized;
  }

  /// Batch update helper để tránh multiple rebuilds
  static void batchUpdate(VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      callback();
    });
  }

  /// Precompute expensive values
  static Map<String, double> precomputeChartValues(
    List<Map<String, dynamic>> data, {
    String valueKey = 'value',
  }) {
    final result = <String, double>{};

    double total = 0;
    double min = double.infinity;
    double max = double.negativeInfinity;

    for (final item in data) {
      final value = (item[valueKey] as num).toDouble();
      total += value;
      min = min < value ? min : value;
      max = max > value ? max : value;
    }

    result['total'] = total;
    result['min'] = min;
    result['max'] = max;
    result['average'] = total / data.length;

    return result;
  }

  /// Measure performance của function
  static Future<T> measurePerformance<T>(
    Future<T> Function() function, {
    String? label,
  }) async {
    final stopwatch = Stopwatch()..start();
    final result = await function();
    stopwatch.stop();

    debugPrint(
        'Performance [${label ?? 'Function'}]: ${stopwatch.elapsedMilliseconds}ms');
    return result;
  }

  /// Optimize image loading cho chart icons
  static Widget optimizeImage(
    String imagePath, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: (width ?? 100).toInt(),
      cacheHeight: (height ?? 100).toInt(),
    );
  }

  /// Prevent unnecessary rebuilds với RepaintBoundary
  static Widget withRepaintBoundary(Widget child) {
    return RepaintBoundary(child: child);
  }

  /// Optimize list rendering với ListView.builder
  static Widget optimizedListView<T>({
    required List<T> items,
    required Widget Function(BuildContext, T, int) itemBuilder,
    ScrollController? controller,
    bool shrinkWrap = false,
  }) {
    return ListView.builder(
      controller: controller,
      shrinkWrap: shrinkWrap,
      itemCount: items.length,
      itemBuilder: (context, index) {
        return withRepaintBoundary(
          itemBuilder(context, items[index], index),
        );
      },
    );
  }
}

/// Timed cache implementation
class TimedCache<T> {
  final Map<String, _CacheEntry<T>> _cache = {};
  final Duration ttl;

  TimedCache({this.ttl = const Duration(minutes: 5)});

  T? get(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (DateTime.now().difference(entry.timestamp) > ttl) {
      _cache.remove(key);
      return null;
    }

    return entry.value;
  }

  void set(String key, T value) {
    _cache[key] = _CacheEntry(value, DateTime.now());
  }

  void clear() {
    _cache.clear();
  }
}

class _CacheEntry<T> {
  final T value;
  final DateTime timestamp;

  _CacheEntry(this.value, this.timestamp);
}
