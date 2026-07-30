import 'package:flutter/material.dart';

import '../models/staff_profile.dart';
import '../widgets/area_chips_editor.dart';
import '../widgets/project_idea_card.dart';

class StaffProfileDetailScreen extends StatelessWidget {
  const StaffProfileDetailScreen({super.key, required this.profile});

  final StaffProfile profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(profile.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF2E5AAC),
                        child: Text(
                          profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile.name, style: Theme.of(context).textTheme.titleLarge),
                            if (profile.department.isNotEmpty)
                              Text(profile.department, style: const TextStyle(color: Colors.grey)),
                            Text(profile.email, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (profile.bio.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(profile.bio),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Areas of interest', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  AreaChipsEditor(areas: profile.areasOfInterest),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Project ideas', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (profile.projectIdeas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'This supervisor hasn\'t posted any project ideas yet.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            for (final idea in profile.projectIdeas)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ProjectIdeaCard(idea: idea),
              ),
        ],
      ),
    );
  }
}
