import 'package:atlassian_apis/jira_platform.dart';
import 'package:elopage_performance/src/extensions/field_details_ext.dart';
import 'package:elopage_performance/src/jira/jira.dart';
import 'package:elopage_performance/src/models/fileld_type.dart';
import 'package:elopage_performance/src/service_locator.dart';
import 'package:flutter/material.dart';

class FieldsSelector extends StatefulWidget {
  const FieldsSelector({Key? key, this.exclude = const []}) : super(key: key);

  final List<FieldDetails> exclude;

  @override
  State<FieldsSelector> createState() => _FieldsSelectorState();
}

class _FieldsSelectorState extends State<FieldsSelector> {
  FieldType? type;
  FieldDetails? field;

  int currentStep = 0;
  List<FieldDetails>? detailsOptions;

  void didChangeField(final FieldDetails? fieldDetails) {
    if (mounted) setState(() => field = fieldDetails);
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

    detailsOptions = fields.where((f) => f.type == type && !widget.exclude.any((e) => e.id == f.id)).toList();

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
                title: const Text('Field type'),
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
                title: const Text('Field'),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget buildControls(BuildContext context, ControlsDetails controlsDetails) {
    switch (controlsDetails.stepIndex) {
      case 0:
        return const SizedBox.shrink();

      case 1:
      default:
        return Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(elevation: 0),
              onPressed: field != null ? () => Navigator.pop(context, field) : null,
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
