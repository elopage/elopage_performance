import 'package:atlassian_apis/jira_platform.dart';
import 'package:elopage_performance/src/models/fileld_type.dart';

extension FieldDetailsExt on FieldDetails {
  FieldType get type => FieldType.fromString(schema?.type);
}
