import 'package:atlassian_apis/jira_platform.dart';

typedef PerformanceData = Map<IssueBean, List<Worklog>>;

extension PerformanceDataExt on PerformanceData {
  List<IssueBean> get issues => keys.toList();
  List<Worklog> get worklogs => values.fold<List<Worklog>>([], (p, worklogs) => p..addAll(worklogs)).toList();

  int get totalLoggedMilis => worklogs.fold<int>(0, (t, w) => t + (w.timeSpentSeconds ?? 0)) * 1000;
  Duration get totalLogged => worklogs.fold(Duration.zero, (t, w) => t + Duration(seconds: w.timeSpentSeconds ?? 0));
}
