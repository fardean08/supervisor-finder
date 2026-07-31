import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_supervisor_finder/models/app_user.dart';
import 'package:fyp_supervisor_finder/models/request.dart';
import 'package:fyp_supervisor_finder/repositories/request_repository.dart';
import 'package:fyp_supervisor_finder/repositories/staff_repository.dart';
import 'package:fyp_supervisor_finder/screens/staff_dashboard_screen.dart';
import 'package:fyp_supervisor_finder/services/auth_service.dart';
import 'package:fyp_supervisor_finder/theme/theme_controller.dart';

void main() {
  const staffUser = AppUser(
    uid: 'staff-1',
    email: 'staff@example.com',
    name: 'Dr. Staff',
    role: UserRole.staff,
  );

  late MemoryStaffRepository staffRepository;
  late MemoryRequestRepository requestRepository;

  setUp(() {
    staffRepository = MemoryStaffRepository();
    requestRepository = MemoryRequestRepository(staffRepository: staffRepository);
  });

  Future<void> pumpDashboard(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: StaffDashboardScreen(
          user: staffUser,
          authService: LocalAuthService(),
          repository: staffRepository,
          requestRepository: requestRepository,
          firebaseReady: false,
          themeController: ThemeController(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('adding and removing an area of interest updates the profile', (tester) async {
    await pumpDashboard(tester);

    await tester.tap(find.text('Add area'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Distributed systems');
    await tester.tap(find.text('Add').last);
    await tester.pumpAndSettle();

    expect(find.text('Distributed systems'), findsOneWidget);
    expect(await staffRepository.fetchProfile('staff-1').then((p) => p!.areasOfInterest),
        contains('Distributed systems'));

    // The delete icon's hit target is small and chip rendering details are
    // an implementation detail we don't want this test tied to — invoke
    // the same callback InputChip's delete icon would trigger.
    final chip = tester.widget<InputChip>(find.widgetWithText(InputChip, 'Distributed systems'));
    chip.onDeleted!();
    await tester.pumpAndSettle();

    expect(find.text('Distributed systems'), findsNothing);
    final profile = await staffRepository.fetchProfile('staff-1');
    expect(profile!.areasOfInterest, isNot(contains('Distributed systems')));
  });

  testWidgets('adding, editing, and deleting a project idea', (tester) async {
    await pumpDashboard(tester);

    await tester.tap(find.text('Add idea'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Title'), 'Graph colouring');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Description'),
      'Compare heuristics for graph colouring.',
    );
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Graph colouring'), findsOneWidget);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Title'), 'Graph colouring (updated)');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Graph colouring (updated)'), findsOneWidget);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Graph colouring (updated)'), findsNothing);
    expect(find.text('No project ideas yet.'), findsOneWidget);
  });

  testWidgets('accepting a request auto-declines competing requests for the same idea',
      (tester) async {
    await staffRepository.fetchOrCreateProfile(uid: 'staff-1', name: 'Dr. Staff', email: 'staff@example.com');
    final r1 = await requestRepository.createRequest(
      studentId: 'student-1',
      staffId: 'staff-1',
      ideaId: 'idea-1',
    );
    await requestRepository.createRequest(
      studentId: 'student-2',
      staffId: 'staff-1',
      ideaId: 'idea-1',
    );

    await pumpDashboard(tester);

    expect(find.text('2'), findsOneWidget); // pending-count badge

    // Tap the mail icon itself rather than the tooltip-derived center — the
    // unread-count badge sits in a Stack on top of part of the icon button
    // and can otherwise steal the hit test.
    await tester.tap(find.byIcon(Icons.mail_outline));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check).first);
    await tester.pumpAndSettle();

    final all = await requestRepository.fetchRequestsForStaff('staff-1');
    final accepted = all.firstWhere((r) => r.id == r1.id);
    final other = all.firstWhere((r) => r.id != r1.id);
    expect(accepted.status, RequestStatus.accepted);
    expect(other.status, RequestStatus.declined);
  });

  testWidgets('cannot accept past capacity — shows an error and leaves it pending', (tester) async {
    await staffRepository.fetchOrCreateProfile(uid: 'staff-1', name: 'Dr. Staff', email: 'staff@example.com');
    await staffRepository.updateProfileDetails(
      uid: 'staff-1',
      department: '',
      bio: '',
      maxStudents: 1,
    );
    final already = await requestRepository.createRequest(
      studentId: 'student-1',
      staffId: 'staff-1',
      ideaId: 'idea-1',
    );
    await requestRepository.updateRequestStatus(requestId: already.id, status: RequestStatus.accepted);
    final second = await requestRepository.createRequest(
      studentId: 'student-2',
      staffId: 'staff-1',
      ideaId: 'idea-2',
    );

    await pumpDashboard(tester);

    // Tap the mail icon itself rather than the tooltip-derived center — the
    // unread-count badge sits in a Stack on top of part of the icon button
    // and can otherwise steal the hit test.
    await tester.tap(find.byIcon(Icons.mail_outline));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(find.textContaining('already supervising 1 student'), findsOneWidget);
    final refreshed = await requestRepository.fetchRequestsForStaff('staff-1');
    expect(refreshed.firstWhere((r) => r.id == second.id).status, RequestStatus.pending);
  });
}
