import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_supervisor_finder/models/app_user.dart';
import 'package:fyp_supervisor_finder/repositories/request_repository.dart';
import 'package:fyp_supervisor_finder/repositories/staff_repository.dart';
import 'package:fyp_supervisor_finder/repositories/user_repository.dart';
import 'package:fyp_supervisor_finder/screens/admin_dashboard_screen.dart';
import 'package:fyp_supervisor_finder/services/auth_service.dart';
import 'package:fyp_supervisor_finder/theme/theme_controller.dart';

void main() {
  testWidgets('overview tab reports staff, student and request counts', (tester) async {
    final staffRepository = MemoryStaffRepository();
    final requestRepository = MemoryRequestRepository(staffRepository: staffRepository);
    final userRepository = MemoryUserRepository();
    final authService = LocalAuthService(onUserChanged: userRepository.upsert);

    await staffRepository.fetchOrCreateProfile(
      uid: 'staff-1',
      name: 'Dr. One',
      email: 'one@example.com',
    );
    await authService.signUp(
      name: 'Student One',
      email: 'student1@example.com',
      password: 'password1',
      role: UserRole.student,
    );
    await requestRepository.createRequest(
      studentId: 'student1@example.com',
      staffId: 'staff-1',
      ideaId: 'idea-1',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AdminDashboardScreen(
          authService: authService,
          staffRepository: staffRepository,
          requestRepository: requestRepository,
          userRepository: userRepository,
          themeController: ThemeController(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1'), findsNWidgets(3)); // staff, students, total requests

    final staffTab = find.descendant(of: find.byType(TabBar), matching: find.text('Staff'));
    final studentsTab = find.descendant(of: find.byType(TabBar), matching: find.text('Students'));
    expect(staffTab, findsOneWidget);
    expect(studentsTab, findsOneWidget);

    await tester.tap(staffTab);
    await tester.pumpAndSettle();
    expect(find.text('Dr. One'), findsOneWidget);

    await tester.tap(studentsTab);
    await tester.pumpAndSettle();
    expect(find.text('Student One'), findsOneWidget);
  });
}
