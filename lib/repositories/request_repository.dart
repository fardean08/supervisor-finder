import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/request.dart';
import '../repositories/staff_repository.dart';

/// Thrown by [RequestRepository.createRequest] when the target staff member
/// has already reached their maximum number of accepted students.
class SupervisorFullyBookedException implements Exception {
  const SupervisorFullyBookedException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class RequestRepository {
  /// Creates a pending request, unless the staff member is already at
  /// capacity (see [StaffProfile.maxStudents]), in which case a
  /// [SupervisorFullyBookedException] is thrown and no request is created.
  Future<ProjectRequest> createRequest({
    required String studentId,
    required String staffId,
    required String ideaId,
  });

  Future<List<ProjectRequest>> fetchRequestsForStaff(String staffId);

  Future<List<ProjectRequest>> fetchRequestsForStudent(String studentId);

  /// All requests across every staff member and student. Used to compute
  /// capacity/"fully booked" status and for the admin dashboard.
  Future<List<ProjectRequest>> fetchAllRequests();

  Future<void> updateRequestStatus({
    required String requestId,
    required RequestStatus status,
  });
}

class FirestoreRequestRepository implements RequestRepository {
  FirestoreRequestRepository({
    required this.staffRepository,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final StaffRepository staffRepository;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('projectRequests');

  Future<void> _ensureCapacity(String staffId) async {
    final profile = await staffRepository.fetchProfile(staffId);
    if (profile == null) return;

    final existing = await fetchRequestsForStaff(staffId);
    final acceptedCount =
        existing.where((r) => r.status == RequestStatus.accepted).length;

    if (acceptedCount >= profile.maxStudents) {
      throw SupervisorFullyBookedException(
        '${profile.name} is fully booked and cannot accept new requests.',
      );
    }
  }

  @override
  Future<ProjectRequest> createRequest({
    required String studentId,
    required String staffId,
    required String ideaId,
  }) async {
    await _ensureCapacity(staffId);

    final doc = await _requests.add({
      'studentId': studentId,
      'staffId': staffId,
      'ideaId': ideaId,
      'status': RequestStatus.pending.name,
      'createdAt': DateTime.now().toIso8601String(),
    });

    final snapshot = await doc.get();
    return ProjectRequest.fromMap(doc.id, snapshot.data() ?? {});
  }

  @override
  Future<List<ProjectRequest>> fetchRequestsForStaff(String staffId) async {
    final snap = await _requests.where('staffId', isEqualTo: staffId).get();
    return snap.docs
        .map((d) => ProjectRequest.fromMap(d.id, d.data()))
        .toList();
  }

  @override
  Future<List<ProjectRequest>> fetchRequestsForStudent(String studentId) async {
    final snap = await _requests.where('studentId', isEqualTo: studentId).get();
    return snap.docs
        .map((d) => ProjectRequest.fromMap(d.id, d.data()))
        .toList();
  }

  @override
  Future<List<ProjectRequest>> fetchAllRequests() async {
    final snap = await _requests.get();
    return snap.docs
        .map((d) => ProjectRequest.fromMap(d.id, d.data()))
        .toList();
  }

  @override
  Future<void> updateRequestStatus({
    required String requestId,
    required RequestStatus status,
  }) async {
    await _requests.doc(requestId).update({'status': status.name});
  }
}

class MemoryRequestRepository implements RequestRepository {
  MemoryRequestRepository({required this.staffRepository});

  final StaffRepository staffRepository;
  final Map<String, ProjectRequest> _store = {};
  int _next = 1;

  Future<void> _ensureCapacity(String staffId) async {
    final profile = await staffRepository.fetchProfile(staffId);
    if (profile == null) return;

    final acceptedCount = _store.values
        .where((r) => r.staffId == staffId && r.status == RequestStatus.accepted)
        .length;

    if (acceptedCount >= profile.maxStudents) {
      throw SupervisorFullyBookedException(
        '${profile.name} is fully booked and cannot accept new requests.',
      );
    }
  }

  @override
  Future<ProjectRequest> createRequest({
    required String studentId,
    required String staffId,
    required String ideaId,
  }) async {
    await _ensureCapacity(staffId);

    final id = 'req-${_next++}';
    final req = ProjectRequest(
      id: id,
      studentId: studentId,
      staffId: staffId,
      ideaId: ideaId,
      status: RequestStatus.pending,
      createdAt: DateTime.now(),
    );
    _store[id] = req;
    return req;
  }

  @override
  Future<List<ProjectRequest>> fetchRequestsForStaff(String staffId) async {
    return _store.values.where((r) => r.staffId == staffId).toList();
  }

  @override
  Future<List<ProjectRequest>> fetchRequestsForStudent(String studentId) async {
    return _store.values.where((r) => r.studentId == studentId).toList();
  }

  @override
  Future<List<ProjectRequest>> fetchAllRequests() async {
    return List<ProjectRequest>.from(_store.values);
  }

  @override
  Future<void> updateRequestStatus({
    required String requestId,
    required RequestStatus status,
  }) async {
    final r = _store[requestId];
    if (r == null) return;
    _store[requestId] = r.copyWith(status: status);
  }
}
