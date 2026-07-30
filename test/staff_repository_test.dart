import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_supervisor_finder/models/project_idea.dart';
import 'package:fyp_supervisor_finder/repositories/staff_repository.dart';

void main() {
  group('MemoryStaffRepository', () {
    late MemoryStaffRepository repository;

    setUp(() {
      repository = MemoryStaffRepository();
    });

    test('fetchOrCreateProfile creates an empty profile the first time', () async {
      final profile = await repository.fetchOrCreateProfile(
        uid: 'staff-1',
        name: 'Dr. Amara Okafor',
        email: 'amara@example.com',
      );

      expect(profile.name, 'Dr. Amara Okafor');
      expect(profile.areasOfInterest, isEmpty);
      expect(profile.projectIdeas, isEmpty);
    });

    test('areas of interest can be added and removed', () async {
      await repository.fetchOrCreateProfile(
        uid: 'staff-1',
        name: 'Dr. Amara Okafor',
        email: 'amara@example.com',
      );

      await repository.addAreaOfInterest(uid: 'staff-1', area: 'Graph theory');
      await repository.addAreaOfInterest(uid: 'staff-1', area: 'Data analysis');

      var profiles = await repository.fetchAllProfiles();
      expect(profiles.single.areasOfInterest, ['Graph theory', 'Data analysis']);

      await repository.removeAreaOfInterest(uid: 'staff-1', area: 'Graph theory');

      profiles = await repository.fetchAllProfiles();
      expect(profiles.single.areasOfInterest, ['Data analysis']);
    });

    test('project ideas can be added, updated, and deleted', () async {
      await repository.fetchOrCreateProfile(
        uid: 'staff-1',
        name: 'Dr. Amara Okafor',
        email: 'amara@example.com',
      );

      await repository.addProjectIdea(
        uid: 'staff-1',
        idea: const ProjectIdea(
          id: '',
          title: 'Graph colouring heuristics',
          description: 'Compare heuristics for the graph colouring problem.',
        ),
      );

      var profiles = await repository.fetchAllProfiles();
      final idea = profiles.single.projectIdeas.single;
      expect(idea.title, 'Graph colouring heuristics');

      await repository.updateProjectIdea(
        uid: 'staff-1',
        idea: idea.copyWith(title: 'Graph colouring heuristics (updated)'),
      );

      profiles = await repository.fetchAllProfiles();
      expect(
        profiles.single.projectIdeas.single.title,
        'Graph colouring heuristics (updated)',
      );

      await repository.deleteProjectIdea(uid: 'staff-1', ideaId: idea.id);

      profiles = await repository.fetchAllProfiles();
      expect(profiles.single.projectIdeas, isEmpty);
    });
  });
}
