import 'package:atlassian_apis/jira_platform.dart' hide Icon;
import 'package:collection/collection.dart';
import 'package:elopage_performance/src/components/linear_chart.dart';
import 'package:elopage_performance/src/components/user_group_badge.dart';
import 'package:elopage_performance/src/components/user_icon.dart';
import 'package:elopage_performance/src/components/value_card.dart';
import 'package:elopage_performance/src/controllers/performance_controller.dart';
import 'package:elopage_performance/src/models/field_configuration.dart';
import 'package:elopage_performance/src/models/statistics.dart';
import 'package:elopage_performance/src/models/statistics_configuration.dart';
import 'package:elopage_performance/src/styles/animation_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class PerformancePage extends StatefulWidget {
  const PerformancePage({
    Key? key,
    required this.users,
    required this.title,
    required this.configuration,
  })  : assert(users.length > 0, 'PerformancePage must accept at least one user'),
        super(key: key);

  final String title;
  final List<UserDetails> users;
  final StatisticsConfiguration configuration;

  @override
  State<PerformancePage> createState() => _PerformancePageState();
}

class _PerformancePageState extends State<PerformancePage> {
  late final PerformanceController controller;

  Iterable<String> get userIds => widget.users.map((user) => user.accountId).whereType<String>();
  String get userIdsQuery => userIds.fold<String>('', (q, userId) => '$q$userId${userIds.last != userId ? ', ' : ''}');

  @override
  void initState() {
    super.initState();
    controller = PerformanceController(widget.configuration, widget.users);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Container(
            alignment: Alignment.center,
            margin: const EdgeInsets.only(right: 16),
            child: widget.users.length == 1
                ? UserIcon(avatar: widget.users.first.avatarUrls?.$48X48, size: 40, borderWidth: 2)
                : UserGroupBadge(users: widget.users, circleSize: 40),
          )
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            reverse: true,
            controller: controller,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final data = controller.retrieveStatistics(index);
              return FutureBuilder<List<Statistics>>(
                initialData: data.statistics,
                future: data.statisticsComputation,
                builder: (context, snapshot) => AnimatedCrossFade(
                  alignment: Alignment.center,
                  duration: AnimationStyles.defaultDuration,
                  firstChild: const Center(child: CircularProgressIndicator()),
                  crossFadeState: !snapshot.hasData ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                  secondChild: !snapshot.hasData
                      ? const SizedBox.shrink()
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: snapshot.data!.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 100),
                          separatorBuilder: (c, i) => const Divider(thickness: 1.0, height: 52),
                          itemBuilder: (c, i) => _StatisticsSection(snapshot.data![i], openLinearChart: _openChart),
                        ),
                ),
              );
            },
          ),
          Positioned(left: 0, right: 0, child: Center(child: _PeriodSelector(controller: controller))),
        ],
      ),
    );
  }

  void _openChart<T extends Statistics>({
    required final String title,
    required final LinearChartYValueBuilder valueBuilder,
    required final ValueRepresentationBuilder representationBuilder,
  }) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => Center(
          child: Chart<T>(
            title: title,
            controller: controller,
            yValueBuilder: valueBuilder,
            representationBuilder: representationBuilder,
          ),
        ),
      );
    }
  }
}

class _PeriodSelector extends StatefulWidget {
  const _PeriodSelector({Key? key, required this.controller}) : super(key: key);

  final PerformanceController controller;

  @override
  State<_PeriodSelector> createState() => _PeriodSelectorState();
}

class _PeriodSelectorState extends State<_PeriodSelector> {
  final format = DateFormat.yMMMMd();
  int page = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(didChangePage);
  }

  @override
  void dispose() {
    widget.controller.removeListener(didChangePage);
    super.dispose();
  }

  void didChangePage() {
    final newPage = widget.controller.page?.round();
    if (newPage != null && newPage != page) {
      page = newPage;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final statistics = widget.controller.retrieveStatistics(page);
    return Focus(
      autofocus: true,
      onKeyEvent: _onKeyTap,
      child: Container(
        height: 50,
        constraints: const BoxConstraints(minWidth: 450),
        margin: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(offset: Offset(0, 2), blurRadius: 2, color: Colors.black26)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(splashRadius: 1, onPressed: _openNextPage, icon: const Icon(Icons.chevron_left_rounded)),
            Text(
              '${format.format(statistics.period.startDate)} - ${format.format(statistics.period.endDate)}',
              style: Theme.of(context).textTheme.headline6?.copyWith(fontWeight: FontWeight.bold),
            ),
            IconButton(splashRadius: 1, onPressed: _openPrevPage, icon: const Icon(Icons.chevron_right_rounded)),
          ],
        ),
      ),
    );
  }

  KeyEventResult _onKeyTap(final FocusNode node, final KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.skipRemainingHandlers;
    switch (event.logicalKey.keyId) {
      case 100:
      case 0x100000303:
        _openPrevPage();
        break;
      case 97:
      case 0x100000302:
        _openNextPage();
        break;
    }

    return KeyEventResult.handled;
  }

  void _openPrevPage() => widget.controller.previousPage(
        duration: AnimationStyles.defaultDuration,
        curve: Curves.easeInOut,
      );

  void _openNextPage() => widget.controller.nextPage(
        duration: AnimationStyles.defaultDuration,
        curve: Curves.easeInOut,
      );
}

class _StatisticsSection extends StatelessWidget {
  const _StatisticsSection(final this.statistics, {Key? key, required this.openLinearChart}) : super(key: key);

  final Statistics statistics;
  final LinearChartBuilder openLinearChart;

  TextStyle get titleStyle => GoogleFonts.lato(fontSize: 32, height: 1, fontWeight: FontWeight.bold);
  String? get _title {
    if (statistics is GeneralStatistics) {
      return null;
    } else if (statistics is TimeLoggingStatistics) {
      return 'Logging';
    } else if (statistics is NumberFieldStatistics) {
      final numberField = statistics as NumberFieldStatistics;
      return '${numberField.configuration.field.name}';
    }

    assert(false, 'Check why app entered this point');
    return 'UNKNOWN';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_title != null) Text(_title!, style: titleStyle, textAlign: TextAlign.start),
        if (_title != null) const SizedBox(height: 32),
        Wrap(spacing: 8, runSpacing: 8, children: _buildRepresentation(statistics)),
      ],
    );
  }

  List<Widget> _buildRepresentation(final Statistics statistics) {
    final widgets = <Widget>[];
    if (statistics is GeneralStatistics) {
      widgets.addAll([
        ValueCard(
          title: 'Issues',
          value: '${statistics.issuesCount}',
          onTap: () => openLinearChart<GeneralStatistics>(
            title: 'Issues',
            representationBuilder: buildRepresentation,
            valueBuilder: (pageStatistics) {
              final statistics = _retrieveStatistics<GeneralStatistics>(pageStatistics);
              return statistics?.issuesCount.toDouble();
            },
          ),
        ),
        ValueCard(
          title: 'Issue / Day',
          value: statistics.issuesPerWorkingDay.toStringAsFixed(2),
          onTap: () => openLinearChart<GeneralStatistics>(
            title: 'Issue / Day',
            representationBuilder: buildRepresentation,
            valueBuilder: (pageStatistics) {
              final statistics = _retrieveStatistics<GeneralStatistics>(pageStatistics);
              return statistics?.issuesPerWorkingDay.toDouble();
            },
          ),
        ),
        ValueCard(
          title: 'Days / Issue',
          value: statistics.workingDaysPerIssue.toStringAsFixed(2),
          onTap: () => openLinearChart<GeneralStatistics>(
            title: 'Days / Issue',
            representationBuilder: buildRepresentation,
            valueBuilder: (pageStatistics) {
              final statistics = _retrieveStatistics<GeneralStatistics>(pageStatistics);
              return statistics?.workingDaysPerIssue.toDouble();
            },
          ),
        ),
      ]);
    } else if (statistics is TimeLoggingStatistics) {
      widgets.addAll([
        ValueCard(
          title: 'Time logged',
          value: _formatDuration(statistics.totalLogged),
          onTap: () => openLinearChart<TimeLoggingStatistics>(
            title: 'Time logged',
            representationBuilder: _formatDuration,
            valueBuilder: (pageStatistics) {
              final statistics = _retrieveStatistics<TimeLoggingStatistics>(pageStatistics);
              return statistics?.totalLogged.toDouble();
            },
          ),
        ),
        ValueCard(
          title: 'Logged / Issue',
          value: _formatDuration(statistics.loggedTimePerIssue),
          onTap: () => openLinearChart<TimeLoggingStatistics>(
            title: 'Logged / Issue',
            representationBuilder: _formatDuration,
            valueBuilder: (pageStatistics) {
              final statistics = _retrieveStatistics<TimeLoggingStatistics>(pageStatistics);
              return statistics?.loggedTimePerIssue.toDouble();
            },
          ),
        ),
        ValueCard(
          title: 'Logged / Day',
          value: _formatDuration(statistics.loggedTimePerWorkingDay),
          onTap: () => openLinearChart<TimeLoggingStatistics>(
            title: 'Logged / Day',
            representationBuilder: _formatDuration,
            valueBuilder: (pageStatistics) {
              final statistics = _retrieveStatistics<TimeLoggingStatistics>(pageStatistics);
              return statistics?.loggedTimePerWorkingDay.toDouble();
            },
          ),
        ),
      ]);
    } else if (statistics is NumberFieldStatistics) {
      final fieldId = statistics.configuration.field.id;
      final isTimeRepresentation = statistics.configuration.representation == NumberFieldRepresentation.time;
      final sumValue = isTimeRepresentation
          ? _formatDuration(statistics.sum)
          : statistics.sum.toStringAsFixed(statistics.sum % 1 > 0.005 ? 2 : 0);
      final averageValue = isTimeRepresentation
          ? _formatDuration(statistics.averageValuePerIssue)
          : statistics.averageValuePerIssue.toStringAsFixed(2);

      widgets.addAll([
        ValueCard(
          value: sumValue,
          title: 'Σ "${statistics.configuration.field.name}"',
          onTap: () => openLinearChart<NumberFieldStatistics>(
            title: 'Σ "${statistics.configuration.field.name}"',
            representationBuilder: isTimeRepresentation ? _formatDuration : buildRepresentation,
            valueBuilder: (pageStatistics) {
              final s = _retrieveFieldStatistics<NumberFieldStatistics>(pageStatistics, fieldId);
              return s?.sum;
            },
          ),
        ),
        ValueCard(
          title: 'Average',
          value: averageValue,
          onTap: () => openLinearChart<NumberFieldStatistics>(
            title: 'Average',
            representationBuilder: isTimeRepresentation ? _formatDuration : buildRepresentation,
            valueBuilder: (pageStatistics) {
              final s = _retrieveFieldStatistics<NumberFieldStatistics>(pageStatistics, fieldId);
              return s?.averageValuePerIssue;
            },
          ),
        ),
        ValueCard(
          title: 'Issues with field',
          value: '${statistics.issuesWithFieldCount}',
          onTap: () => openLinearChart<NumberFieldStatistics>(
            title: 'Issues with field',
            representationBuilder: buildRepresentation,
            valueBuilder: (pageStatistics) {
              final s = _retrieveFieldStatistics<NumberFieldStatistics>(pageStatistics, fieldId);
              return s?.issuesWithFieldCount.toDouble();
            },
          ),
        ),
      ]);
    }

    if (statistics.composed != null) widgets.addAll(_buildRepresentation(statistics.composed!));

    return widgets;
  }

  String _formatDuration(final num durationInMiliseconds) {
    final duration = Duration(milliseconds: durationInMiliseconds.toInt());
    return '${duration.inHours}h ${duration.inMinutes % 60}m';
  }

  List<Statistics> _getComposed(final Statistics statistics) {
    if (statistics.composed == null) return [];
    return [statistics.composed!, ..._getComposed(statistics.composed!)];
  }

  T? _retrieveStatistics<T extends Statistics>(final PageStatisticsData data) {
    final pageStatistics = [...?data.statistics];
    for (final s in data.statistics ?? []) {
      pageStatistics.addAll(_getComposed(s));
    }

    final statistics = pageStatistics.whereType<T>();
    if (statistics.isEmpty) return null;
    return statistics.first;
  }

  T? _retrieveFieldStatistics<T extends FieldStatistics>(final PageStatisticsData data, final String? fieldId) {
    final pageStatistics = [...?data.statistics];
    for (final s in data.statistics ?? []) {
      pageStatistics.addAll(_getComposed(s));
    }

    final statistics = pageStatistics.whereType<T>();
    if (statistics.isEmpty) return null;

    return statistics.firstWhereOrNull((fieldStatistics) => fieldStatistics.configuration.field.id == fieldId);
  }
}
