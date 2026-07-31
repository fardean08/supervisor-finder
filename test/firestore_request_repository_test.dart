import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fyp_supervisor_finder/models/request.dart';
import 'package:fyp_supervisor_finder/repositories/request_repository.dart';
import 'package:fyp_supervisor_finder/repositories/staff_repository.dart';

// Exercises FirestoreRequestRepository directly (not the in-memory
// fallback), including the capacity rule (FR2, FR9) that is the system's
// most central business rule (see Chapter 4, 4.1).
void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreStaffRepository staffRepo;
  late FirestoreRequestRepository requestRepo;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    staffRepo = FirestoreStaffRepository(firestore: firestore);
    requestRepo = FirestoreRequestRepository(staffRepository: staffRepo, firestore: firestore);

    await staffRepo.fetchOrCreateProfile(uid: 'staff-uid', name: 'Dr Alice Chen', email: 'alice.chen@example.ac.uk');
  });

  test('createRequest succeeds while the supervisor is under capacity', () async {
    await staffRepo.updateProfileDetails(uid: 'staff-uid', department: 'CS', bio: 'x', maxStudents: 3);

    final request = await requestRepo.createRequest(studentId: 'student-1', staffId: 'staff-uid', ideaId: 'idea-1');

    expect(request.status, RequestStatus.pending);
    expect(request.staffId, 'staff-uid');
    expect(request.studentId, 'student-1');
  });

  test('createRequest throws SupervisorFullyBookedException once accepted requests reach maxStudents', () async {
    await staffRepo.updateProfileDetails(uid: 'staff-uid', department: 'CS', bio: 'x', maxStudents: 1);

    final first = await requestRepo.createRequest(studentId: 'student-1', staffId: 'staff-uid', ideaId: 'idea-1');
    await requestRepo.updateRequestStatus(requestId: first.id, status: RequestStatus.accepted);

    expect(
      () => requestRepo.createRequest(studentId: 'student-2', staffId: 'staff-uid', ideaId: 'idea-2'),
      throwsA(isA<SupervisorFullyBookedException>()),
    );
  });

  test('a pending (not yet accepted) request does not count against capacity', () async {
    await staffRepo.updateProfileDetails(uid: 'staff-uid', department: 'CS', bio: 'x', maxStudents: 1);

    await requestRepo.createRequest(studentId: 'student-1', staffId: 'staff-uid', ideaId: 'idea-1');
    // First request is still pending, not accepted, so a second should succeed.
    final second = await requestRepo.createRequest(studentId: 'student-2', staffId: 'staff-uid', ideaId: 'idea-2');

    expect(second.status, RequestStatus.pending);
  });

  test('updateRequestStatus changes a request from pending to accepted', () async {
    final request = await requestRepo.createRequest(studentId: 'student-1', staffId: 'staff-uid', ideaId: 'idea-1');

    await requestRepo.updateRequestStatus(requestId: request.id, status: RequestStatus.accepted);

    final staffRequests = await requestRepo.fetchRequestsForStaff('staff-uid');
    expect(staffRequests.single.status, RequestStatus.accepted);
  });

  test('fetchRequestsForStaff and fetchRequestsForStudent each return only their own scoped requests (NFR4)', () async {
    await staffRepo.fetchOrCreateProfile(uid: 'staff-2-uid', name: 'Dr Robert Osei', email: 'robert.osei@example.ac.uk');

    await requestRepo.createRequest(studentId: 'student-1', staffId: 'staff-uid', ideaId: 'idea-1');
    await requestRepo.createRequest(studentId: 'student-2', staffId: 'staff-2-uid', ideaId: 'idea-2');

    final forStaff1 = await requestRepo.fetchRequestsForStaff('staff-uid');
    final forStudent1 = await requestRepo.fetchRequestsForStudent('student-1');

    expect(forStaff1, hasLength(1));
    expect(forStaff1.single.staffId, 'staff-uid');
    expect(forStudent1, hasLength(1));
    expect(forStudent1.single.studentId, 'student-1');
  });

  test('fetchAllRequests returns every request across all staff and students (used by UC5 overview)', () async {
    await requestRepo.createRequest(studentId: 'student-1', staffId: 'staff-uid', ideaId: 'idea-1');
    await requestRepo.createRequest(studentId: 'student-2', staffId: 'staff-uid', ideaId: 'idea-2');

    final all = await requestRepo.fetchAllRequests();

    expect(all, hasLength(2));
  });
}
