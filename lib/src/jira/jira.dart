import 'package:atlassian_apis/jira_platform.dart';

const user = 'bohdan.krokhmaliuk@elopage.com';
const authority = 'elopay.atlassian.net';
const apiToken = 'eoTbThLi6ZWyRed5Q9Sd5AE5';

class Jira extends JiraPlatformApi {
  Jira._(super.client);

  factory Jira() {
    final client = ApiClient.basicAuthentication(Uri.https(authority, ''), user: user, apiToken: apiToken);
    return Jira._(client);
  }
}
