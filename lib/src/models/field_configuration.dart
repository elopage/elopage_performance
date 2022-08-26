import 'package:atlassian_apis/jira_platform.dart';
import 'package:elopage_performance/src/extensions/field_details_ext.dart';
import 'package:elopage_performance/src/models/fileld_type.dart';
import 'package:elopage_performance/src/models/performance_data.dart';
import 'package:elopage_performance/src/models/statistics.dart';

extension FieldConfigurationExt on FieldConfiguration {
  FieldStatistics? buildStatistics(final PerformanceData data) {
    switch (type) {
      case FieldType.number:
        return NumberFieldStatistics(this as NumberFieldConfiguration, data);
      case FieldType.unknown:
        return null;
    }
  }
}

abstract class FieldConfiguration {
  const FieldConfiguration(this.field);
  final FieldDetails field;

  FieldType get type => field.type;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'field': field.toJson()};

    switch (runtimeType) {
      case NumberFieldConfiguration:
        map['representation'] = (this as NumberFieldConfiguration).representation.value;
        return map;
    }

    return {};
  }

  static FieldConfiguration? fromJson(final Map<String, dynamic> json) {
    json['field'] = Map<String, dynamic>.from(json['field'] ?? {});
    json['field']?['schema'] = Map<String, dynamic>.from(json['field']?['schema'] ?? {});
    final field = FieldDetails.fromJson(json['field']);

    switch (field.type) {
      case FieldType.number:
        return NumberFieldConfiguration(field, NumberFieldRepresentation.fromValue(json['representation']));
      default:
        return null;
    }
  }
}

enum NumberFieldRepresentation {
  number('number'),
  time('time');

  const NumberFieldRepresentation(this.value);
  factory NumberFieldRepresentation.fromValue(final String value) => value == 'time' ? time : number;

  final String value;
}

class NumberFieldConfiguration extends FieldConfiguration {
  const NumberFieldConfiguration(super.field, final this.representation);
  final NumberFieldRepresentation representation;
}
