import 'package:atlassian_apis/jira_platform.dart';
import 'package:elopage_performance/src/components/user_group_badge.dart';
import 'package:elopage_performance/src/components/user_icon.dart';
import 'package:elopage_performance/src/jira/jira.dart';
import 'package:elopage_performance/src/pages/performance_page.dart';
import 'package:elopage_performance/src/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GroupPage extends StatefulWidget {
  const GroupPage({Key? key, required this.groupName}) : super(key: key);
  final String groupName;

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  late final Jira jira;

  Group? group;
  List<UserDetails>? users;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    jira = serviceLocator();

    final usersResult = await jira.groups.getUsersFromGroup(groupname: widget.groupName, maxResults: 100);
    users = usersResult.values;

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.groupName)),
      body: Center(
        child: users == null
            ? const CircularProgressIndicator()
            : ListView.builder(
                itemCount: users!.length + 1,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ListTile(
                      tileColor: Colors.white,
                      leading: UserGroupBadge(users: users!),
                      onTap: () => _onUserTap(users!, widget.groupName),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: BorderSide(color: Theme.of(context).dividerColor, width: 1),
                      ),
                      title: Text(
                        '${widget.groupName} group statistics',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    );
                  }

                  final user = users![index - 1];
                  final id = user.accountId;
                  final email = user.emailAddress;

                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: ListTile(
                      tileColor: Colors.white,
                      leading: UserIcon(avatar: user.avatarUrls?.$48X48),
                      onTap: () => _onUserTap([user], user.displayName ?? ''),
                      title: Text('${user.displayName}', overflow: TextOverflow.ellipsis),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      subtitle: Text('$id${email == null ? '' : ' | $email'}', overflow: TextOverflow.ellipsis),
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _onUserTap(final List<UserDetails> users, final String title) {
    final route = MaterialPageRoute(builder: ((context) => PerformancePage(users: users, title: title)));
    if (mounted) Navigator.push(context, route);
  }
}
