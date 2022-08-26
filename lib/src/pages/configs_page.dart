import 'package:elopage_performance/src/controllers/configurations_page_controller.dart';
import 'package:elopage_performance/src/jira/jira.dart';
import 'package:elopage_performance/src/models/statistics_configuration.dart';
import 'package:elopage_performance/src/pages/configuration_edit_page.dart';
import 'package:elopage_performance/src/pages/group_page.dart';
import 'package:flutter/material.dart';

class ConfigsPage extends StatefulWidget {
  const ConfigsPage({Key? key}) : super(key: key);

  @override
  State<ConfigsPage> createState() => _ConfigsPageState();
}

class _ConfigsPageState extends State<ConfigsPage> {
  bool isEditing = false;

  late final Jira jira;
  final controller = ConfigurationsPageController();

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      if (mounted) setState(() {});
    });
    controller.initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        actions: [
          AnimatedOpacity(
            opacity: isEditing || controller.configurations.isEmpty ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: isEditing ? null : () => setState(() => isEditing = true),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        height: 40.0,
        child: RawMaterialButton(
          onPressed: isEditing ? closeEditing : createConfig,
          fillColor: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: Text(
              isEditing ? 'Exit editing' : 'New configuration',
              style: Theme.of(context).primaryTextTheme.button,
            ),
          ),
        ),
      ),
      body: !controller.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : ReorderableListView.builder(
              onReorder: controller.move,
              itemCount: controller.configurations.length,
              buildDefaultDragHandles: isEditing,
              itemBuilder: (context, i) => _StatisticsTile(
                onEdit: () => editConfig(i),
                showEditingButtons: isEditing,
                config: controller.configurations[i],
                onDelete: () => controller.delete(i),
                key: ValueKey(controller.configurations[i].hashCode),
                showStatistics: MediaQuery.of(context).size.width >= 600 || !isEditing,
                onTap: isEditing ? null : () => openStatistics(controller.configurations[i]),
              ),
            ),
    );
  }

  void openStatistics(final StatisticsConfiguration configuration) {
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => GroupPage(configuration: configuration)));
  }

  Future<void> closeEditing() async {
    if (!mounted) return;

    setState(() => isEditing = false);
  }

  Future<void> createConfig() async {
    if (!mounted) return;

    final statistics = await Navigator.of(context)
        .push<StatisticsConfiguration>(MaterialPageRoute(builder: (_) => const ConfigurationEditPage()));

    if (statistics == null) return;

    controller.save(statistics);
  }

  Future<void> editConfig(final int index) async {
    if (!mounted) return;

    final currentConfig = controller.configurations[index];
    final statistics = await Navigator.of(context).push<StatisticsConfiguration>(
      MaterialPageRoute(builder: (_) => ConfigurationEditPage(editConfig: currentConfig)),
    );

    if (statistics == null) return;

    controller.edit(index, statistics);
  }
}

class _StatisticsTile extends StatelessWidget {
  const _StatisticsTile({
    Key? key,
    this.onTap,
    this.onEdit,
    this.onDelete,
    required this.config,
    this.showStatistics = true,
    this.showEditingButtons = false,
  }) : super(key: key);

  final bool showStatistics;
  final bool showEditingButtons;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final StatisticsConfiguration config;

  @override
  Widget build(BuildContext context) {
    final trailingTitle = Theme.of(context).textTheme.bodyText1?.copyWith(fontSize: 12);
    final trailingSubtitle = Theme.of(context).textTheme.headline6?.copyWith(fontWeight: FontWeight.bold);
    return ListTile(
      onTap: onTap,
      tileColor: Colors.white,
      title: Text(config.name),
      subtitle: Text(config.group.name ?? ''),
      trailing: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showStatistics)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Grouping period', style: trailingTitle),
                  Text('${config.dataGrouping}w', style: trailingSubtitle),
                ],
              ),
            if (showStatistics) const SizedBox(width: 20),
            if (showStatistics)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Fields', style: trailingTitle),
                  Text('${config.fields.length}', style: trailingSubtitle),
                ],
              ),
            if (showEditingButtons) const SizedBox(width: 32),
            if (showEditingButtons)
              IconButton(
                iconSize: 23,
                splashRadius: 22,
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                icon: Icon(Icons.edit_note, color: Theme.of(context).primaryColor),
              ),
            if (showEditingButtons) const SizedBox(width: 16),
            if (showEditingButtons)
              IconButton(
                iconSize: 23,
                splashRadius: 22,
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                icon: Icon(Icons.delete_sweep_outlined, color: Colors.red[300]!),
              ),
            if (showEditingButtons) const SizedBox(width: 32),
          ],
        ),
      ),
    );
  }
}
