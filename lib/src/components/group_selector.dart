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
  late Future<List<GroupDetails>> buildGroups;
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    jira = serviceLocator();

    controller.addListener(() {
      if (mounted) setState(() {});
    });
    buildGroups = _buildGroups();
  }

  Future<List<GroupDetails>> _buildGroups() async {
    final result = await jira.groups.bulkGetGroups(maxResults: 1000);
    return result.values;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
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
                child: FutureBuilder<List<GroupDetails>>(
                  future: buildGroups,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData && !snapshot.hasError) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(child: Text('${snapshot.error}')),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () => setState(() {
                              buildGroups = _buildGroups();
                            }),
                            child: const Text('Refresh'),
                          )
                        ],
                      );
                    }

                    final filteredGroups = snapshot.data!
                        .where((g) => g.name?.toLowerCase().contains(controller.text.trim().toLowerCase()) ?? false)
                        .toList();

                    return ListView.builder(
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
