import 'package:flutter/material.dart';

import '../models/project_idea.dart';

/// Shows a dialog to create or edit a [ProjectIdea]. Returns the resulting
/// idea, or null if the user cancelled.
Future<ProjectIdea?> showProjectIdeaForm(
  BuildContext context, {
  ProjectIdea? existing,
  List<String> areaOptions = const [],
}) {
  final titleController = TextEditingController(text: existing?.title ?? '');
  final descriptionController =
      TextEditingController(text: existing?.description ?? '');
  var selectedArea = existing?.area ?? (areaOptions.isNotEmpty ? areaOptions.first : '');

  return showDialog<ProjectIdea>(
    context: context,
    builder: (context) {
      final formKey = GlobalKey<FormState>();

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(existing == null ? 'Add project idea' : 'Edit project idea'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty) ? 'Enter a title' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 4,
                      validator: (value) =>
                          (value == null || value.trim().isEmpty) ? 'Enter a description' : null,
                    ),
                    if (areaOptions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedArea.isEmpty ? null : selectedArea,
                        decoration: const InputDecoration(labelText: 'Related area (optional)'),
                        items: [
                          for (final area in {...areaOptions, if (selectedArea.isNotEmpty) selectedArea})
                            DropdownMenuItem(value: area, child: Text(area)),
                        ],
                        onChanged: (value) => setState(() => selectedArea = value ?? ''),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;

                  Navigator.of(context).pop(
                    ProjectIdea(
                      id: existing?.id ?? '',
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      area: selectedArea,
                    ),
                  );
                },
                child: Text(existing == null ? 'Add' : 'Save'),
              ),
            ],
          );
        },
      );
    },
  );
}
