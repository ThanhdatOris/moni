import 'package:flutter/material.dart';

import '../../../constants/enums.dart';
import '../models/chart_config_models.dart';
import '../models/chart_data_models.dart';
import 'chart_theme.dart';

/// Abstract base class for all chart widgets
abstract class ChartBase extends StatefulWidget {
  final CompleteChartConfig config;
  final VoidCallback? onTap;
  final Function(ChartDataPoint)? onDataPointTap;
  final Function(ChartInsight)? onInsightTap;

  const ChartBase({
    super.key,
    required this.config,
    this.onTap,
    this.onDataPointTap,
    this.onInsightTap,
  });

  @override
  State<ChartBase> createState();
}

/// Base state class for chart widgets
abstract class ChartBaseState<T extends ChartBase> extends State<T>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _loadData();
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_shouldReloadData(oldWidget)) {
      _loadData();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Initialize animation controller
  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: widget.config.chart.animationDuration,
      vsync: this,
    );

    switch (widget.config.chart.animationType) {
      case ChartAnimationType.fade:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
        );
        break;
      case ChartAnimationType.slide:
        _animation = Tween<double>(begin: -1.0, end: 0.0).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
        break;
      case ChartAnimationType.scale:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
              parent: _animationController, curve: Curves.elasticOut),
        );
        break;
      case ChartAnimationType.bounce:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
              parent: _animationController, curve: Curves.bounceOut),
        );
        break;
      case ChartAnimationType.elastic:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
              parent: _animationController, curve: Curves.elasticOut),
        );
        break;
      case ChartAnimationType.none:
        _animation =
            Tween<double>(begin: 1.0, end: 1.0).animate(_animationController);
        break;
    }

    _animationController.forward();
  }

  /// Check if data should be reloaded
  bool _shouldReloadData(T oldWidget) {
    return widget.config.filter != oldWidget.config.filter ||
        widget.config.chart.timePeriod != oldWidget.config.chart.timePeriod;
  }

  /// Load chart data
  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await loadChartData();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  /// Abstract method to load chart-specific data
  Future<void> loadChartData();

  /// Abstract method to build the chart content
  Widget buildChart(BuildContext context, ChartTheme theme);

  /// Build the main chart widget
  @override
  Widget build(BuildContext context) {
    final theme = ChartThemeProvider.of(context);

    return Container(
      padding: widget.config.chart.padding,
      decoration: BoxDecoration(
        color: widget.config.style.backgroundColor,
        borderRadius: widget.config.style.borderRadius,
        boxShadow: widget.config.style.shadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.config.chart.title.isNotEmpty) _buildTitle(theme),
          if (widget.config.chart.subtitle?.isNotEmpty == true)
            _buildSubtitle(theme),
          const SizedBox(height: 16),
          Flexible(
            child: _buildContent(theme),
          ),
          if (widget.config.legend.show) _buildLegend(theme),
        ],
      ),
    );
  }

  /// Build chart title
  Widget _buildTitle(ChartTheme theme) {
    return Text(
      widget.config.chart.title,
      style: theme.textTheme.titleLarge?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  /// Build chart subtitle
  Widget _buildSubtitle(ChartTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        widget.config.chart.subtitle!,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  /// Build chart content with loading and error states
  Widget _buildContent(ChartTheme theme) {
    if (_isLoading) {
      return _buildLoadingState(theme);
    }

    if (_error != null) {
      return _buildErrorState(theme);
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        switch (widget.config.chart.animationType) {
          case ChartAnimationType.fade:
            return Opacity(
              opacity: _animation.value,
              child: buildChart(context, theme),
            );
          case ChartAnimationType.slide:
            return Transform.translate(
              offset: Offset(
                  _animation.value * MediaQuery.of(context).size.width, 0),
              child: buildChart(context, theme),
            );
          case ChartAnimationType.scale:
            return Transform.scale(
              scale: _animation.value,
              child: buildChart(context, theme),
            );
          default:
            return buildChart(context, theme);
        }
      },
    );
  }

  /// Build loading state
  Widget _buildLoadingState(ChartTheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading chart data...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(ChartTheme theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading chart',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.errorColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error!.length > 100
                  ? '${_error!.substring(0, 100)}...'
                  : _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build legend (can be overridden by subclasses)
  Widget _buildLegend(ChartTheme theme) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Text(
        'Legend placeholder',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  /// Utility method to handle data point taps
  void handleDataPointTap(ChartDataPoint dataPoint) {
    if (widget.onDataPointTap != null) {
      widget.onDataPointTap!(dataPoint);
    }
  }

  /// Utility method to handle insight taps
  void handleInsightTap(ChartInsight insight) {
    if (widget.onInsightTap != null) {
      widget.onInsightTap!(insight);
    }
  }

  /// Utility method to refresh chart data
  Future<void> refresh() async {
    await _loadData();
  }

  /// Utility method to animate chart
  void animateChart() {
    _animationController.reset();
    _animationController.forward();
  }

  /// Check if chart is currently loading
  bool get isLoading => _isLoading;

  /// Check if chart has error
  bool get hasError => _error != null;

  /// Get current error message
  String? get error => _error;

  /// Get animation controller for custom animations
  AnimationController get animationController => _animationController;

  /// Get current animation value
  double get animationValue => _animation.value;
}

/// Mixin for charts that support drill-down functionality
mixin DrillDownMixin<T extends ChartBase> on ChartBaseState<T> {
  List<ChartDataPoint> _drillDownStack = [];

  /// Navigate to drill-down level
  void drillDown(ChartDataPoint dataPoint) {
    _drillDownStack.add(dataPoint);
    loadDrillDownData(dataPoint);
  }

  /// Navigate back from drill-down
  void drillUp() {
    if (_drillDownStack.isNotEmpty) {
      _drillDownStack.removeLast();
      if (_drillDownStack.isEmpty) {
        loadChartData();
      } else {
        loadDrillDownData(_drillDownStack.last);
      }
    }
  }

  /// Check if currently in drill-down mode
  bool get isDrillDown => _drillDownStack.isNotEmpty;

  /// Get current drill-down level
  int get drillDownLevel => _drillDownStack.length;

  /// Get current drill-down data point
  ChartDataPoint? get currentDrillDownPoint =>
      _drillDownStack.isNotEmpty ? _drillDownStack.last : null;

  /// Abstract method to load drill-down data
  Future<void> loadDrillDownData(ChartDataPoint dataPoint);
}

/// Mixin for charts that support data export
mixin ExportMixin<T extends ChartBase> on ChartBaseState<T> {
  /// Export chart as image
  Future<void> exportAsImage() async {
    // Implementation would capture the widget as an image
    // Using packages like screenshot or similar
  }

  /// Export chart data as CSV
  Future<void> exportAsCSV() async {
    // Implementation would export the chart data as CSV
  }

  /// Export chart as PDF
  Future<void> exportAsPDF() async {
    // Implementation would generate a PDF with the chart
  }
}

/// Mixin for charts that support real-time updates
mixin RealtimeMixin<T extends ChartBase> on ChartBaseState<T> {
  late Stream<dynamic> _dataStream;

  /// Initialize real-time data stream
  void initializeRealtimeUpdates(Stream<dynamic> dataStream) {
    _dataStream = dataStream;
    _dataStream.listen((_) {
      if (mounted) {
        loadChartData();
      }
    });
  }

  /// Stop real-time updates
  void stopRealtimeUpdates() {
    // Stream subscription would be cancelled here
  }
}
