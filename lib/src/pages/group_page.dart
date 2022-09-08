import 'package:atlassian_apis/jira_platform.dart';
import 'package:elopage_performance/src/components/user_group_badge.dart';
import 'package:elopage_performance/src/components/user_icon.dart';
import 'package:elopage_performance/src/jira/jira.dart';
import 'package:elopage_performance/src/models/statistics_configuration.dart';
import 'package:elopage_performance/src/pages/performance_page.dart';
import 'package:elopage_performance/src/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GroupPage extends StatefulWidget {
  const GroupPage({Key? key, required this.configuration}) : super(key: key);
  final StatisticsConfiguration configuration;

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  late final Jira jira;

  Future<List<UserDetails>>? buildUsers;

  String get groupName => widget.configuration.group.name ?? '';

  @override
  void initState() {
    super.initState();
    jira = serviceLocator();
    buildUsers = _buildUsers();
  }

  Future<List<UserDetails>> _buildUsers() async {
    final usersResult = await jira.groups.getUsersFromGroup(
      groupId: widget.configuration.group.groupId,
      maxResults: 100,
    );
    return usersResult.values;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(groupName)),
      body: Center(
        child: FutureBuilder(
          future: buildUsers,
          builder: (BuildContext context, AsyncSnapshot<List<UserDetails>> snapshot) {
            if (!snapshot.hasData && !snapshot.hasError) return const CircularProgressIndicator();
            if (snapshot.hasError) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(child: Text('${snapshot.error}')),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => setState(() {
                      buildUsers = _buildUsers();
                    }),
                    child: const Text('Refresh'),
                  )
                ],
              );
            }
            final users = snapshot.data!;
            return ListView.builder(
              itemCount: users.length + 1,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    tileColor: Colors.white,
                    onTap: () => _onGroupTap(users),
                    leading: UserGroupBadge(users: users),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(color: Theme.of(context).dividerColor, width: 1),
                    ),
                    title: Text(
                      '$groupName group statistics',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  );
                }

                final user = users[index - 1];
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: ListTile(
                    tileColor: Colors.white,
                    onTap: () => _onUserTap(user),
                    leading: UserIcon(avatar: user.avatarUrls?.$48X48),
                    title: Text('${user.displayName}', overflow: TextOverflow.ellipsis),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    subtitle: Text('${user.accountId}', overflow: TextOverflow.ellipsis),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _onGroupTap(final List<UserDetails> users) {
    if (!mounted) return;

    final page = PerformancePage(users: users, title: groupName, configuration: widget.configuration);
    final route = MaterialPageRoute(builder: (context) => page);
    Navigator.push(context, route);
  }

  void _onUserTap(final UserDetails user) {
    if (!mounted) return;

    final page = PerformancePage(users: [user], title: user.displayName ?? '', configuration: widget.configuration);
    final route = MaterialPageRoute(builder: (context) => page);
    Navigator.push(context, route);
  }
}
