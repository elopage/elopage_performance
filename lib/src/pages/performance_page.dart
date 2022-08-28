import 'package:atlassian_apis/jira_platform.dart' hide Icon;
import 'package:elopage_performance/src/components/user_group_badge.dart';
import 'package:elopage_performance/src/components/user_icon.dart';
import 'package:elopage_performance/src/components/value_card.dart';
import 'package:elopage_performance/src/controllers/performance_controller.dart';
import 'package:elopage_performance/src/models/field_configuration.dart';
import 'package:elopage_performance/src/models/statistics.dart';
import 'package:elopage_performance/src/models/statistics_configuration.dart';
import 'package:elopage_performance/src/styles/animation_styles.dart';
import 'package:flutter/material.dart';
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

  Iterable<String> get userIds => widget.users.map((user) => user.accountId).whereType<String>();
  String get userIdsQuery => userIds.fold<String>('', (q, userId) => '$q$userId${userIds.last != userId ? ', ' : ''}');

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
                          itemBuilder: (c, i) => _StatisticsSection(snapshot.data![i]),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 100),
                          separatorBuilder: (c, i) => const Divider(thickness: 1.0, height: 52),
                        ),
                ),
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            child: Center(child: _PeriodSelector(controller: controller)),
          ),
        ],
      ),
    );
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
  final focus = FocusNode();
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
      onFocusChange: (value) => focus.requestFocus(),
      child: KeyboardListener(
        focusNode: focus,
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
      ),
    );
  }

  void _onKeyTap(final KeyEvent value) {
    switch (value.logicalKey.keyId) {
      case 0x100000303:
        return _openPrevPage();
      case 0x100000302:
        return _openNextPage();
    }
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
  const _StatisticsSection(final this.statistics, {Key? key}) : super(key: key);

  final Statistics statistics;

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
        ValueCard(value: '${statistics.issuesCount}', title: 'Issues'),
        ValueCard(value: statistics.issuesPerWorkingDay.toStringAsFixed(2), title: 'Issue / Day'),
        ValueCard(value: statistics.workingDaysPerIssue.toStringAsFixed(2), title: 'Days / Issue'),
      ]);
    } else if (statistics is TimeLoggingStatistics) {
      widgets.addAll([
        ValueCard(value: _formatDuration(statistics.totalLogged), title: 'Time logged'),
        ValueCard(value: _formatDuration(statistics.loggedTimePerIssue), title: 'Logged / Issue'),
        ValueCard(value: _formatDuration(statistics.loggedTimePerWorkingDay), title: 'Logged / Day'),
      ]);
    } else if (statistics is NumberFieldStatistics) {
      final sumValue = statistics.configuration.representation == NumberFieldRepresentation.time
          ? _formatDuration(Duration(seconds: statistics.sum.round()))
          : statistics.sum.toStringAsFixed(statistics.sum % 1 > 0.005 ? 2 : 0);
      final averageValue = statistics.configuration.representation == NumberFieldRepresentation.time
          ? _formatDuration(Duration(seconds: statistics.averageValuePerIssue.round()))
          : statistics.averageValuePerIssue.toStringAsFixed(2);

      widgets.addAll([
        ValueCard(value: sumValue, title: 'Σ "${statistics.configuration.field.name}"'),
        ValueCard(value: averageValue, title: 'Average'),
        ValueCard(value: '${statistics.issuesWithFieldCount}', title: 'Issues with field'),
      ]);
    }

    if (statistics.composed != null) widgets.addAll(_buildRepresentation(statistics.composed!));

    return widgets;
  }

  String _formatDuration(final Duration duration) {
    return '${duration.inHours}h ${duration.inMinutes % 60}m';
  }
}
