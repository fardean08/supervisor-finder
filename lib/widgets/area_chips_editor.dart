import 'package:flutter/material.dart';

/// Lets a staff member add and remove areas of interest as chips.
/// Read-only mode (no delete buttons) is used when students view a profile.
class AreaChipsEditor extends StatelessWidget {
  const AreaChipsEditor({
    super.key,
    required this.areas,
    this.onAdd,
    this.onRemove,
  });

  final List<String> areas;
  final ValueChanged<String>? onAdd;
  final ValueChanged<String>? onRemove;

  bool get isEditable => onAdd != null && onRemove != null;

  Future<void> _showAddDialog(BuildContext context) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add area of interest'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Graph theory, Data analysis',
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    final trimmed = result?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      onAdd!(trimmed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final area in areas)
          isEditable
              ? InputChip(
                  label: Text(area),
                  onDeleted: () => onRemove!(area),
                )
              : Chip(label: Text(area)),
        if (isEditable)
          ActionChip(
            avatar: const Icon(Icons.add, size: 18),
            label: const Text('Add area'),
            onPressed: () => _showAddDialog(context),
          ),
        if (!isEditable && areas.isEmpty)
          const Text(
            'No areas of interest listed yet.',
            style: TextStyle(color: Colors.grey),
          ),
      ],
    );
  }
}
