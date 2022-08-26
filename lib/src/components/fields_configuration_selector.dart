import 'package:atlassian_apis/jira_platform.dart' hide FieldConfiguration;
import 'package:elopage_performance/src/extensions/field_details_ext.dart';
import 'package:elopage_performance/src/jira/jira.dart';
import 'package:elopage_performance/src/models/field_configuration.dart';
import 'package:elopage_performance/src/models/fileld_type.dart';
import 'package:elopage_performance/src/service_locator.dart';
import 'package:flutter/material.dart';

class FieldsConfigurationSelector extends StatefulWidget {
  const FieldsConfigurationSelector({Key? key, this.exclude = const []}) : super(key: key);

  final List<FieldConfiguration> exclude;

  @override
  State<FieldsConfigurationSelector> createState() => _FieldsConfigurationSelectorState();
}

class _FieldsConfigurationSelectorState extends State<FieldsConfigurationSelector> {
  FieldType? type;
  FieldDetails? field;
  FieldConfiguration? configuration;

  int currentStep = 0;
  List<FieldDetails>? detailsOptions;

  void didChangeField(final FieldDetails? fieldDetails) {
    if (!mounted || field == fieldDetails) return;

    field = fieldDetails;
    configuration = null;
    currentStep = 2;

    setState(() {});
  }

  Future<void> didChangeFieldType(final FieldType? value) async {
    if (type == value) return;

    field = null;
    currentStep = 1;
    if (mounted) setState(() {});

    final jira = serviceLocator<Jira>();
    final fields = await jira.issueFields.getFields();

    type = value;
    field = null;

    detailsOptions = fields.where((f) => f.type == type && !widget.exclude.any((e) => e.field.id == f.id)).toList();

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxHeight: 500, minWidth: 350, maxWidth: 500),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: Theme.of(context).dialogBackgroundColor,
        ),
        child: Material(
          color: Colors.transparent,
          child: Stepper(
            currentStep: currentStep,
            onStepTapped: (i) {
              if (mounted) setState(() => currentStep = i);
            },
            controlsBuilder: buildControls,
            steps: [
              Step(
                isActive: true,
                title: Text('Select type ${type?.value != null ? '(${type?.value})' : ''}'),
                subtitle: const Text('Select type of field you would like to add'),
                content: DropdownButton<FieldType>(
                  value: type,
                  isExpanded: true,
                  onChanged: didChangeFieldType,
                  focusColor: Colors.transparent,
                  hint: const Text('Select field type'),
                  items: FieldType.defined.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                ),
              ),
              Step(
                isActive: type != null,
                title: Text('Select field ${field?.name != null ? '(${field?.name})' : ''}'),
                state: type != null ? StepState.indexed : StepState.disabled,
                subtitle: const Text('Select field based on which we will build a statistics for you'),
                content: DropdownButton<FieldDetails>(
                  value: field,
                  isExpanded: true,
                  onChanged: didChangeField,
                  focusColor: Colors.transparent,
                  hint: const Text('Select field'),
                  borderRadius: BorderRadius.circular(6),
                  items: detailsOptions?.map((d) => DropdownMenuItem(value: d, child: Text(d.name ?? ''))).toList(),
                ),
              ),
              Step(
                isActive: field != null,
                title: const Text('Configure field'),
                content: buildConfiguration(context),
                state: field != null ? StepState.indexed : StepState.disabled,
                subtitle: const Text('Configure how your field should behave'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildConfiguration(BuildContext context) {
    switch (field?.type) {
      case FieldType.number:
        return _NumberFieldConfigurator(
          field: field!,
          key: ValueKey(field?.id),
          onConfigurationChanged: (value) {
            if (mounted) setState(() => configuration = value);
          },
        );

      default:
        return Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'This field has no configuration - feel free to continue',
            style: Theme.of(context).textTheme.subtitle2?.copyWith(color: Colors.grey),
          ),
        );
    }
  }

  Widget buildControls(BuildContext context, ControlsDetails controlsDetails) {
    switch (controlsDetails.stepIndex) {
      case 0:
      case 1:
        return const SizedBox.shrink();

      case 2:
      default:
        return Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: ElevatedButton(
              onPressed: configuration != null ? () => Navigator.pop(context, configuration) : null,
              style: ElevatedButton.styleFrom(elevation: 0),
              child: const Text('Add field to statistics'),
            ),
          ),
        );
    }
  }

  void onStepTapped(final int index) {
    if (mounted) setState(() => currentStep = index);
  }
}

class _NumberFieldConfigurator extends StatefulWidget {
  const _NumberFieldConfigurator({Key? key, required this.field, required this.onConfigurationChanged})
      : super(key: key);

  final FieldDetails field;
  final ValueChanged<NumberFieldConfiguration?> onConfigurationChanged;

  @override
  State<_NumberFieldConfigurator> createState() => _NumberFieldConfiguratorState();
}

class _NumberFieldConfiguratorState extends State<_NumberFieldConfigurator> {
  NumberFieldRepresentation? representation;

  @override
  void initState() {
    super.initState();
    assert(widget.field.type == FieldType.number, '_NumberFieldConfigurator works only with Number type fields');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose representation of number value. '
          'Values like "Original estimate" or "Time spent" '
          'Jira represent as numbers in seconds, so those '
          'will look better with time representation mode.',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(height: 1.4),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Radio<NumberFieldRepresentation>(
              splashRadius: 15,
              groupValue: representation,
              onChanged: setRepresentation,
              value: NumberFieldRepresentation.number,
            ),
            GestureDetector(
              onTap: () => setRepresentation(NumberFieldRepresentation.number),
              child: const Text('Number'),
            ),
            const SizedBox(width: 32),
            Radio<NumberFieldRepresentation>(
              splashRadius: 15,
              groupValue: representation,
              onChanged: setRepresentation,
              value: NumberFieldRepresentation.time,
            ),
            GestureDetector(
              onTap: () => setRepresentation(NumberFieldRepresentation.time),
              child: const Text('Time'),
            ),
          ],
        ),
      ],
    );
  }

  void setRepresentation(final NumberFieldRepresentation? value) {
    if (!mounted) return;
    setState(() => representation = value);
    widget.onConfigurationChanged(value == null ? null : NumberFieldConfiguration(widget.field, value));
  }
}
