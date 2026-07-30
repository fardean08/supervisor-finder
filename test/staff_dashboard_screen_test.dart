import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_supervisor_finder/models/app_user.dart';
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

  Future<void> pumpDashboard(
    WidgetTester tester, {
    required MemoryStaffRepository staffRepository,
    required MemoryRequestRepository requestRepository,
  }) async {
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

  testWidgets('shows 0% complete for a brand-new profile', (tester) async {
    final staffRepository = MemoryStaffRepository();
    final requestRepository = MemoryRequestRepository(staffRepository: staffRepository);

    await pumpDashboard(tester, staffRepository: staffRepository, requestRepository: requestRepository);

    expect(find.textContaining('0% complete'), findsOneWidget);
  });

  testWidgets('capacity stepper increases max students and saves it', (tester) async {
    final staffRepository = MemoryStaffRepository();
    final requestRepository = MemoryRequestRepository(staffRepository: staffRepository);

    await pumpDashboard(tester, staffRepository: staffRepository, requestRepository: requestRepository);

    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('4'), findsOneWidget);

    await tester.ensureVisible(find.text('Save details'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save details'));
    await tester.pumpAndSettle();

    final saved = await staffRepository.fetchProfile('staff-1');
    expect(saved?.maxStudents, 4);
  });
}
