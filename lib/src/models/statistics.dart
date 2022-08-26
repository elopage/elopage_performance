import 'package:atlassian_apis/jira_platform.dart';
import 'package:elopage_performance/src/extensions/field_details_ext.dart';
import 'package:elopage_performance/src/models/fileld_type.dart';
import 'package:elopage_performance/src/models/performance_data.dart';

abstract class Statistics {
  const Statistics.performance({this.composed});

  final Statistics? composed;
}

class GeneralStatistics extends Statistics {
  GeneralStatistics.performance(final PerformanceData data, final int workingDays, {super.composed})
      : super.performance() {
    issuesCount = data.issues.length;

    issuesPerWorkingDay = workingDays > 0 ? issuesCount / workingDays : 0;
    workingDaysPerIssue = issuesCount > 0 ? workingDays / issuesCount : 0;
  }

  late final int issuesCount;
  late final double issuesPerWorkingDay;
  late final double workingDaysPerIssue;
}

class TimeLoggingStatistics extends Statistics {
  TimeLoggingStatistics.performance(final PerformanceData data, final int workingDays, {super.composed})
      : super.performance() {
    totalLogged = data.totalLogged;
    loggedTimePerIssue = data.issues.isNotEmpty
        ? Duration(milliseconds: totalLogged.inMilliseconds ~/ data.issues.length)
        : Duration.zero;
    loggedTimePerWorkingDay =
        workingDays > 0 ? Duration(milliseconds: totalLogged.inMilliseconds ~/ workingDays) : Duration.zero;
  }

  late final Duration totalLogged;
  late final Duration loggedTimePerIssue;
  late final Duration loggedTimePerWorkingDay;
}

abstract class FieldStatistics extends Statistics {
  const FieldStatistics.performance(this.field, {super.composed}) : super.performance();

  final FieldDetails field;
}

class NumberFieldStatistics extends FieldStatistics {
  NumberFieldStatistics.performance(super.field, final PerformanceData data, {super.composed}) : super.performance() {
    assert(field.type == FieldType.number, 'This statistics can\'t accept other then "number" fields');
    final issues = data.issues;
    final issuesWithField = issues.where((i) => i.fields?[field.key] != null);

    issuesWithFieldCount = issuesWithField.length;
    sum = issuesWithField.fold(0.0, (p, issue) => p + issue.fields![field.key]);
  }

  late final double sum;
  late final int issuesWithFieldCount;
  double get averageValuePerIssue => issuesWithFieldCount > 0 ? sum / issuesWithFieldCount : 0;
}
