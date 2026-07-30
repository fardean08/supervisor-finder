import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_supervisor_finder/models/request.dart';
import 'package:fyp_supervisor_finder/repositories/request_repository.dart';
import 'package:fyp_supervisor_finder/repositories/staff_repository.dart';

void main() {
  group('MemoryRequestRepository capacity', () {
    late MemoryStaffRepository staffRepository;
    late MemoryRequestRepository requestRepository;

    setUp(() async {
      staffRepository = MemoryStaffRepository();
      requestRepository = MemoryRequestRepository(staffRepository: staffRepository);

      await staffRepository.fetchOrCreateProfile(
        uid: 'staff-1',
        name: 'Dr. Amara Okafor',
        email: 'amara@example.com',
      );
      await staffRepository.updateProfileDetails(
        uid: 'staff-1',
        department: 'Computer Science',
        bio: '',
        maxStudents: 1,
      );
    });

    test('blocks new requests once accepted requests reach maxStudents', () async {
      final first = await requestRepository.createRequest(
        studentId: 'student-1',
        staffId: 'staff-1',
        ideaId: 'idea-1',
      );

      await requestRepository.updateRequestStatus(
        requestId: first.id,
        status: RequestStatus.accepted,
      );

      expect(
        () => requestRepository.createRequest(
          studentId: 'student-2',
          staffId: 'staff-1',
          ideaId: 'idea-1',
        ),
        throwsA(isA<SupervisorFullyBookedException>()),
      );
    });

    test('allows requests while under capacity', () async {
      final request = await requestRepository.createRequest(
        studentId: 'student-1',
        staffId: 'staff-1',
        ideaId: 'idea-1',
      );

      expect(request.status, RequestStatus.pending);
    });
  });
}
