import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_supervisor_finder/models/app_user.dart';
import 'package:fyp_supervisor_finder/models/project_idea.dart';
import 'package:fyp_supervisor_finder/models/request.dart';
import 'package:fyp_supervisor_finder/repositories/request_repository.dart';
import 'package:fyp_supervisor_finder/repositories/staff_repository.dart';
import 'package:fyp_supervisor_finder/screens/student_browse_screen.dart';
import 'package:fyp_supervisor_finder/services/auth_service.dart';
import 'package:fyp_supervisor_finder/theme/theme_controller.dart';

void main() {
  late MemoryStaffRepository staffRepository;
  late MemoryRequestRepository requestRepository;
  late LocalAuthService authService;
  late ThemeController themeController;

  const student = AppUser(
    uid: 'student-1',
    email: 'student@example.com',
    name: 'Student One',
    role: UserRole.student,
    interests: ['Graph theory', 'Machine learning'],
  );

  setUp(() async {
    staffRepository = MemoryStaffRepository();
    requestRepository = MemoryRequestRepository(staffRepository: staffRepository);
    authService = LocalAuthService();
    themeController = ThemeController();

    // Matching supervisor: shares 2 interests with the student.
    await staffRepository.fetchOrCreateProfile(
      uid: 'staff-match',
      name: 'Dr. Match',
      email: 'match@example.com',
    );
    await staffRepository.addAreaOfInterest(uid: 'staff-match', area: 'Graph theory');
    await staffRepository.addAreaOfInterest(uid: 'staff-match', area: 'Machine learning');
    await staffRepository.addProjectIdea(
      uid: 'staff-match',
      idea: const ProjectIdea(id: '', title: 'Matching idea', description: 'desc'),
    );

    // Non-matching, fully booked supervisor: capacity 1, already has 1 accepted.
    await staffRepository.fetchOrCreateProfile(
      uid: 'staff-full',
      name: 'Dr. Full',
      email: 'full@example.com',
    );
    await staffRepository.addAreaOfInterest(uid: 'staff-full', area: 'Databases');
    await staffRepository.updateProfileDetails(
      uid: 'staff-full',
      department: 'CS',
      bio: '',
      maxStudents: 1,
    );

    final req = await requestRepository.createRequest(
      studentId: 'other-student',
      staffId: 'staff-full',
      ideaId: 'idea-x',
    );
    await requestRepository.updateRequestStatus(requestId: req.id, status: RequestStatus.accepted);
  });

  Future<void> pumpBrowseScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StudentBrowseScreen(
          user: student,
          authService: authService,
          repository: staffRepository,
          requestRepository: requestRepository,
          firebaseReady: false,
          themeController: themeController,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('dark mode toggle switches ThemeMode and updates the icon', (tester) async {
    await pumpBrowseScreen(tester);

    expect(themeController.value, ThemeMode.light);
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.dark_mode_outlined));
    await tester.pumpAndSettle();

    expect(themeController.value, ThemeMode.dark);
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.light_mode_outlined));
    await tester.pumpAndSettle();

    expect(themeController.value, ThemeMode.light);
  });

  testWidgets('ranks matching supervisor first and shows shared interest badge', (tester) async {
    await pumpBrowseScreen(tester);

    expect(find.text('Dr. Match'), findsOneWidget);
    expect(find.text('Dr. Full'), findsOneWidget);
    expect(find.textContaining('2 shared interests'), findsOneWidget);

    // Matching profile should appear before the non-matching one.
    final matchOffset = tester.getTopLeft(find.text('Dr. Match'));
    final fullOffset = tester.getTopLeft(find.text('Dr. Full'));
    expect(matchOffset.dy, lessThan(fullOffset.dy));
  });

  testWidgets('shows Fully booked badge once a supervisor is at capacity', (tester) async {
    await pumpBrowseScreen(tester);

    expect(find.text('Fully booked'), findsOneWidget);
  });

  testWidgets('filter chips narrow the list to the selected area', (tester) async {
    await pumpBrowseScreen(tester);

    expect(find.text('Dr. Match'), findsOneWidget);
    expect(find.text('Dr. Full'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'Databases'));
    await tester.pumpAndSettle();

    expect(find.text('Dr. Full'), findsOneWidget);
    expect(find.text('Dr. Match'), findsNothing);
  });

  testWidgets('blocks a request to a fully booked supervisor with a clear message', (tester) async {
    await pumpBrowseScreen(tester);

    await tester.tap(find.text('Dr. Full'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('fully booked and isn\'t accepting new requests'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.send), findsNothing);
  });
}
