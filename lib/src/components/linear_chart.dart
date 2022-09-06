import 'package:elopage_performance/src/controllers/performance_controller.dart';
import 'package:elopage_performance/src/models/statistics.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

typedef LinearChartBuilder = void Function<T extends Statistics>({
  required String title,
  required LinearChartYValueBuilder valueBuilder,
  required ValueRepresentationBuilder representationBuilder,
});

typedef LinearChartYValueBuilder = double? Function(PageStatisticsData statistics);
typedef ValueRepresentationBuilder = String Function(double value);

String buildRepresentation(final double value) => value.toStringAsFixed(2);

class Chart<T extends Statistics> extends StatefulWidget {
  const Chart({
    Key? key,
    required this.title,
    required this.controller,
    required this.yValueBuilder,
    this.representationBuilder = buildRepresentation,
  }) : super(key: key);

  final String title;
  final PerformanceController controller;
  final LinearChartYValueBuilder yValueBuilder;
  final ValueRepresentationBuilder representationBuilder;

  @override
  State<Chart> createState() => _ChartState<T>();
}

class _ChartState<T extends Statistics> extends State<Chart> {
  int offset = 0;
  int maxPeriods = 3;
  static const pixelsPerPeriod = 50;
  final dateFormat = DateFormat.yMd();

  int get currentMaxPeriods => maxPeriods + offset;

  List<FlSpot> get availableSpots {
    final entries = widget.controller.data.entries.toList();

    return entries.map(_spotBuilder).whereType<FlSpot>().toList();
  }

  bool get isLoading {
    for (var i = offset; i < currentMaxPeriods; i++) {
      if (widget.controller.retrieveStatistics(i).isComputing) return true;
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    retrieveSpots();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newMaxPeriods = (MediaQuery.of(context).size.width - 150) ~/ pixelsPerPeriod;
    if (newMaxPeriods == maxPeriods) return;
    maxPeriods = newMaxPeriods;
    retrieveSpots();
  }

  Future<void> retrieveSpots() async {
    for (var i = offset; i < currentMaxPeriods; i++) {
      buildPointForPeriod(i);
    }
  }

  Future<void> buildPointForPeriod(final int period) async {
    final data = widget.controller.retrieveStatistics(period);
    if (data.statistics != null) return;
    await data.statisticsComputation;
    if (mounted) setState(() {});
  }

  List<FlSpot> buildCurrentViewSpots() {
    final spots = availableSpots;
    if (offset >= spots.length) return [];
    return spots.getRange(offset, currentMaxPeriods > spots.length ? spots.length : currentMaxPeriods).toList();
  }

  void addOffset() => setState(() {
        offset++;
        retrieveSpots();
      });

  void reduceOffset() => setState(() => offset--);

  FlSpot? _spotBuilder(final MapEntry<int, PageStatisticsData> entry) {
    final yValue = widget.yValueBuilder(entry.value);
    if (yValue == null) return null;
    return FlSpot(-entry.key.toDouble(), yValue);
  }

  KeyEventResult _onKeyTap(final FocusNode node, final KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.skipRemainingHandlers;
    switch (event.logicalKey.keyId) {
      case 100:
      case 0x100000303:
        if (offset > 0) reduceOffset();
        break;
      case 97:
      case 0x100000302:
        addOffset();
        break;
    }

    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _onKeyTap,
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(32),
          constraints: BoxConstraints(maxHeight: 400, maxWidth: maxPeriods * 50 + 100),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(6)),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxX: -offset.toDouble(),
                      minX: -(currentMaxPeriods - 1).toDouble(),
                      lineTouchData: LineTouchData(
                        getTouchedSpotIndicator: (barData, spotIndexes) {
                          return spotIndexes
                              .map(
                                (i) => TouchedSpotIndicatorData(
                                  FlLine(strokeWidth: 2, dashArray: [5, 5, 5], color: Theme.of(context).canvasColor),
                                  FlDotData(
                                    getDotPainter: (s, x, b, i) => FlDotCirclePainter(
                                      radius: 5,
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              )
                              .toList();
                        },
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: Theme.of(context).hoverColor,
                          maxContentWidth: 100,
                          getTooltipItems: (touchedSpots) {
                            final theme = Theme.of(context);
                            return touchedSpots
                                .map<LineTooltipItem>(
                                  (s) => LineTooltipItem(
                                    widget.representationBuilder(s.y),
                                    theme.textTheme.titleMedium!.copyWith(
                                      color: theme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                                .toList();
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: AxisTitles(
                          axisNameSize: 40,
                          sideTitles: SideTitles(showTitles: false),
                          axisNameWidget: Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              textBaseline: TextBaseline.alphabetic,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  splashRadius: 1,
                                  onPressed: addOffset,
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.chevron_left_rounded, size: 20),
                                ),
                                const SizedBox(width: 32),
                                Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(width: 32),
                                IconButton(
                                  splashRadius: 1,
                                  padding: EdgeInsets.zero,
                                  onPressed: offset <= 0 ? null : reduceOffset,
                                  icon: const Icon(Icons.chevron_right_rounded, size: 20),
                                ),
                              ],
                            ),
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 70,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  widget.representationBuilder(value),
                                  textAlign: TextAlign.right,
                                  style: Theme.of(context).textTheme.caption?.copyWith(fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 70,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  widget.representationBuilder(value),
                                  textAlign: TextAlign.left,
                                  style: Theme.of(context).textTheme.caption?.copyWith(fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          axisNameWidget: Text('Periods in weeks with offset: ${offset}w'),
                          sideTitles: SideTitles(
                            interval: 1,
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final data = widget.controller.data[value.abs().toInt()];

                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Column(
                                  children: [
                                    Text(
                                      dateFormat.format(data!.period.startDate),
                                      style: Theme.of(context).textTheme.caption?.copyWith(fontSize: 8),
                                    ),
                                    const SizedBox(width: 32, height: 2, child: Divider()),
                                    Text(
                                      value == 0 ? 'now' : dateFormat.format(data.period.endDate),
                                      style: Theme.of(context).textTheme.caption?.copyWith(fontSize: 8),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          barWidth: 1.5,
                          spots: buildCurrentViewSpots(),
                          preventCurveOverShooting: true,
                          color: Theme.of(context).primaryColor,
                          belowBarData: BarAreaData(show: true, color: Theme.of(context).primaryColor.withOpacity(0.2)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isLoading) const LinearProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}