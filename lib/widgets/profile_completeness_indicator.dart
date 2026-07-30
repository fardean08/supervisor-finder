import 'package:flutter/material.dart';

import '../models/staff_profile.dart';

/// Tracks how complete a staff profile is: a non-empty bio, at least one
/// area of interest, and at least one project idea.
class ProfileCompleteness {
  const ProfileCompleteness(this.profile);

  final StaffProfile profile;

  bool get hasBio => profile.bio.trim().isNotEmpty;
  bool get hasAreas => profile.areasOfInterest.isNotEmpty;
  bool get hasIdea => profile.projectIdeas.isNotEmpty;

  int get completedCount => [hasBio, hasAreas, hasIdea].where((done) => done).length;

  double get fraction => completedCount / 3;

  int get percent => (fraction * 100).round();

  bool get isComplete => completedCount == 3;
}

/// Small progress bar + label showing how complete a staff profile is, with
/// a hint about what's still missing.
class ProfileCompletenessIndicator extends StatelessWidget {
  const ProfileCompletenessIndicator({super.key, required this.profile});

  final StaffProfile profile;

  @override
  Widget build(BuildContext context) {
    final completeness = ProfileCompleteness(profile);
    final missing = [
      if (!completeness.hasBio) 'a bio',
      if (!completeness.hasAreas) 'an area of interest',
      if (!completeness.hasIdea) 'a project idea',
    ];

    final color = completeness.isComplete ? const Color(0xFF2E7D32) : const Color(0xFF2E5AAC);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Profile ${completeness.percent}% complete',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
            ),
            const Spacer(),
            if (completeness.isComplete) const Icon(Icons.check_circle, size: 16, color: Color(0xFF2E7D32)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: completeness.fraction,
            minHeight: 8,
            backgroundColor: const Color(0xFFE5E7EB),
            color: color,
          ),
        ),
        if (missing.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Add ${missing.join(', ')} to complete your profile.',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ],
    );
  }
}
