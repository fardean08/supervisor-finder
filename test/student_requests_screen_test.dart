import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_supervisor_finder/models/project_idea.dart';
import 'package:fyp_supervisor_finder/models/request.dart';
import 'package:fyp_supervisor_finder/repositories/request_repository.dart';
import 'package:fyp_supervisor_finder/repositories/staff_repository.dart';
import 'package:fyp_supervisor_finder/screens/student_requests_screen.dart';

void main() {
  late MemoryStaffRepository staffRepository;
  late MemoryRequestRepository requestRepository;

  setUp(() {
    staffRepository = MemoryStaffRepository();
    requestRepository = MemoryRequestRepository(staffRepository: staffRepository);
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StudentRequestsScreen(
          studentId: 'student-1',
          staffRepository: staffRepository,
          requestRepository: requestRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows an empty state with no requests', (tester) async {
    await pumpScreen(tester);
    expect(find.textContaining('haven\'t requested any projects yet'), findsOneWidget);
  });

  testWidgets('groups requests by status with staff/idea names resolved', (tester) async {
    final profile = await staffRepository.fetchOrCreateProfile(
      uid: 'staff-1',
      name: 'Dr. Amara Okafor',
      email: 'amara@example.com',
    );
    await staffRepository.addProjectIdea(
      uid: 'staff-1',
      idea: const ProjectIdea(id: '', title: 'Graph colouring', description: 'd'),
    );
    await staffRepository.addProjectIdea(
      uid: 'staff-1',
      idea: const ProjectIdea(id: '', title: 'Route optimisation', description: 'd'),
    );
    final ideas = (await staffRepository.fetchProfile('staff-1'))!.projectIdeas;
    expect(ideas.length, 2);

    await requestRepository.createRequest(
      studentId: 'student-1',
      staffId: 'staff-1',
      ideaId: ideas[0].id,
    );
    final accepted = await requestRepository.createRequest(
      studentId: 'student-1',
      staffId: 'staff-1',
      ideaId: ideas[1].id,
    );
    await requestRepository.updateRequestStatus(requestId: accepted.id, status: RequestStatus.accepted);
    // A third request for the same idea, declined once the other got accepted.
    final declined = await requestRepository.createRequest(
      studentId: 'student-1',
      staffId: 'staff-1',
      ideaId: ideas[0].id,
    );
    await requestRepository.updateRequestStatus(requestId: declined.id, status: RequestStatus.declined);

    await pumpScreen(tester);

    expect(find.textContaining('Pending (1)'), findsOneWidget);
    expect(find.textContaining('Accepted (1)'), findsOneWidget);
    expect(find.textContaining('Declined (1)'), findsOneWidget);
    expect(find.text('Graph colouring'), findsNWidgets(2)); // pending + declined
    expect(find.text('Route optimisation'), findsOneWidget);
    expect(find.text(profile.name), findsNWidgets(3));
  });
}
