import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'repositories/staff_repository.dart';
import 'repositories/request_repository.dart';
import 'screens/auth_gate.dart';
import 'services/auth_service.dart';

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

  @override
  Widget build(BuildContext context) {
    final AuthService authService =
        firebaseReady ? FirebaseAuthService() : LocalAuthService();

    final StaffRepository staffRepository =
        firebaseReady ? FirestoreStaffRepository() : MemoryStaffRepository();

    final requestRepository = firebaseReady
        ? FirestoreRequestRepository(staffRepository: staffRepository)
        : MemoryRequestRepository(staffRepository: staffRepository);

    return MaterialApp(
      title: 'FYP Supervisor Finder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E5AAC),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF9FAFB),
          foregroundColor: Color(0xFF111827),
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2E5AAC), width: 1.4),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFE9EEF9),
          labelStyle: const TextStyle(color: Color(0xFF1F3A63)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        useMaterial3: true,
      ),
      home: AuthGate(
        authService: authService,
        staffRepository: staffRepository,
        requestRepository: requestRepository,
        firebaseReady: firebaseReady,
      ),
    );
  }
}
