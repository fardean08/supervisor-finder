import 'package:flutter/material.dart';

import '../models/project_idea.dart';
import '../models/request.dart';
import '../models/staff_profile.dart';
import '../repositories/staff_repository.dart';

/// Shows a student's own supervisor requests, grouped by status.
class StudentRequestsScreen extends StatefulWidget {
  const StudentRequestsScreen({
    super.key,
    required this.studentId,
    required this.staffRepository,
    required this.requestRepository,
  });

  final String studentId;
  final StaffRepository staffRepository;
  final dynamic requestRepository;

  @override
  State<StudentRequestsScreen> createState() => _StudentRequestsScreenState();
}

class _StudentRequestsScreenState extends State<StudentRequestsScreen> {
  bool _isLoading = true;
  List<ProjectRequest> _requests = [];
  Map<String, StaffProfile> _staffById = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final requests = await widget.requestRepository.fetchRequestsForStudent(widget.studentId);
    final profiles = await widget.staffRepository.fetchAllProfiles();

    if (!mounted) return;
    setState(() {
      _requests = requests;
      _staffById = {for (final profile in profiles) profile.uid: profile};
      _isLoading = false;
    });
  }

  List<ProjectRequest> _byStatus(RequestStatus status) {
    return _requests.where((r) => r.status == status).toList();
  }

  ProjectIdea? _ideaFor(ProjectRequest request) {
    final staff = _staffById[request.staffId];
    if (staff == null) return null;

    for (final idea in staff.projectIdeas) {
      if (idea.id == request.ideaId) return idea;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My requests')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _requests.isEmpty
                  ? ListView(
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 64),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                                SizedBox(height: 12),
                                Text(
                                  'You haven\'t requested any projects yet.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final status in RequestStatus.values)
                          if (_byStatus(status).isNotEmpty) ...[
                            _StatusHeader(status: status, count: _byStatus(status).length),
                            const SizedBox(height: 8),
                            for (final request in _byStatus(status))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _RequestTile(
                                  request: request,
                                  staff: _staffById[request.staffId],
                                  idea: _ideaFor(request),
                                ),
                              ),
                            const SizedBox(height: 8),
                          ],
                      ],
                    ),
            ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.status, required this.count});

  final RequestStatus status;
  final int count;

  ({String label, IconData icon, Color color}) get _display {
    switch (status) {
      case RequestStatus.pending:
        return (label: 'Pending', icon: Icons.hourglass_empty, color: const Color(0xFF92610C));
      case RequestStatus.accepted:
        return (label: 'Accepted', icon: Icons.check_circle_outline, color: const Color(0xFF2E7D32));
      case RequestStatus.declined:
        return (label: 'Declined', icon: Icons.cancel_outlined, color: const Color(0xFFB3261E));
    }
  }

  @override
  Widget build(BuildContext context) {
    final display = _display;
    return Row(
      children: [
        Icon(display.icon, size: 18, color: display.color),
        const SizedBox(width: 8),
        Text(
          '${display.label} ($count)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: display.color),
        ),
      ],
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.request, required this.staff, required this.idea});

  final ProjectRequest request;
  final StaffProfile? staff;
  final ProjectIdea? idea;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.lightbulb_outline, color: Color(0xFF2E5AAC)),
        title: Text(idea?.title ?? 'Project idea'),
        subtitle: Text(staff?.name ?? 'Supervisor'),
      ),
    );
  }
}
