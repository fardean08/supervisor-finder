import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/project_idea.dart';
import '../models/staff_profile.dart';

abstract class StaffRepository {
  /// All staff profiles, for students browsing to find a supervisor.
  Future<List<StaffProfile>> fetchAllProfiles();

  /// Fetches one profile, creating an empty one the first time a staff
  /// member logs in.
  Future<StaffProfile> fetchOrCreateProfile({
    required String uid,
    required String name,
    required String email,
  });

  Future<void> updateProfileDetails({
    required String uid,
    required String department,
    required String bio,
  });

  Future<void> addAreaOfInterest({
    required String uid,
    required String area,
  });

  Future<void> removeAreaOfInterest({
    required String uid,
    required String area,
  });

  Future<void> addProjectIdea({
    required String uid,
    required ProjectIdea idea,
  });

  Future<void> updateProjectIdea({
    required String uid,
    required ProjectIdea idea,
  });

  Future<void> deleteProjectIdea({
    required String uid,
    required String ideaId,
  });
}

class FirestoreStaffRepository implements StaffRepository {
  FirestoreStaffRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _profileDoc(String uid) {
    return _firestore.collection('staffProfiles').doc(uid);
  }

  CollectionReference<Map<String, dynamic>> _ideasCollection(String uid) {
    return _profileDoc(uid).collection('projectIdeas');
  }

  Future<StaffProfile> _readProfile(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final ideasSnapshot = await _ideasCollection(doc.id).get();
    final ideas = ideasSnapshot.docs
        .map((ideaDoc) => ProjectIdea.fromMap(ideaDoc.id, ideaDoc.data()))
        .toList();

    return StaffProfile.fromMap(doc.id, doc.data() ?? const {}, ideas);
  }

  @override
  Future<List<StaffProfile>> fetchAllProfiles() async {
    final snapshot = await _firestore.collection('staffProfiles').get();
    final profiles = <StaffProfile>[];

    for (final doc in snapshot.docs) {
      profiles.add(await _readProfile(doc));
    }

    return profiles;
  }

  @override
  Future<StaffProfile> fetchOrCreateProfile({
    required String uid,
    required String name,
    required String email,
  }) async {
    final doc = await _profileDoc(uid).get();

    if (!doc.exists) {
      final empty = StaffProfile.empty(uid: uid, name: name, email: email);
      await _profileDoc(uid).set(empty.toMap());
      return empty;
    }

    return _readProfile(doc);
  }

  @override
  Future<void> updateProfileDetails({
    required String uid,
    required String department,
    required String bio,
  }) {
    return _profileDoc(uid).update({
      'department': department,
      'bio': bio,
    });
  }

  @override
  Future<void> addAreaOfInterest({
    required String uid,
    required String area,
  }) {
    return _profileDoc(uid).update({
      'areasOfInterest': FieldValue.arrayUnion([area]),
    });
  }

  @override
  Future<void> removeAreaOfInterest({
    required String uid,
    required String area,
  }) {
    return _profileDoc(uid).update({
      'areasOfInterest': FieldValue.arrayRemove([area]),
    });
  }

  @override
  Future<void> addProjectIdea({
    required String uid,
    required ProjectIdea idea,
  }) {
    return _ideasCollection(uid).add(idea.toMap());
  }

  @override
  Future<void> updateProjectIdea({
    required String uid,
    required ProjectIdea idea,
  }) {
    return _ideasCollection(uid).doc(idea.id).update(idea.toMap());
  }

  @override
  Future<void> deleteProjectIdea({
    required String uid,
    required String ideaId,
  }) {
    return _ideasCollection(uid).doc(ideaId).delete();
  }
}

class MemoryStaffRepository implements StaffRepository {
  final Map<String, StaffProfile> _profiles = {};
  int _nextIdeaId = 1;

  @override
  Future<List<StaffProfile>> fetchAllProfiles() async {
    return List<StaffProfile>.from(_profiles.values);
  }

  @override
  Future<StaffProfile> fetchOrCreateProfile({
    required String uid,
    required String name,
    required String email,
  }) async {
    return _profiles.putIfAbsent(
      uid,
      () => StaffProfile.empty(uid: uid, name: name, email: email),
    );
  }

  @override
  Future<void> updateProfileDetails({
    required String uid,
    required String department,
    required String bio,
  }) async {
    final profile = _profiles[uid];
    if (profile == null) return;

    _profiles[uid] = profile.copyWith(department: department, bio: bio);
  }

  @override
  Future<void> addAreaOfInterest({
    required String uid,
    required String area,
  }) async {
    final profile = _profiles[uid];
    if (profile == null) return;

    if (profile.areasOfInterest.contains(area)) return;

    _profiles[uid] = profile.copyWith(
      areasOfInterest: [...profile.areasOfInterest, area],
    );
  }

  @override
  Future<void> removeAreaOfInterest({
    required String uid,
    required String area,
  }) async {
    final profile = _profiles[uid];
    if (profile == null) return;

    _profiles[uid] = profile.copyWith(
      areasOfInterest:
          profile.areasOfInterest.where((item) => item != area).toList(),
    );
  }

  @override
  Future<void> addProjectIdea({
    required String uid,
    required ProjectIdea idea,
  }) async {
    final profile = _profiles[uid];
    if (profile == null) return;

    final id = 'idea-${_nextIdeaId++}';

    _profiles[uid] = profile.copyWith(
      projectIdeas: [...profile.projectIdeas, idea.copyWith(id: id)],
    );
  }

  @override
  Future<void> updateProjectIdea({
    required String uid,
    required ProjectIdea idea,
  }) async {
    final profile = _profiles[uid];
    if (profile == null) return;

    _profiles[uid] = profile.copyWith(
      projectIdeas: [
        for (final existing in profile.projectIdeas)
          if (existing.id == idea.id) idea else existing,
      ],
    );
  }

  @override
  Future<void> deleteProjectIdea({
    required String uid,
    required String ideaId,
  }) async {
    final profile = _profiles[uid];
    if (profile == null) return;

    _profiles[uid] = profile.copyWith(
      projectIdeas:
          profile.projectIdeas.where((idea) => idea.id != ideaId).toList(),
    );
  }
}
