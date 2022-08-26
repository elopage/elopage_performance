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

  Group? group;
  List<UserDetails>? users;

  String get groupName => widget.configuration.group.name ?? '';

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    jira = serviceLocator();

    final usersResult = await jira.groups.getUsersFromGroup(
      groupId: widget.configuration.group.groupId,
      maxResults: 100,
    );
    users = usersResult.values;

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(groupName)),
      body: Center(
        child: users == null
            ? const CircularProgressIndicator()
            : ListView.builder(
                itemCount: users!.length + 1,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ListTile(
                      onTap: _onGroupTap,
                      tileColor: Colors.white,
                      leading: UserGroupBadge(users: users!),
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

                  final user = users![index - 1];
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
              ),
      ),
    );
  }

  void _onGroupTap() {
    if (!mounted || users == null) return;

    final page = PerformancePage(users: users!, title: groupName, configuration: widget.configuration);
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
