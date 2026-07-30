import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'repositories/staff_repository.dart';
import 'repositories/request_repository.dart';
import 'repositories/user_repository.dart';
import 'screens/auth_gate.dart';
import 'services/auth_service.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var firebaseReady = false;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (_) {
    firebaseReady = false;
  }

  runApp(FypSupervisorFinderApp(firebaseReady: firebaseReady));
}

class FypSupervisorFinderApp extends StatelessWidget {
  const FypSupervisorFinderApp({
    super.key,
    required this.firebaseReady,
  });

  final bool firebaseReady;

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E5AAC),
        brightness: brightness,
      ),
      scaffoldBackgroundColor: isDark ? const Color(0xFF121417) : const Color(0xFFF3F4F6),
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF1E2126) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF17191D) : const Color(0xFFF9FAFB),
        foregroundColor: isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827),
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1E2126) : const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isDark ? const Color(0xFF3A3F47) : const Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2E5AAC), width: 1.4),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? const Color(0xFF262B33) : const Color(0xFFE9EEF9),
        labelStyle: TextStyle(color: isDark ? const Color(0xFFCBD5F5) : const Color(0xFF1F3A63)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      useMaterial3: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final StaffRepository staffRepository =
        firebaseReady ? FirestoreStaffRepository() : MemoryStaffRepository();

    final requestRepository = firebaseReady
        ? FirestoreRequestRepository(staffRepository: staffRepository)
        : MemoryRequestRepository(staffRepository: staffRepository);

    final UserRepository userRepository =
        firebaseReady ? FirestoreUserRepository() : MemoryUserRepository();

    final AuthService authService = firebaseReady
        ? FirebaseAuthService()
        : LocalAuthService(
            onUserChanged: (user) => (userRepository as MemoryUserRepository).upsert(user),
          );

    final themeController = ThemeController();

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'FYP Supervisor Finder',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          home: AuthGate(
            authService: authService,
            staffRepository: staffRepository,
            requestRepository: requestRepository,
            userRepository: userRepository,
            themeController: themeController,
            firebaseReady: firebaseReady,
          ),
        );
      },
    );
  }
}
