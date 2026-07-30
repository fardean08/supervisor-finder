import 'package:flutter/material.dart';

import '../models/project_idea.dart';

class ProjectIdeaCard extends StatelessWidget {
  const ProjectIdeaCard({
    super.key,
    required this.idea,
    this.onEdit,
    this.onDelete,
  });

  final ProjectIdea idea;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  bool get isEditable => onEdit != null || onDelete != null;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lightbulb_outline, color: Color(0xFF2E5AAC)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    idea.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(idea.description),
                  if (idea.area.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(idea.area),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ],
              ),
            ),
            if (isEditable)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit?.call();
                  if (value == 'delete') onDelete?.call();
                },
                itemBuilder: (context) => [
                  if (onEdit != null)
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  if (onDelete != null)
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
