import 'package:atlassian_apis/jira_platform.dart';
import 'package:elopage_performance/src/models/fileld_type.dart';
import 'package:elopage_performance/src/models/performance_data.dart';
import 'package:elopage_performance/src/models/statistics.dart';

extension FieldDetailsExt on FieldDetails {
  FieldType get type => FieldType.fromString(schema?.type);
  FieldStatistics? buildStatistics(final PerformanceData data) {
    switch (type) {
      case FieldType.number:
        return NumberFieldStatistics.performance(this, data);
      case FieldType.unknown:
        return null;
    }
  }
}
