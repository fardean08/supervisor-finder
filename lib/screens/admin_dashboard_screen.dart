import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/request.dart';
import '../models/staff_profile.dart';
import '../repositories/staff_repository.dart';
import '../repositories/user_repository.dart';
import '../services/auth_service.dart';
import '../theme/theme_controller.dart';

/// Read-only overview for coordinators: every staff profile, every
/// student, and every request in the system.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
    required this.authService,
    required this.staffRepository,
    required this.requestRepository,
    required this.userRepository,
    required this.themeController,
  });

  final AuthService authService;
  final StaffRepository staffRepository;
  final dynamic requestRepository;
  final UserRepository userRepository;
  final ThemeController themeController;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  List<StaffProfile> _staff = [];
  List<AppUser> _students = [];
  List<ProjectRequest> _requests = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // There's no backend "give me the whole system" endpoint, so this
    // just pulls the three collections independently and stitches them
    // together client-side (matching staffId/studentId by hand below).
    // Fine at this app's scale; would need real joins/pagination if the
    // number of staff/students/requests ever got large.
    final staff = await widget.staffRepository.fetchAllProfiles();
    final users = await widget.userRepository.fetchAllUsers();
    final requests = await widget.requestRepository.fetchAllRequests();

    if (!mounted) return;
    setState(() {
      _staff = staff;
      _students = users.where((u) => u.isStudent).toList();
      _requests = requests;
      _isLoading = false;
    });
  }

  int _acceptedCountFor(String staffId) {
    return _requests
        .where((r) => r.staffId == staffId && r.status == RequestStatus.accepted)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Coordinator dashboard'),
          actions: [
            ValueListenableBuilder<ThemeMode>(
              valueListenable: widget.themeController,
              builder: (context, mode, _) => IconButton(
                tooltip: mode == ThemeMode.dark ? 'Switch to light mode' : 'Switch to dark mode',
                icon: Icon(mode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                onPressed: widget.themeController.toggle,
              ),
            ),
            IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout),
              onPressed: () => widget.authService.signOut(),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Staff'),
              Tab(text: 'Students'),
              Tab(text: 'Requests'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: TabBarView(
                  children: [
                    _OverviewTab(staff: _staff, students: _students, requests: _requests),
                    _StaffTab(staff: _staff, acceptedCountFor: _acceptedCountFor),
                    _StudentsTab(students: _students),
                    _RequestsTab(requests: _requests, staff: _staff, students: _students),
                  ],
                ),
              ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.staff, required this.students, required this.requests});

  final List<StaffProfile> staff;
  final List<AppUser> students;
  final List<ProjectRequest> requests;

  @override
  Widget build(BuildContext context) {
    final pending = requests.where((r) => r.status == RequestStatus.pending).length;
    final accepted = requests.where((r) => r.status == RequestStatus.accepted).length;
    final declined = requests.where((r) => r.status == RequestStatus.declined).length;
    final fullyBooked = staff.where((s) {
      final count = requests
          .where((r) => r.staffId == s.uid && r.status == RequestStatus.accepted)
          .length;
      return count >= s.maxStudents;
    }).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _StatCard(label: 'Staff', value: '${staff.length}', icon: Icons.badge_outlined),
            _StatCard(label: 'Students', value: '${students.length}', icon: Icons.backpack_outlined),
            _StatCard(
              label: 'Fully booked staff',
              value: '$fullyBooked',
              icon: Icons.event_busy_outlined,
            ),
            _StatCard(
              label: 'Total requests',
              value: '${requests.length}',
              icon: Icons.swap_horiz_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Requests by status', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _StatusBar(label: 'Pending', count: pending, total: requests.length, color: const Color(0xFF92610C)),
                const SizedBox(height: 8),
                _StatusBar(label: 'Accepted', count: accepted, total: requests.length, color: const Color(0xFF2E7D32)),
                const SizedBox(height: 8),
                _StatusBar(label: 'Declined', count: declined, total: requests.length, color: const Color(0xFFB3261E)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF2E5AAC)),
            const Spacer(),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : count / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $count', style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor: const Color(0xFFE5E7EB),
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StaffTab extends StatelessWidget {
  const _StaffTab({required this.staff, required this.acceptedCountFor});

  final List<StaffProfile> staff;
  final int Function(String staffId) acceptedCountFor;

  @override
  Widget build(BuildContext context) {
    if (staff.isEmpty) {
      return const _EmptyState(
        icon: Icons.badge_outlined,
        message: 'No staff profiles yet.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: staff.length,
      itemBuilder: (context, index) {
        final profile = staff[index];
        final accepted = acceptedCountFor(profile.uid);
        final isFull = accepted >= profile.maxStudents;

        return Card(
          child: ListTile(
            title: Text(profile.name),
            subtitle: Text(
              '${profile.department.isEmpty ? 'No department' : profile.department} · '
              '${profile.projectIdeas.length} idea${profile.projectIdeas.length == 1 ? '' : 's'} · '
              '${profile.areasOfInterest.length} area${profile.areasOfInterest.length == 1 ? '' : 's'}',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$accepted / ${profile.maxStudents}'),
                if (isFull)
                  const Text(
                    'Fully booked',
                    style: TextStyle(fontSize: 11, color: Color(0xFFB3261E)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StudentsTab extends StatelessWidget {
  const _StudentsTab({required this.students});

  final List<AppUser> students;

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return const _EmptyState(
        icon: Icons.backpack_outlined,
        message: 'No students have signed up yet.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        return Card(
          child: ListTile(
            title: Text(student.name),
            subtitle: Text(student.email),
            trailing: student.interests.isEmpty
                ? null
                : Text('${student.interests.length} interest${student.interests.length == 1 ? '' : 's'}'),
          ),
        );
      },
    );
  }
}

class _RequestsTab extends StatelessWidget {
  const _RequestsTab({required this.requests, required this.staff, required this.students});

  final List<ProjectRequest> requests;
  final List<StaffProfile> staff;
  final List<AppUser> students;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const _EmptyState(
        icon: Icons.swap_horiz_outlined,
        message: 'No requests have been made yet.',
      );
    }

    final staffById = {for (final s in staff) s.uid: s};
    final studentsById = {for (final s in students) s.uid: s};

    Color colorFor(RequestStatus status) {
      switch (status) {
        case RequestStatus.pending:
          return const Color(0xFF92610C);
        case RequestStatus.accepted:
          return const Color(0xFF2E7D32);
        case RequestStatus.declined:
          return const Color(0xFFB3261E);
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        final staffName = staffById[request.staffId]?.name ?? request.staffId;
        final studentName = studentsById[request.studentId]?.name ?? request.studentId;

        return Card(
          child: ListTile(
            title: Text('$studentName → $staffName'),
            subtitle: Text('Idea: ${request.ideaId}'),
            trailing: Text(
              request.status.name,
              style: TextStyle(color: colorFor(request.status), fontWeight: FontWeight.w600),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
