import 'package:elopage_performance/src/models/field_configuration.dart';
import 'package:elopage_performance/src/models/fileld_type.dart';
import 'package:elopage_performance/src/models/performance_data.dart';

abstract class Statistics {
  const Statistics({this.composed});

  final Statistics? composed;
}

class GeneralStatistics extends Statistics {
  GeneralStatistics(final PerformanceData data, final int workingDays, {super.composed}) {
    issuesCount = data.issues.length;

    issuesPerWorkingDay = workingDays > 0 ? issuesCount / workingDays : 0;
    workingDaysPerIssue = issuesCount > 0 ? workingDays / issuesCount : 0;
  }

  late final int issuesCount;
  late final double issuesPerWorkingDay;
  late final double workingDaysPerIssue;
}

class TimeLoggingStatistics extends Statistics {
  TimeLoggingStatistics(final PerformanceData data, final int workingDays, {super.composed}) {
    totalLogged = data.totalLoggedMilis;
    loggedTimePerWorkingDay = workingDays > 0 ? data.totalLoggedMilis ~/ workingDays : 0;
    loggedTimePerIssue = data.issues.isNotEmpty ? data.totalLoggedMilis ~/ data.issues.length : 0;
  }

  late final int totalLogged;
  late final int loggedTimePerIssue;
  late final int loggedTimePerWorkingDay;
}

abstract class FieldStatistics extends Statistics {
  const FieldStatistics(this.configuration, {super.composed});

  final FieldConfiguration configuration;
}

class NumberFieldStatistics extends FieldStatistics {
  NumberFieldStatistics(
    final NumberFieldConfiguration super.configuration,
    final PerformanceData data, {
    super.composed,
  }) {
    assert(configuration.type == FieldType.number, 'This statistics can\'t accept other then "number" fields');
    final issues = data.issues;
    final issuesWithField = issues.where((i) => i.fields?[configuration.field.key] != null);

    issuesWithFieldCount = issuesWithField.length;
    sum = issuesWithField.fold(0.0, (p, issue) => p + issue.fields![configuration.field.key]);
  }

  @override
  NumberFieldConfiguration get configuration => super.configuration as NumberFieldConfiguration;

  late final double sum;
  late final int issuesWithFieldCount;
  double get averageValuePerIssue => issuesWithFieldCount > 0 ? sum / issuesWithFieldCount : 0;
}
