import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/staff_profile.dart';
import '../repositories/staff_repository.dart';
import '../services/auth_service.dart';
import '../widgets/staff_summary_card.dart';
import 'staff_profile_detail_screen.dart';

class StudentBrowseScreen extends StatefulWidget {
  const StudentBrowseScreen({
    super.key,
    required this.user,
    required this.authService,
    required this.repository,
    required this.firebaseReady,
  });

  final AppUser user;
  final AuthService authService;
  final StaffRepository repository;
  final bool firebaseReady;

  @override
  State<StudentBrowseScreen> createState() => _StudentBrowseScreenState();
}

class _StudentBrowseScreenState extends State<StudentBrowseScreen> {
  List<StaffProfile> _profiles = [];
  bool _isLoading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profiles = await widget.repository.fetchAllProfiles();
    if (!mounted) return;
    setState(() {
      _profiles = profiles;
      _isLoading = false;
    });
  }

  List<StaffProfile> get _filteredProfiles {
    if (_query.trim().isEmpty) return _profiles;

    final query = _query.toLowerCase();

    return _profiles.where((profile) {
      final matchesName = profile.name.toLowerCase().contains(query);
      final matchesDepartment = profile.department.toLowerCase().contains(query);
      final matchesArea =
          profile.areasOfInterest.any((area) => area.toLowerCase().contains(query));
      final matchesIdea = profile.projectIdeas
          .any((idea) => idea.title.toLowerCase().contains(query));

      return matchesName || matchesDepartment || matchesArea || matchesIdea;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final profiles = _filteredProfiles;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a supervisor'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => widget.authService.signOut(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (!widget.firebaseReady)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7E6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Running without Firebase: only staff profiles created in this session are shown.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF92610C)),
                      ),
                    ),
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search by name, department, area, or idea',
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 16),
                  if (profiles.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'No staff profiles match your search yet.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    for (final profile in profiles)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: StaffSummaryCard(
                          profile: profile,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    StaffProfileDetailScreen(profile: profile),
                              ),
                            );
                          },
                        ),
                      ),
                ],
              ),
            ),
    );
  }
}
