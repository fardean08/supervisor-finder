import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_supervisor_finder/models/app_user.dart';
import 'package:fyp_supervisor_finder/models/project_idea.dart';
import 'package:fyp_supervisor_finder/models/staff_profile.dart';
import 'package:fyp_supervisor_finder/repositories/request_repository.dart';
import 'package:fyp_supervisor_finder/repositories/staff_repository.dart';
import 'package:fyp_supervisor_finder/screens/staff_profile_detail_screen.dart';

void main() {
  const student = AppUser(
    uid: 'student-1',
    email: 'student@example.com',
    name: 'Student One',
    role: UserRole.student,
  );

  const profile = StaffProfile(
    uid: 'staff-1',
    name: 'Dr. Amara Okafor',
    email: 'amara@example.com',
    department: 'Computer Science',
    bio: 'Works on distributed systems and graph algorithms.',
    areasOfInterest: ['Graph theory', 'Distributed systems'],
    projectIdeas: [
      ProjectIdea(id: 'idea-1', title: 'Graph colouring heuristics', description: 'desc', area: 'Graph theory'),
    ],
  );

  testWidgets('renders bio, areas, and project ideas', (tester) async {
    final staffRepository = MemoryStaffRepository();
    final requestRepository = MemoryRequestRepository(staffRepository: staffRepository);

    await tester.pumpWidget(MaterialApp(
      home: StaffProfileDetailScreen(
        profile: profile,
        currentUser: student,
        requestRepository: requestRepository,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Computer Science'), findsOneWidget);
    expect(find.text('Works on distributed systems and graph algorithms.'), findsOneWidget);
    expect(find.text('Graph theory'), findsWidgets);
    expect(find.text('Graph colouring heuristics'), findsOneWidget);
  });

  testWidgets('sending a request shows a confirmation snackbar', (tester) async {
    final staffRepository = MemoryStaffRepository();
    final requestRepository = MemoryRequestRepository(staffRepository: staffRepository);
    await staffRepository.fetchOrCreateProfile(uid: 'staff-1', name: 'Dr. Amara Okafor', email: 'amara@example.com');

    await tester.pumpWidget(MaterialApp(
      home: StaffProfileDetailScreen(
        profile: profile,
        currentUser: student,
        requestRepository: requestRepository,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('Request sent'), findsOneWidget);
    final requests = await requestRepository.fetchRequestsForStudent('student-1');
    expect(requests.single.staffId, 'staff-1');
    expect(requests.single.ideaId, 'idea-1');
  });

  testWidgets('fully booked hides the request button and shows a banner', (tester) async {
    final staffRepository = MemoryStaffRepository();
    final requestRepository = MemoryRequestRepository(staffRepository: staffRepository);

    await tester.pumpWidget(MaterialApp(
      home: StaffProfileDetailScreen(
        profile: profile,
        currentUser: student,
        requestRepository: requestRepository,
        isFullyBooked: true,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.send), findsNothing);
    expect(find.textContaining('fully booked'), findsOneWidget);
  });

  testWidgets('shows an empty state when the supervisor has no project ideas', (tester) async {
    final staffRepository = MemoryStaffRepository();
    final requestRepository = MemoryRequestRepository(staffRepository: staffRepository);
    const emptyProfile = StaffProfile(
      uid: 'staff-2',
      name: 'Dr. No Ideas',
      email: 'noideas@example.com',
      department: '',
      bio: '',
      areasOfInterest: [],
      projectIdeas: [],
    );

    await tester.pumpWidget(MaterialApp(
      home: StaffProfileDetailScreen(
        profile: emptyProfile,
        currentUser: student,
        requestRepository: requestRepository,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('hasn\'t posted any project ideas yet'), findsOneWidget);
  });
}
