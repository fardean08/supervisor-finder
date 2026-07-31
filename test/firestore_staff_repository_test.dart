import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fyp_supervisor_finder/models/project_idea.dart';
import 'package:fyp_supervisor_finder/repositories/staff_repository.dart';

// These tests exercise FirestoreStaffRepository itself (not the in-memory
// fallback), using fake_cloud_firestore's in-memory fake of the Firestore
// API surface. This closes the gap where only the Memory* implementation
// was previously covered by automated tests.
void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreStaffRepository repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = FirestoreStaffRepository(firestore: firestore);
  });

  test('fetchOrCreateProfile creates an empty profile the first time', () async {
    final profile = await repo.fetchOrCreateProfile(
      uid: 'alice-uid',
      name: 'Dr Alice Chen',
      email: 'alice.chen@example.ac.uk',
    );

    expect(profile.uid, 'alice-uid');
    expect(profile.name, 'Dr Alice Chen');
    expect(profile.department, '');
    expect(profile.areasOfInterest, isEmpty);
    expect(profile.maxStudents, 3); // FR2: default capacity
  });

  test('fetchOrCreateProfile returns the existing profile on a second call, not a new empty one', () async {
    await repo.fetchOrCreateProfile(uid: 'alice-uid', name: 'Dr Alice Chen', email: 'alice.chen@example.ac.uk');
    await repo.updateProfileDetails(uid: 'alice-uid', department: 'Computer Science', bio: 'ML researcher', maxStudents: 5);

    final second = await repo.fetchOrCreateProfile(uid: 'alice-uid', name: 'Dr Alice Chen', email: 'alice.chen@example.ac.uk');

    expect(second.department, 'Computer Science');
    expect(second.maxStudents, 5);
  });

  test('fetchProfile returns null for a uid with no profile document', () async {
    final result = await repo.fetchProfile('nobody-uid');
    expect(result, isNull);
  });

  test('updateProfileDetails persists department, bio, and capacity (FR2)', () async {
    await repo.fetchOrCreateProfile(uid: 'robert-uid', name: 'Dr Robert Osei', email: 'robert.osei@example.ac.uk');
    await repo.updateProfileDetails(uid: 'robert-uid', department: 'Data Science', bio: 'Graphs and networks', maxStudents: 2);

    final profile = await repo.fetchProfile('robert-uid');
    expect(profile!.department, 'Data Science');
    expect(profile.bio, 'Graphs and networks');
    expect(profile.maxStudents, 2);
  });

  test('addAreaOfInterest adds an area, without duplicating it on a repeat call (FR3, NFR5)', () async {
    await repo.fetchOrCreateProfile(uid: 'maria-uid', name: 'Dr Maria Lopez', email: 'maria.lopez@example.ac.uk');

    await repo.addAreaOfInterest(uid: 'maria-uid', area: 'Human-Computer Interaction');
    await repo.addAreaOfInterest(uid: 'maria-uid', area: 'Human-Computer Interaction'); // arrayUnion should de-dupe

    final profile = await repo.fetchProfile('maria-uid');
    expect(profile!.areasOfInterest, ['Human-Computer Interaction']);
  });

  test('removeAreaOfInterest removes exactly the named area', () async {
    await repo.fetchOrCreateProfile(uid: 'maria-uid', name: 'Dr Maria Lopez', email: 'maria.lopez@example.ac.uk');
    await repo.addAreaOfInterest(uid: 'maria-uid', area: 'HCI');
    await repo.addAreaOfInterest(uid: 'maria-uid', area: 'Accessibility');

    await repo.removeAreaOfInterest(uid: 'maria-uid', area: 'HCI');

    final profile = await repo.fetchProfile('maria-uid');
    expect(profile!.areasOfInterest, ['Accessibility']);
  });

  test('addProjectIdea stores the idea in the projectIdeas subcollection, not an embedded array', () async {
    await repo.fetchOrCreateProfile(uid: 'alice-uid', name: 'Dr Alice Chen', email: 'alice.chen@example.ac.uk');
    await repo.addProjectIdea(
      uid: 'alice-uid',
      idea: const ProjectIdea(id: '', title: 'Predicting Readmission', description: 'ML on patient records', area: 'Machine Learning'),
    );

    // Confirm it is genuinely a subcollection at staffProfiles/{uid}/projectIdeas,
    // matching the structure documented in Chapter 2's data design (2.3.4).
    final subcollectionDocs = await firestore.collection('staffProfiles').doc('alice-uid').collection('projectIdeas').get();
    expect(subcollectionDocs.docs, hasLength(1));
    expect(subcollectionDocs.docs.first.data()['title'], 'Predicting Readmission');

    final profile = await repo.fetchProfile('alice-uid');
    expect(profile!.projectIdeas, hasLength(1));
    expect(profile.projectIdeas.first.title, 'Predicting Readmission');
  });

  test('updateProjectIdea edits the correct idea by id', () async {
    await repo.fetchOrCreateProfile(uid: 'alice-uid', name: 'Dr Alice Chen', email: 'alice.chen@example.ac.uk');
    await repo.addProjectIdea(uid: 'alice-uid', idea: const ProjectIdea(id: '', title: 'Original title', description: 'x'));

    final created = (await repo.fetchProfile('alice-uid'))!.projectIdeas.first;
    await repo.updateProjectIdea(uid: 'alice-uid', idea: created.copyWith(title: 'Updated title'));

    final profile = await repo.fetchProfile('alice-uid');
    expect(profile!.projectIdeas.first.title, 'Updated title');
  });

  test('deleteProjectIdea removes only the targeted idea (UC3)', () async {
    await repo.fetchOrCreateProfile(uid: 'alice-uid', name: 'Dr Alice Chen', email: 'alice.chen@example.ac.uk');
    await repo.addProjectIdea(uid: 'alice-uid', idea: const ProjectIdea(id: '', title: 'Keep me', description: 'x'));
    await repo.addProjectIdea(uid: 'alice-uid', idea: const ProjectIdea(id: '', title: 'Delete me', description: 'x'));

    final toDelete = (await repo.fetchProfile('alice-uid'))!.projectIdeas.firstWhere((i) => i.title == 'Delete me');
    await repo.deleteProjectIdea(uid: 'alice-uid', ideaId: toDelete.id);

    final profile = await repo.fetchProfile('alice-uid');
    expect(profile!.projectIdeas, hasLength(1));
    expect(profile.projectIdeas.first.title, 'Keep me');
  });

  test('fetchAllProfiles returns every seeded profile with its ideas attached', () async {
    await repo.fetchOrCreateProfile(uid: 'alice-uid', name: 'Dr Alice Chen', email: 'alice.chen@example.ac.uk');
    await repo.fetchOrCreateProfile(uid: 'robert-uid', name: 'Dr Robert Osei', email: 'robert.osei@example.ac.uk');
    await repo.addProjectIdea(uid: 'alice-uid', idea: const ProjectIdea(id: '', title: 'Idea A', description: 'x'));

    final all = await repo.fetchAllProfiles();

    expect(all, hasLength(2));
    final alice = all.firstWhere((p) => p.uid == 'alice-uid');
    expect(alice.projectIdeas, hasLength(1));
  });
}
