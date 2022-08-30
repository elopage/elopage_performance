import 'package:elopage_performance/src/controllers/performance_controller.dart';
import 'package:elopage_performance/src/models/statistics.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  int get currentMaxPeriods => maxPeriods + offset;

  List<FlSpot> get availableSpots {
    final entries = widget.controller.data.entries.toList();

    return entries.map(_spotBuilder).whereType<FlSpot>().toList();
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
          padding: const EdgeInsets.all(12),
          constraints: BoxConstraints(maxHeight: 400, maxWidth: maxPeriods * 50 + 100),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(6)),
          child: Column(
            children: [
              Expanded(
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxX: -offset.toDouble(),
                    minX: -(currentMaxPeriods - 1).toDouble(),
                    lineTouchData: LineTouchData(
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
                                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                              ),
                              const SizedBox(width: 32),
                              Text(
                                widget.title,
                                style: Theme.of(context).textTheme.headline6?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 32),
                              IconButton(
                                splashRadius: 1,
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
                            final periodInWeeks = widget.controller.configuration.dataGrouping;
                            final period = value.round().abs();
                            final prevStr = '${(period + 1) * periodInWeeks}${period == 0 ? 'w' : ''}';
                            final curStr = period == 0 ? 'now' : '${period * periodInWeeks}w';
                            return Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                '$prevStr-$curStr',
                                style: Theme.of(context).textTheme.caption?.copyWith(fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: buildCurrentViewSpots(),
                        preventCurveOverShooting: true,
                        color: Theme.of(context).primaryColor,
                        belowBarData: BarAreaData(show: true, color: Theme.of(context).primaryColor.withOpacity(0.2)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
