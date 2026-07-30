import 'package:flutter/material.dart';

import '../models/staff_profile.dart';

class StaffSummaryCard extends StatelessWidget {
  const StaffSummaryCard({
    super.key,
    required this.profile,
    required this.onTap,
    this.sharedInterestCount = 0,
    this.isFullyBooked = false,
  });

  final StaffProfile profile;
  final VoidCallback onTap;

  /// Number of the current student's interests that overlap with this
  /// staff member's areas of interest. 0 hides the match badge.
  final int sharedInterestCount;

  final bool isFullyBooked;

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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            profile.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (isFullyBooked)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBE9E7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Fully booked',
                              style: TextStyle(fontSize: 11, color: Color(0xFFB3261E)),
                            ),
                          ),
                      ],
                    ),
                    if (profile.department.isNotEmpty)
                      Text(
                        profile.department,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    if (sharedInterestCount > 0) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F3E6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 12, color: Color(0xFF2E7D32)),
                            const SizedBox(width: 4),
                            Text(
                              '$sharedInterestCount shared interest${sharedInterestCount == 1 ? '' : 's'}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF2E7D32)),
                            ),
                          ],
                        ),
                      ),
                    ],
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
