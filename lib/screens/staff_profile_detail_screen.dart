import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/staff_profile.dart';
import '../repositories/request_repository.dart';
import '../widgets/area_chips_editor.dart';
import '../widgets/empty_state.dart';
import '../widgets/project_idea_card.dart';

class StaffProfileDetailScreen extends StatelessWidget {
  const StaffProfileDetailScreen({
    super.key,
    required this.profile,
    required this.currentUser,
    required this.requestRepository,
    this.isFullyBooked = false,
  });

  final StaffProfile profile;
  final AppUser currentUser;
  final dynamic requestRepository;
  final bool isFullyBooked;

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
          if (isFullyBooked) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFBE9E7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.event_busy, size: 18, color: Color(0xFFB3261E)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This supervisor is fully booked and isn\'t accepting new requests.',
                      style: TextStyle(fontSize: 12, color: Color(0xFFB3261E)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text('Project ideas', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (profile.projectIdeas.isEmpty)
            const EmptyState(
              icon: Icons.lightbulb_outline,
              message: 'This supervisor hasn\'t posted any project ideas yet.',
            )
          else
            for (final idea in profile.projectIdeas)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ProjectIdeaCard(
                  idea: idea,
                  onRequest: isFullyBooked
                      ? null
                      : () async {
                          try {
                            await requestRepository.createRequest(
                              studentId: currentUser.uid,
                              staffId: profile.uid,
                              ideaId: idea.id,
                            );

                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Request sent')),
                            );
                          } on SupervisorFullyBookedException catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.message)),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to send request')),
                            );
                          }
                        },
                ),
              ),
        ],
      ),
    );
  }
}
