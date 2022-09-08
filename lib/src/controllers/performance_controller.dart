import 'dart:async';

import 'package:atlassian_apis/jira_platform.dart' hide FieldConfiguration;
import 'package:elopage_performance/src/jira/jira.dart';
import 'package:elopage_performance/src/models/field_configuration.dart';
import 'package:elopage_performance/src/models/performance_data.dart';
import 'package:elopage_performance/src/models/statistics.dart';
import 'package:elopage_performance/src/models/statistics_configuration.dart';
import 'package:elopage_performance/src/service_locator.dart';
import 'package:flutter/material.dart';

class Period {
  Period(this.startDate, this.endDate) {
    assert(startDate.isBefore(endDate), 'Start date must be before end date');
    workingDays = startDate.countWorkingDaysBefore(endDate);
  }

  late final int workingDays;
  final DateTime startDate;
  final DateTime endDate;
}

class PageStatisticsData {
  PageStatisticsData(this.period, this._statisticsComputation);

  final Period period;
  final Future<List<Statistics>> _statisticsComputation;

  bool get isComputing => _statistics == null;

  List<Statistics>? _statistics;
  List<Statistics>? get statistics => _statistics;
  Future<List<Statistics>> get statisticsComputation async {
    if (_statistics != null) return _statistics!;

    final statistics = await _statisticsComputation;
    _statistics = statistics;
    return statistics;
  }
}

extension on DateTime {
  String get jiraDate => '$year-$month-$day';

  int countWorkingDaysBefore(final DateTime endDate) {
    assert(isBefore(endDate), 'endDate must be afte $this');

    int workingDays = 0;

    DateTime date = this;
    while (date.isBefore(endDate)) {
      if (date.weekday <= 5) workingDays++;
      date = date.add(const Duration(days: 1));
    }

    return workingDays;
  }
}

class PerformanceController extends PageController {
  PerformanceController(this.configuration, this.users) {
    assert(users.isNotEmpty, 'You must pass at least 1 user for gathering statistics');
    assert(configuration.dataGrouping >= 1, 'Period must be higher or equal of 1');

    jira = serviceLocator();

    retrieveStatistics(0);
  }

  late final Jira jira;

  final now = DateTime.now();
  final data = <int, PageStatisticsData>{};

  final List<UserDetails> users;
  final StatisticsConfiguration configuration;

  @override
  double? get page {
    return positions.isEmpty ? initialPage.toDouble() : super.page;
  }

  PageStatisticsData get currentStatistics => retrieveStatistics(page?.round() ?? 0);
  Duration get periodDuration => Duration(days: configuration.dataGrouping * DateTime.daysPerWeek);

  Iterable<String> get _userIds => users.map((user) => user.accountId).whereType<String>();
  String get _userIdsQuery =>
      _userIds.fold<String>('', (q, userId) => '$q$userId${_userIds.last != userId ? ', ' : ''}');

  PageStatisticsData retrieveStatistics(final int page) {
    assert(page >= 0, 'Page can not be negative');

    if (data[page] != null) return data[page]!;

    final period = _buildPeriod(page);
    final pageData = _fetchPageData(period);
    pageData.catchError((e, s) {
      data.remove(page);
      return <Statistics>[];
    });

    final statistics = PageStatisticsData(period, pageData);
    data[page] = statistics;

    return statistics;
  }

  Period _buildPeriod(final int period) {
    if (configuration.freezeDate == null) {
      final endDate = DateTime(now.year, now.month, now.day).subtract(periodDuration * period);
      return Period(endDate.subtract(periodDuration), endDate);
    }

    final freeze = configuration.freezeDate!;
    final difference = now.difference(freeze);
    assert(!difference.isNegative, 'Freeze date can not be set in the future');

    final currentPeriodProgress = Duration(microseconds: difference.inMicroseconds % periodDuration.inMicroseconds);
    final latestPeriodStartDate = now.subtract(currentPeriodProgress);

    if (period == 0) return Period(latestPeriodStartDate, now);

    final endDate = latestPeriodStartDate.subtract(periodDuration * (period - 1));
    return Period(endDate.subtract(periodDuration), endDate);
  }

  Future<List<Statistics>> _fetchPageData(final Period period) async {
    final issuesResult = await jira.issueSearch.searchForIssuesUsingJql(
      maxResults: 1000,
      jql: [
        'worklogAuthor in ($_userIdsQuery) AND ',
        'worklogDate >= ${period.startDate.jiraDate} AND worklogDate <= ${period.endDate.jiraDate} ',
        'order by created DESC',
      ].join(),
    );

    final PerformanceData data = {};
    for (final issue in issuesResult.issues) {
      if (issue.id == null) continue;

      final worklogsResult = await jira.issueWorklogs.getIssueWorklog(
        startedAfter: period.startDate.millisecondsSinceEpoch,
        startedBefore: period.endDate.millisecondsSinceEpoch,
        issueIdOrKey: issue.id!,
        maxResults: 1000,
      );

      data[issue] = worklogsResult.worklogs.where((w) => _userIdsQuery.contains(w.author?.accountId ?? '')).toList();
    }

    return [
      GeneralStatistics(data, period.workingDays, composed: TimeLoggingStatistics(data, period.workingDays)),
      ...configuration.fieldConfigurations.map((f) => f.buildStatistics(data)).whereType<Statistics>(),
    ];
  }
}
