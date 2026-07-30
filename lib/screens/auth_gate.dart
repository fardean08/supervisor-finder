import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../repositories/staff_repository.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';
import 'staff_dashboard_screen.dart';
import 'student_browse_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.authService,
    required this.staffRepository,
    required this.requestRepository,
    required this.firebaseReady,
  });

  final AuthService authService;
  final StaffRepository staffRepository;
  final dynamic requestRepository;
  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return AuthScreen(
            authService: authService,
            firebaseReady: firebaseReady,
          );
        }

        if (user.isStaff) {
          return StaffDashboardScreen(
            user: user,
            authService: authService,
            repository: staffRepository,
            requestRepository: requestRepository,
            firebaseReady: firebaseReady,
          );
        }

        return StudentBrowseScreen(
          user: user,
          authService: authService,
          repository: staffRepository,
          requestRepository: requestRepository,
          firebaseReady: firebaseReady,
        );
      },
    );
  }
}
