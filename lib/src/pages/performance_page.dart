import 'package:atlassian_apis/jira_platform.dart';
import 'package:elopage_performance/src/components/user_group_badge.dart';
import 'package:elopage_performance/src/components/user_icon.dart';
import 'package:elopage_performance/src/jira/jira.dart';
import 'package:elopage_performance/src/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatisticsData {
  const StatisticsData({
    this.qaCount,
    this.reviewCount,
    this.issuesCount = 0,
    this.isEmpty = false,
    this.stepInWeeks = 15,
    this.testedIssuesCount = 0,
    this.reviewedIssuesCount = 0,
    this.timeSpent = Duration.zero,
  });

  const StatisticsData.empty({
    this.qaCount,
    this.reviewCount,
    this.isEmpty = true,
    this.issuesCount = 0,
    this.stepInWeeks = 15,
    this.testedIssuesCount = 0,
    this.reviewedIssuesCount = 0,
    this.timeSpent = Duration.zero,
  });

  static const workingDaysPerWeek = 5;

  final int stepInWeeks;
  final bool isEmpty;

  // Custom data
  final double? qaCount;
  final double? reviewCount;

  // Required data
  final int issuesCount;
  final int testedIssuesCount;
  final int reviewedIssuesCount;
  final Duration timeSpent;

  bool get hasQACount => qaCount != null;
  bool get hasReviewCount => reviewCount != null;

  int get workingDaysForPeriod => stepInWeeks * workingDaysPerWeek;
  double get issuesPerDay => issuesCount / workingDaysForPeriod;
  double get workingDaysPerIssue => issuesCount == 0 ? double.nan : workingDaysForPeriod / issuesCount;
  Duration get timeLoggedPerWorkingDay => Duration(milliseconds: timeSpent.inMilliseconds ~/ workingDaysForPeriod);
  Duration get timeLoggedPerIssue =>
      issuesCount == 0 ? Duration.zero : Duration(milliseconds: timeSpent.inMilliseconds ~/ issuesCount);

  StatisticsData copyWith({
    final double? qaCount,
    final int? issuesCount,
    final int? testedIssuesCount,
    final int? reviewedIssuesCount,
    final double? reviewCount,
    final Duration? timeSpent,
  }) =>
      StatisticsData(
        reviewedIssuesCount: reviewedIssuesCount ?? this.reviewedIssuesCount,
        testedIssuesCount: testedIssuesCount ?? this.testedIssuesCount,
        issuesCount: issuesCount ?? this.issuesCount,
        reviewCount: reviewCount ?? this.reviewCount,
        timeSpent: timeSpent ?? this.timeSpent,
        qaCount: qaCount ?? this.qaCount,
      );
}

extension on bool {
  int get asInt => this ? 1 : 0;
}

class PerformancePage extends StatefulWidget {
  const PerformancePage({Key? key, required this.users, required this.title})
      : assert(users.length > 0, 'PerformancePage must accept at least one user'),
        super(key: key);

  final String title;
  final List<UserDetails> users;

  @override
  State<PerformancePage> createState() => _PerformancePageState();
}

class _PerformancePageState extends State<PerformancePage> {
  static const qaCountField = 'customfield_10897';
  static const reviewCountField = 'customfield_10896';

  // Can be dynamic later on
  static const int stepInWeeks = 15;

  StatisticsData data = const StatisticsData.empty(stepInWeeks: stepInWeeks);

  TextStyle get titleStyle => GoogleFonts.lato(fontSize: 52, height: 1.28, fontWeight: FontWeight.bold);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Iterable<String> get userIds => widget.users.map((user) => user.accountId).whereType<String>();
  String get userIdsQuery {
    String query = '';
    for (final userId in userIds) {
      query += userId;
      if (userIds.last != userId) query += ', ';
    }
    return query;
  }

  Future<void> _init() async {
    final jira = serviceLocator<Jira>();
    final now = DateTime.now();
    final endDate = now.subtract(
      Duration(
        hours: now.hour,
        minutes: now.minute,
        seconds: now.second,
        milliseconds: now.millisecond,
        microseconds: now.microsecond,
      ),
    );
    final startDate = endDate.subtract(const Duration(days: stepInWeeks * 7));
    final issuesResult = await jira.issueSearch.searchForIssuesUsingJql(
      maxResults: 1000,
      jql: 'worklogAuthor in ($userIdsQuery) AND '
          'worklogDate >= startOfDay(-${stepInWeeks}w) AND worklogDate <= startOfDay(-0d) '
          'order by created DESC',
    );

    final issues = issuesResult.issues;

    final hasQACount = issues.any((i) => i.fields?[qaCountField] != null);
    final hasReviewCount = issues.any((i) => i.fields?[reviewCountField] != null);

    data = data.copyWith(
      issuesCount: issues.length,
      qaCount: hasQACount ? 0 : null,
      reviewCount: hasReviewCount ? 0 : null,
    );

    if (mounted) setState(() {});

    for (final issue in issues) {
      final fields = issue.fields ?? {};

      if (hasQACount) {
        final issueQACount = fields[qaCountField] as double? ?? 0.0;
        final totalQACount = (data.qaCount ?? 0) + issueQACount;
        final testedIssuesCount = data.testedIssuesCount + (issueQACount > 0).asInt;
        data = data.copyWith(qaCount: totalQACount, testedIssuesCount: testedIssuesCount);
      }
      if (hasReviewCount) {
        final issueReviewCount = fields[reviewCountField] as double? ?? 0.0;
        final totalReviewCount = (data.reviewCount ?? 0) + issueReviewCount;
        final reviewedIssuesCount = data.reviewedIssuesCount + (issueReviewCount > 0).asInt;
        data = data.copyWith(reviewCount: totalReviewCount, reviewedIssuesCount: reviewedIssuesCount);
      }
    }

    if (mounted) setState(() {});

    Future.wait(
      List.generate(issues.length, (i) => calculateTimeSpent(issues[i].id, jira, startDate, endDate)),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> calculateTimeSpent(
    final String? id,
    final Jira jira,
    final DateTime startDate,
    final DateTime endDate,
  ) async {
    if (id == null) return;
    final worklogsResult = await jira.issueWorklogs.getIssueWorklog(
      startedAfter: startDate.millisecondsSinceEpoch,
      startedBefore: endDate.millisecondsSinceEpoch,
      maxResults: 1000,
      issueIdOrKey: id,
    );
    for (final worklog in worklogsResult.worklogs) {
      if (!userIds.contains(worklog.author?.accountId)) continue;
      data = data.copyWith(timeSpent: data.timeSpent + Duration(seconds: worklog.timeSpentSeconds ?? 0));
      if (mounted) setState(() {});
    }
  }

  String _formatDuration(final Duration duration) => '${duration.inHours}h ${duration.inMinutes % 60}m';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
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
        crossFadeState: data.isEmpty ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        secondChild: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            Center(child: Text('General', style: titleStyle, textAlign: TextAlign.start)),
            const SizedBox(height: 32),
            Center(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ValueCard(value: '${data.issuesCount}', title: 'Issues'),
                  if (data.hasQACount) ValueCard(value: '${data.testedIssuesCount}', title: 'Issues tested'),
                  if (data.hasQACount) ValueCard(value: '${data.qaCount!.round()}', title: 'QA checks'),
                  if (data.hasReviewCount) ValueCard(value: '${data.reviewedIssuesCount}', title: 'Issues reviewed'),
                  if (data.hasReviewCount) ValueCard(value: '${data.reviewCount!.round()}', title: 'Reviews number'),
                  ValueCard(value: _formatDuration(data.timeSpent), title: 'Time logged'),
                ],
              ),
            ),
            const Divider(thickness: 1.0, height: 52, indent: 32, endIndent: 32),
            Center(child: Text('Timeing', style: titleStyle)),
            const SizedBox(height: 32),
            Center(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ValueCard(value: data.issuesPerDay.toStringAsFixed(2), title: 'Issue / Day'),
                  ValueCard(value: data.workingDaysPerIssue.toStringAsFixed(2), title: 'Days / Issue'),
                  ValueCard(value: _formatDuration(data.timeLoggedPerIssue), title: 'Time / Issue'),
                  ValueCard(value: _formatDuration(data.timeLoggedPerWorkingDay), title: 'Time Logged / Day'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ValueCard extends StatelessWidget {
  const ValueCard({
    Key? key,
    required this.value,
    required this.title,
    this.isLoading = false,
  }) : super(key: key);

  final String value;
  final String title;
  final bool isLoading;

  TextStyle get valueStyle => GoogleFonts.lato(fontSize: 36, fontWeight: FontWeight.w700);
  TextStyle get titleStyle => GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.w400);

  @override
  Widget build(BuildContext context) => Card(
        elevation: 2.5,
        child: Container(
          constraints: const BoxConstraints(minWidth: 175, maxWidth: 300),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: isLoading
              ? const CircularProgressIndicator()
              : Column(
                  children: [
                    const SizedBox(height: 32),
                    Text(value, style: valueStyle, textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    Text(title, style: titleStyle),
                  ],
                ),
        ),
      );
}
