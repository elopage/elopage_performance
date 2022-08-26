import 'package:atlassian_apis/jira_platform.dart' hide Icon, FieldConfiguration;
import 'package:elopage_performance/src/components/fields_configuration_selector.dart';
import 'package:elopage_performance/src/components/group_selector.dart';
import 'package:elopage_performance/src/extensions/field_details_ext.dart';
import 'package:elopage_performance/src/models/field_configuration.dart';
import 'package:elopage_performance/src/models/fileld_type.dart';
import 'package:elopage_performance/src/models/statistics_configuration.dart';
import 'package:flutter/material.dart';

class ConfigurationEditPage extends StatefulWidget {
  const ConfigurationEditPage({Key? key, this.editConfig}) : super(key: key);

  final StatisticsConfiguration? editConfig;

  @override
  State<ConfigurationEditPage> createState() => _ConfigurationEditPageState();
}

class _ConfigurationEditPageState extends State<ConfigurationEditPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final fieldConfigurations = <FieldConfiguration>[];
  late final TextEditingController nameController;
  late final TextEditingController groupingController;

  GroupDetails? group;

  bool get isEditing => widget.editConfig != null;

  @override
  void initState() {
    super.initState();
    group = widget.editConfig?.group;
    nameController = TextEditingController(text: widget.editConfig?.name);
    groupingController = TextEditingController(text: widget.editConfig?.dataGrouping.toString() ?? '1');
    if (isEditing) fieldConfigurations.addAll(widget.editConfig!.fieldConfigurations);
  }

  @override
  void dispose() {
    super.dispose();
    nameController.dispose();
    groupingController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editing "${widget.editConfig?.name}"' : 'New configuration')),
      floatingActionButton: SizedBox(
        width: 70.0,
        height: 40.0,
        child: RawMaterialButton(
          onPressed: createConfig,
          fillColor: Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          child: Text('Save', style: Theme.of(context).primaryTextTheme.button),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16).copyWith(bottom: 56),
          children: [
            TextFormField(
              validator: validateName,
              controller: nameController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: const InputDecoration(
                labelText: 'Configuration name',
                hintText: 'My team statistics',
                helperText: 'Internal statistics configuration name',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              validator: validateGrouping,
              controller: groupingController,
              keyboardType: TextInputType.number,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: const InputDecoration(
                labelText: 'Grouping',
                helperText: 'Number of weeks per which statistics data will be grouped',
              ),
            ),
            const SizedBox(height: 38),
            FormField(
              initialValue: group,
              validator: validateUsers,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              builder: (state) {
                final hasError = state.errorText != null;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('User group', style: Theme.of(context).textTheme.headline5),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => openGroupSelector(state),
                        style: OutlinedButton.styleFrom(
                          side: hasError ? BorderSide(color: Colors.red[800]!) : null,
                          minimumSize: const Size(100, 75),
                        ),
                        child: group == null
                            ? const Text('Assign user group')
                            : ListTile(
                                key: ValueKey(group!.groupId),
                                title: Text(group!.name ?? ''),
                                subtitle: Text(group!.groupId ?? ''),
                                trailing: Icon(Icons.check, color: Theme.of(context).primaryColor),
                              ),
                      ),
                    ),
                    if (hasError) const SizedBox(height: 8),
                    if (hasError)
                      Text(
                        state.errorText!,
                        style: Theme.of(context).textTheme.caption?.copyWith(color: Colors.red[800]),
                      )
                  ],
                );
              },
            ),
            const SizedBox(height: 48),
            ReorderableListView(
              shrinkWrap: true,
              onReorder: reorderFields,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              header: Column(
                children: [
                  SizedBox(
                    height: 30,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text('Fields', style: Theme.of(context).textTheme.headline5)),
                        TextButton(onPressed: openFieldSelector, child: const Text('+ add')),
                      ],
                    ),
                  ),
                  const Divider(height: 32),
                ],
              ),
              footer: fieldConfigurations.isNotEmpty
                  ? null
                  : Container(
                      height: 65,
                      alignment: Alignment.center,
                      child: Text(
                        'Here you can set up custom statistics data',
                        style: Theme.of(context).textTheme.headline5?.copyWith(color: Colors.grey[300]),
                      ),
                    ),
              children: fieldConfigurations
                  .map<ListTile>((c) => ListTile(
                        minVerticalPadding: 8,
                        key: ValueKey(c.field.id ?? ''),
                        title: Text(c.field.name ?? ''),
                        subtitle: Text(c.field.id ?? ''),
                        leading: buildLeading(context, c),
                        contentPadding: const EdgeInsets.only(left: 8.0),
                        trailing: Padding(
                          padding: const EdgeInsets.only(right: 36.0),
                          child: IconButton(
                            iconSize: 20,
                            splashRadius: 22,
                            onPressed: () => removeField(c),
                            icon: Icon(Icons.delete_sweep_outlined, color: Colors.red[300]!),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const Divider(height: 32),
          ],
        ),
      ),
    );
  }

  Widget buildLeading(final BuildContext context, final FieldConfiguration configuration) {
    switch (configuration.field.type) {
      case FieldType.number:
        final representation = (configuration as NumberFieldConfiguration).representation;
        return Icon(representation == NumberFieldRepresentation.time ? Icons.timer_outlined : Icons.onetwothree);

      default:
        return const SizedBox.shrink();
    }
  }

  void removeField(final FieldConfiguration configuration) {
    fieldConfigurations.remove(configuration);

    if (mounted) setState(() {});
  }

  void reorderFields(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;

    final field = fieldConfigurations.removeAt(oldIndex);
    fieldConfigurations.insert(newIndex, field);

    if (mounted) setState(() {});
  }

  String? validateName(final String? name) => name == null || name.trim().isEmpty ? 'Field can not be empty' : null;

  String? validateUsers(GroupDetails? value) {
    if (value == null) return 'You must assign users group';
    return null;
  }

  String? validateGrouping(final String? period) {
    const generalExplanation = 'Value must be an integer higher or equals 1.';
    if (period == null || period.isEmpty) return 'Field can not be empty. $generalExplanation';
    final number = int.tryParse(period);
    if (number == null) return 'Value must be an integer. $generalExplanation';
    if (number < 1) return generalExplanation;
    return null;
  }

  Future<void> openGroupSelector(final FormFieldState state) async {
    final selected = await showDialog<GroupDetails?>(
      context: context,
      builder: (_) => GroupSelector(selected: group),
    );

    if (selected == null || selected == group) return;

    group = selected;

    if (mounted) setState(() {});

    state.didChange(selected);
  }

  Future<void> openFieldSelector() async {
    final selected = await showDialog<FieldConfiguration?>(
      context: context,
      builder: (context) => FieldsConfigurationSelector(exclude: fieldConfigurations),
    );

    if (selected == null) return;

    fieldConfigurations.add(selected);

    if (mounted) setState(() {});
  }

  void createConfig() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState?.save();

      final name = nameController.text.trim();
      final grouping = int.tryParse(groupingController.text);

      if (group == null || name.isEmpty || grouping == null || grouping < 1) return;
      final statisticsConfig = StatisticsConfiguration(
        name: name,
        group: group!,
        dataGrouping: grouping,
        fieldConfigurations: fieldConfigurations,
      );

      if (mounted) Navigator.of(context).pop(statisticsConfig);
    }
  }
}
