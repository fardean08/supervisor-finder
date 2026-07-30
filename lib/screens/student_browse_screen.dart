import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/staff_profile.dart';
import '../repositories/staff_repository.dart';
import '../services/auth_service.dart';
import '../services/matching_service.dart';
import '../widgets/area_chips_editor.dart';
import '../widgets/staff_summary_card.dart';
import 'staff_profile_detail_screen.dart';

class StudentBrowseScreen extends StatefulWidget {
  const StudentBrowseScreen({
    super.key,
    required this.user,
    required this.authService,
    required this.repository,
    required this.requestRepository,
    required this.firebaseReady,
  });

  final AppUser user;
  final AuthService authService;
  final StaffRepository repository;
  final dynamic requestRepository;
  final bool firebaseReady;

  @override
  State<StudentBrowseScreen> createState() => _StudentBrowseScreenState();
}

class _StudentBrowseScreenState extends State<StudentBrowseScreen> {
  static const _matchingService = MatchingService();

  List<StaffProfile> _profiles = [];
  bool _isLoading = true;
  String _query = '';
  late AppUser _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
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
    final query = _query.toLowerCase();

    final filtered = _query.trim().isEmpty
        ? _profiles
        : _profiles.where((profile) {
            final matchesName = profile.name.toLowerCase().contains(query);
            final matchesDepartment = profile.department.toLowerCase().contains(query);
            final matchesArea =
                profile.areasOfInterest.any((area) => area.toLowerCase().contains(query));
            final matchesIdea = profile.projectIdeas
                .any((idea) => idea.title.toLowerCase().contains(query));

            return matchesName || matchesDepartment || matchesArea || matchesIdea;
          }).toList();

    return _matchingService.rankByInterest(filtered, _user.interests);
  }

  Future<void> _editInterests() async {
    var localInterests = [..._user.interests];

    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('My areas of interest'),
              content: SizedBox(
                width: 360,
                child: AreaChipsEditor(
                  areas: localInterests,
                  onAdd: (area) => setDialogState(() => localInterests = [...localInterests, area]),
                  onRemove: (area) => setDialogState(
                    () => localInterests = localInterests.where((item) => item != area).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(localInterests),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    await widget.authService.updateInterests(uid: _user.uid, interests: result);
    if (!mounted) return;
    setState(() => _user = _user.copyWith(interests: result));
  }

  @override
  Widget build(BuildContext context) {
    final profiles = _filteredProfiles;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a supervisor'),
        actions: [
          IconButton(
            tooltip: 'My areas of interest',
            icon: const Icon(Icons.interests_outlined),
            onPressed: _editInterests,
          ),
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
                          sharedInterestCount: _matchingService.sharedInterestCount(
                            _user.interests,
                            profile.areasOfInterest,
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                        StaffProfileDetailScreen(
                                          profile: profile,
                                          currentUser: _user,
                                          requestRepository: widget.requestRepository,
                                        ),
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
