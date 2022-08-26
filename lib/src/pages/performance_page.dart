import 'package:atlassian_apis/jira_platform.dart';
import 'package:elopage_performance/src/components/user_group_badge.dart';
import 'package:elopage_performance/src/components/user_icon.dart';
import 'package:elopage_performance/src/components/value_card.dart';
import 'package:elopage_performance/src/controllers/performance_controller.dart';
import 'package:elopage_performance/src/models/statistics.dart';
import 'package:elopage_performance/src/models/statistics_configuration.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    controller = PerformanceController(widget.configuration, widget.users);
    controller.fetchPageData().then((_) {
      if (mounted) setState(() => isLoading = false);
    });
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
      body: AnimatedCrossFade(
        alignment: Alignment.center,
        duration: const Duration(milliseconds: 200),
        firstChild: const Center(child: CircularProgressIndicator()),
        crossFadeState: isLoading ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        secondChild: isLoading
            ? const SizedBox.shrink()
            : ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                itemCount: controller.statistics.length,
                itemBuilder: (c, i) => StatisticsSection(controller.statistics[i]),
                separatorBuilder: (c, i) => const Divider(thickness: 1.0, height: 52),
              ),
      ),
    );
  }
}

class StatisticsSection extends StatelessWidget {
  const StatisticsSection(final this.statistics, {Key? key}) : super(key: key);

  final Statistics statistics;

  TextStyle get titleStyle => GoogleFonts.lato(fontSize: 32, height: 1, fontWeight: FontWeight.bold);
  String? get _title {
    if (statistics is GeneralStatistics) {
      return null;
    } else if (statistics is TimeLoggingStatistics) {
      return 'Timeing';
    } else if (statistics is NumberFieldStatistics) {
      final numberField = statistics as NumberFieldStatistics;
      return '${numberField.field.name}';
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
      widgets.addAll([
        ValueCard(
          value: statistics.sum.toStringAsFixed(statistics.sum % 1 > 0.005 ? 2 : 0),
          title: 'Σ "${statistics.field.name}"',
        ),
        ValueCard(value: statistics.averageValuePerIssue.toStringAsFixed(2), title: 'Average'),
        ValueCard(value: '${statistics.issuesWithFieldCount}', title: 'Issues with field'),
      ]);
    }

    if (statistics.composed != null) widgets.addAll(_buildRepresentation(statistics.composed!));

    return widgets;
  }

  String _formatDuration(final Duration duration) => '${duration.inHours}h ${duration.inMinutes % 60}m';
}
