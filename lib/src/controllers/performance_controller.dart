import 'package:atlassian_apis/jira_platform.dart';
import 'package:elopage_performance/src/extensions/field_details_ext.dart';
import 'package:elopage_performance/src/jira/jira.dart';
import 'package:elopage_performance/src/models/performance_data.dart';
import 'package:elopage_performance/src/models/statistics.dart';
import 'package:elopage_performance/src/service_locator.dart';

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

class PerformanceController {
  PerformanceController(this.period, this.users) {
    assert(users.isNotEmpty, 'You must pass at least 1 user for gathering statistics');
    assert(period >= 1, 'Period must be higher or equal of 1');

    jira = serviceLocator();
    final now = DateTime.now();
    // Don't take in account data genrated today
    endDate = DateTime(now.year, now.month, now.day);
    startDate = endDate.subtract(Duration(days: period * DateTime.daysPerWeek));
    workingDays = startDate.countWorkingDaysBefore(endDate);
    statisticFields = [
      FieldDetails.fromJson({
        'id': 'customfield_10897',
        'key': 'customfield_10897',
        'name': 'QA count',
        'schema': {'type': 'number'},
      }),
      FieldDetails.fromJson({
        'id': 'customfield_10896',
        'key': 'customfield_10896',
        'name': 'Reviews Count',
        'schema': {'type': 'number'},
      })
    ];
  }

  // MARK: Configurations
  /// Period in weeks for now
  final int period;
  final List<UserDetails> users;
  late final List<FieldDetails> statisticFields;

  // MARK:
  late final int workingDays;
  late final DateTime endDate;
  late final DateTime startDate;

  // MARK: Preinitialized
  late final Jira jira;

  Map<IssueBean, List<Worklog>>? _data;
  List<Statistics>? _statistics;

  Map<IssueBean, List<Worklog>> get data {
    assert(_data != null, 'This field can be called only after calling fetchPageData()');
    return _data!;
  }

  List<Statistics> get statistics {
    assert(_statistics != null, 'This field can be called only after calling fetchPageData()');
    return _statistics!;
  }

  List<IssueBean> get issues => data.issues;
  List<Worklog> get worklogs => data.worklogs;

  Iterable<String> get userIds => users.map((user) => user.accountId).whereType<String>();
  String get userIdsQuery => userIds.fold<String>('', (q, userId) => '$q$userId${userIds.last != userId ? ', ' : ''}');

  Future<void> fetchPageData() async {
    final issuesResult = await jira.issueSearch.searchForIssuesUsingJql(
      maxResults: 1000,
      jql: 'worklogAuthor in ($userIdsQuery) AND '
          'worklogDate >= ${startDate.jiraDate} AND worklogDate <= ${endDate.jiraDate} '
          'order by created DESC',
    );

    _data = {};
    for (final issue in issuesResult.issues) {
      if (issue.id == null) continue;

      final worklogsResult = await jira.issueWorklogs.getIssueWorklog(
        startedAfter: startDate.millisecondsSinceEpoch,
        startedBefore: endDate.millisecondsSinceEpoch,
        issueIdOrKey: issue.id!,
        maxResults: 1000,
      );

      _data![issue] = worklogsResult.worklogs;
    }

    _statistics = [
      GeneralStatistics.performance(data, workingDays, composed: TimeingStatistics.performance(data, workingDays)),
      ...statisticFields.map((f) => f.buildStatistics(data)).whereType<Statistics>(),
    ];
  }
}
