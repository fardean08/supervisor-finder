import 'package:flutter/material.dart';

import '../models/staff_profile.dart';

class StaffSummaryCard extends StatelessWidget {
  const StaffSummaryCard({
    super.key,
    required this.profile,
    required this.onTap,
  });

  final StaffProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    Text(profile.name, style: Theme.of(context).textTheme.titleMedium),
                    if (profile.department.isNotEmpty)
                      Text(
                        profile.department,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final area in profile.areasOfInterest.take(4))
                          Chip(
                            label: Text(area, style: const TextStyle(fontSize: 12)),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        if (profile.areasOfInterest.length > 4)
                          Text('+${profile.areasOfInterest.length - 4} more'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${profile.projectIdeas.length} project idea${profile.projectIdeas.length == 1 ? '' : 's'}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
