import 'package:atlassian_apis/jira_platform.dart';

void main(List<String> args) async {
  await test();
}

Future<void> test() async {
  const user = 'apps@elopage.com';
  const apiToken = 'uNZ5vOOBVmzolPN3v8Qy133A';

  // Create an authenticated http client.
  final client = ApiClient.basicAuthentication(
    Uri.https('elopay.atlassian.net', ''),
    user: user,
    apiToken: apiToken,
  );

  // Create the API wrapper from the http client
  final jira = JiraPlatformApi(client);

  final issues = await jira.issueSearch.searchForIssuesUsingJql(jql: 'project = "EM" ORDER BY created DESC');

  // print(issues.issues);

  final groups = await jira.groups.findGroups(maxResults: 100);

  print(groups.groups);

  // Close the client to quickly terminate the process
  client.close();
}
