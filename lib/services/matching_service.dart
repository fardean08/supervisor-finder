import '../models/staff_profile.dart';

/// Simple, deterministic matching logic between a student's areas of
/// interest and a staff member's areas of interest. Matching is
/// case-insensitive and trims whitespace, but otherwise does no fuzzy
/// matching so results stay predictable.
class MatchingService {
  const MatchingService();

  /// Interests both lists have in common, in the staff member's original
  /// casing (so the badge shows "Graph Theory" the way the supervisor
  /// wrote it, not however the student happened to type it). Comparison
  /// is case-insensitive; `seen` just guards against a student somehow
  /// having the same interest listed twice from double-counting a match.
  List<String> sharedInterests(
    List<String> studentInterests,
    List<String> staffAreas,
  ) {
    final normalizedStaffAreas = {
      for (final area in staffAreas) area.trim().toLowerCase(): area,
    };

    final shared = <String>[];
    final seen = <String>{};

    for (final interest in studentInterests) {
      final key = interest.trim().toLowerCase();
      if (key.isEmpty || seen.contains(key)) continue;

      final match = normalizedStaffAreas[key];
      if (match != null) {
        shared.add(match);
        seen.add(key);
      }
    }

    return shared;
  }

  int sharedInterestCount(List<String> studentInterests, List<String> staffAreas) {
    return sharedInterests(studentInterests, staffAreas).length;
  }

  /// Ranks [profiles] by number of shared interests with [studentInterests],
  /// highest overlap first. Ties are broken alphabetically by name so the
  /// ordering is stable and deterministic.
  List<StaffProfile> rankByInterest(
    List<StaffProfile> profiles,
    List<String> studentInterests,
  ) {
    final ranked = [...profiles];
    ranked.sort((a, b) {
      final scoreA = sharedInterestCount(studentInterests, a.areasOfInterest);
      final scoreB = sharedInterestCount(studentInterests, b.areasOfInterest);
      if (scoreA != scoreB) return scoreB.compareTo(scoreA);
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return ranked;
  }
}
