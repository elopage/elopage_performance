import 'package:atlassian_apis/jira_platform.dart' hide Icon;
import 'package:elopage_performance/src/jira/jira.dart';
import 'package:elopage_performance/src/service_locator.dart';
import 'package:flutter/material.dart';

class GroupSelector extends StatefulWidget {
  const GroupSelector({Key? key, this.selected}) : super(key: key);

  final GroupDetails? selected;

  @override
  State<GroupSelector> createState() => _GroupSelectorState();
}

class _GroupSelectorState extends State<GroupSelector> {
  late final Jira jira;
  final groups = <GroupDetails>[];
  final controller = TextEditingController();

  List<GroupDetails> filteredGroups = [];

  @override
  void initState() {
    super.initState();
    jira = serviceLocator();

    controller.addListener(() {
      if (mounted) setState(filterGroups);
    });
    jira.groups.bulkGetGroups(maxResults: 1000).then((gropResult) {
      groups.addAll(gropResult.values);
      filterGroups();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void filterGroups() {
    filteredGroups =
        groups.where((g) => g.name?.toLowerCase().contains(controller.text.trim().toLowerCase()) ?? false).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(minHeight: 500, maxHeight: 500, minWidth: 350, maxWidth: 500),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: Theme.of(context).dialogBackgroundColor,
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(50.0)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50.0),
                    borderSide: BorderSide(width: 1, color: Theme.of(context).primaryColor),
                  ),
                ),
              ),
              const Divider(height: 32),
              Expanded(
                child: groups.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: filteredGroups.length,
                        itemBuilder: (context, index) {
                          final group = filteredGroups[index];
                          return GestureDetector(
                            onTap: () => Navigator.pop(context, group),
                            child: ListTile(
                              key: ValueKey(group.groupId),
                              title: Text(group.name ?? ''),
                              subtitle: Text(group.groupId ?? ''),
                              trailing: widget.selected?.groupId == group.groupId
                                  ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                                  : null,
                            ),
                          );
                        },
                      ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
