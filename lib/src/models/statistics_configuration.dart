import 'package:atlassian_apis/jira_platform.dart';

class StatisticsConfiguration {
  const StatisticsConfiguration({
    required this.name,
    required this.group,
    required this.fields,
    required this.dataGrouping,
  });

  final String name;
  final int dataGrouping;
  final GroupDetails group;
  final List<FieldDetails> fields;

  Map<String, dynamic> toJson() => {
        'name': name,
        'grouping': dataGrouping,
        'users_group': group.toJson(),
        'details': fields.map<Map<String, dynamic>>((d) => d.toJson()).toList(),
      };

  static StatisticsConfiguration fromJson(final Map<String, dynamic> json) => StatisticsConfiguration(
        name: json['name'],
        dataGrouping: json['grouping'],
        group: GroupDetails.fromJson(Map<String, Object?>.from(json['users_group'])),
        fields: List<Map>.from(json['details']).map(Map<String, dynamic>.from).map((m) {
          m['schema'] = Map<String, dynamic>.from(m['schema']);
          return FieldDetails.fromJson(m);
        }).toList(),
      );
}
