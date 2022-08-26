import 'package:atlassian_apis/jira_platform.dart' hide FieldConfiguration;
import 'package:elopage_performance/src/models/field_configuration.dart';

class StatisticsConfiguration {
  const StatisticsConfiguration({
    required this.name,
    required this.group,
    required this.dataGrouping,
    required this.fieldConfigurations,
  });

  final String name;
  final int dataGrouping;
  final GroupDetails group;
  final List<FieldConfiguration> fieldConfigurations;

  Map<String, dynamic> toJson() => {
        'name': name,
        'grouping': dataGrouping,
        'users_group': group.toJson(),
        'field_configurations': fieldConfigurations.map<Map<String, dynamic>>((d) => d.toJson()).toList(),
      };

  static StatisticsConfiguration fromJson(final Map<String, dynamic> json) => StatisticsConfiguration(
        name: json['name'],
        dataGrouping: json['grouping'],
        group: GroupDetails.fromJson(Map<String, Object?>.from(json['users_group'])),
        fieldConfigurations: List<Map>.from(json['field_configurations'])
            .map(Map<String, dynamic>.from)
            .map(FieldConfiguration.fromJson)
            .whereType<FieldConfiguration>()
            .toList(),
      );
}
