import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fyp_supervisor_finder/models/app_user.dart';
import 'package:fyp_supervisor_finder/repositories/request_repository.dart';
import 'package:fyp_supervisor_finder/repositories/staff_repository.dart';
import 'package:fyp_supervisor_finder/repositories/user_repository.dart';
import 'package:fyp_supervisor_finder/screens/auth_gate.dart';
import 'package:fyp_supervisor_finder/services/auth_service.dart';
import 'package:fyp_supervisor_finder/theme/theme_controller.dart';

void main() {
  late MemoryStaffRepository staffRepository;
  late MemoryRequestRepository requestRepository;
  late MemoryUserRepository userRepository;
  late LocalAuthService authService;

  setUp(() {
    staffRepository = MemoryStaffRepository();
    requestRepository = MemoryRequestRepository(staffRepository: staffRepository);
    userRepository = MemoryUserRepository();
    authService = LocalAuthService(onUserChanged: userRepository.upsert);
  });

  Future<void> pumpGate(WidgetTester tester) async {
    // The sign-up form is tall (name, role picker, interests editor, email,
    // password); a bigger-than-default viewport means we don't have to
    // scroll to reach fields lower down.
    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: AuthGate(
          authService: authService,
          staffRepository: staffRepository,
          requestRepository: requestRepository,
          userRepository: userRepository,
          themeController: ThemeController(),
          firebaseReady: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('signed out shows the auth screen', (tester) async {
    await pumpGate(tester);
    expect(find.text('FYP Supervisor Finder'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });

  testWidgets('rejects an empty sign-up form with field errors, no navigation', (tester) async {
    await pumpGate(tester);

    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your name'), findsOneWidget);
    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('At least 6 characters'), findsOneWidget);
    // Still on the auth screen.
    expect(find.text('Create an account'), findsOneWidget);
  });

  testWidgets('signing up as a student with interests lands on the browse screen '
      'and the interests carry through', (tester) async {
    await pumpGate(tester);

    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();
    // Student is the default selected segment already.

    await tester.enterText(find.widgetWithText(TextFormField, 'Full name'), 'Ada Student');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'ada@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password1');

    await tester.tap(find.text('Add area'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Machine learning');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('Machine learning'), findsOneWidget);

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    expect(find.text('Find a supervisor'), findsOneWidget);

    // Confirm the interest set at sign-up actually persisted, not just UI state.
    await tester.tap(find.byTooltip('My areas of interest'));
    await tester.pumpAndSettle();
    expect(find.text('Machine learning'), findsOneWidget);
  });

  testWidgets('signing up as staff lands on the staff dashboard', (tester) async {
    await pumpGate(tester);

    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Staff'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Full name'), 'Dr. Staff');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'staff@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password1');

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    expect(find.text('My supervisor profile'), findsOneWidget);
  });

  testWidgets('signing up as admin lands on the coordinator dashboard', (tester) async {
    await pumpGate(tester);

    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Admin'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Full name'), 'Coordinator');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'admin@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password1');

    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    expect(find.text('Coordinator dashboard'), findsOneWidget);
  });

  testWidgets('signing in with the wrong password shows an error and stays put', (tester) async {
    await authService.signUp(
      name: 'Existing User',
      email: 'exists@example.com',
      password: 'correct-password',
      role: UserRole.student,
    );
    await authService.signOut();

    await pumpGate(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'exists@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'wrong-password');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect email or password.'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
