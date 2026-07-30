import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/project_idea.dart';
import '../models/request.dart';
import '../models/staff_profile.dart';
import '../repositories/staff_repository.dart';
import '../services/auth_service.dart';
import '../widgets/area_chips_editor.dart';
import '../widgets/project_idea_card.dart';
import '../widgets/project_idea_form.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({
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
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  StaffProfile? _profile;
  bool _isLoading = true;
  late final TextEditingController _departmentController;
  late final TextEditingController _bioController;
  List<ProjectRequest> _incoming = [];
  int _maxStudents = 3;

  int get _acceptedCount =>
      _incoming.where((r) => r.status == RequestStatus.accepted).length;

  bool get _isFullyBooked => _acceptedCount >= _maxStudents;

  @override
  void initState() {
    super.initState();
    _departmentController = TextEditingController();
    _bioController = TextEditingController();
    _load();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      final list = await widget.requestRepository.fetchRequestsForStaff(widget.user.uid);
      if (!mounted) return;
      setState(() => _incoming = list);
    } catch (_) {}
  }

  @override
  void dispose() {
    _departmentController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final profile = await widget.repository.fetchOrCreateProfile(
      uid: widget.user.uid,
      name: widget.user.name,
      email: widget.user.email,
    );

    if (!mounted) return;

    setState(() {
      _profile = profile;
      _departmentController.text = profile.department;
      _bioController.text = profile.bio;
      _maxStudents = profile.maxStudents;
      _isLoading = false;
    });
  }

  Future<void> _saveDetails() async {
    await widget.repository.updateProfileDetails(
      uid: widget.user.uid,
      department: _departmentController.text.trim(),
      bio: _bioController.text.trim(),
      maxStudents: _maxStudents,
    );

    setState(() {
      _profile = _profile?.copyWith(
        department: _departmentController.text.trim(),
        bio: _bioController.text.trim(),
        maxStudents: _maxStudents,
      );
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile details saved')),
    );
  }

  Future<void> _addArea(String area) async {
    await widget.repository.addAreaOfInterest(uid: widget.user.uid, area: area);
    setState(() {
      _profile = _profile?.copyWith(
        areasOfInterest: [...?_profile?.areasOfInterest, area],
      );
    });
  }

  Future<void> _removeArea(String area) async {
    await widget.repository.removeAreaOfInterest(uid: widget.user.uid, area: area);
    setState(() {
      _profile = _profile?.copyWith(
        areasOfInterest:
            _profile?.areasOfInterest.where((item) => item != area).toList() ?? [],
      );
    });
  }

  Future<void> _addIdea() async {
    final idea = await showProjectIdeaForm(
      context,
      areaOptions: _profile?.areasOfInterest ?? const [],
    );
    if (idea == null) return;

    await widget.repository.addProjectIdea(uid: widget.user.uid, idea: idea);
    await _load();
  }

  Future<void> _editIdea(ProjectIdea idea) async {
    final updated = await showProjectIdeaForm(
      context,
      existing: idea,
      areaOptions: _profile?.areasOfInterest ?? const [],
    );
    if (updated == null) return;

    await widget.repository.updateProjectIdea(
      uid: widget.user.uid,
      idea: updated.copyWith(id: idea.id),
    );
    await _load();
  }

  Future<void> _deleteIdea(ProjectIdea idea) async {
    await widget.repository.deleteProjectIdea(uid: widget.user.uid, ideaId: idea.id);
    setState(() {
      _profile = _profile?.copyWith(
        projectIdeas:
            _profile?.projectIdeas.where((item) => item.id != idea.id).toList() ?? [],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My supervisor profile'),
        actions: [
          Stack(
            children: [
              IconButton(
                tooltip: 'Pending requests',
                icon: const Icon(Icons.mail_outline),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => _PendingRequestsScreen(
                      requests: _incoming,
                      onAction: (id, status) async {
                        await widget.requestRepository.updateRequestStatus(
                          requestId: id,
                          status: status,
                        );
                        if (status == RequestStatus.accepted) {
                          // auto-decline other requests for same idea
                          final accepted = _incoming.firstWhere((r) => r.id == id);
                          for (final r in _incoming) {
                            if (r.ideaId == accepted.ideaId && r.id != id) {
                              await widget.requestRepository.updateRequestStatus(
                                requestId: r.id,
                                status: RequestStatus.declined,
                              );
                            }
                          }
                        }
                        await _loadRequests();
                      },
                    ),
                  ));
                },
              ),
              if (_incoming.where((r) => r.status == RequestStatus.pending).isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      '${_incoming.where((r) => r.status == RequestStatus.pending).length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
            ],
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
                        'Running without Firebase: your profile is stored locally for this session only.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF92610C)),
                      ),
                    ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.user.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              if (_isFullyBooked)
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFBE9E7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Fully booked',
                                    style: TextStyle(fontSize: 11, color: Color(0xFFB3261E)),
                                  ),
                                ),
                            ],
                          ),
                          Text(widget.user.email, style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _departmentController,
                            decoration: const InputDecoration(labelText: 'Department'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _bioController,
                            decoration: const InputDecoration(labelText: 'Short bio'),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          Text('Supervision capacity', style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 4),
                          Text(
                            'Currently supervising $_acceptedCount of $_maxStudents students.',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton.filledTonal(
                                icon: const Icon(Icons.remove),
                                onPressed: _maxStudents > _acceptedCount && _maxStudents > 1
                                    ? () => setState(() => _maxStudents--)
                                    : null,
                              ),
                              SizedBox(
                                width: 48,
                                child: Text(
                                  '$_maxStudents',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              IconButton.filledTonal(
                                icon: const Icon(Icons.add),
                                onPressed: () => setState(() => _maxStudents++),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Max students you can supervise at once',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton(
                              onPressed: _saveDetails,
                              child: const Text('Save details'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Areas of interest', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          const Text(
                            'These help students find you when browsing for a supervisor.',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          AreaChipsEditor(
                            areas: _profile?.areasOfInterest ?? const [],
                            onAdd: _addArea,
                            onRemove: _removeArea,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Project ideas', style: Theme.of(context).textTheme.titleMedium),
                      FilledButton.icon(
                        onPressed: _addIdea,
                        icon: const Icon(Icons.add),
                        label: const Text('Add idea'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if ((_profile?.projectIdeas ?? const []).isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No project ideas yet. Add one so students can find it.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    for (final idea in _profile!.projectIdeas)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ProjectIdeaCard(
                          idea: idea,
                          onEdit: () => _editIdea(idea),
                          onDelete: () => _deleteIdea(idea),
                        ),
                      ),
                ],
              ),
            ),
    );
  }
}

class _PendingRequestsScreen extends StatelessWidget {
  const _PendingRequestsScreen({
    required this.requests,
    required this.onAction,
  });

  final List<ProjectRequest> requests;
  final Future<void> Function(String id, RequestStatus status) onAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending requests')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final r = requests[index];
          return Card(
            child: ListTile(
              title: Text('Student: ${r.studentId}'),
              subtitle: Text('Idea: ${r.ideaId} — ${r.status.name}'),
              trailing: r.status == RequestStatus.pending
                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () async {
                          await onAction(r.id, RequestStatus.accepted);
                          Navigator.of(context).pop();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () async {
                          await onAction(r.id, RequestStatus.declined);
                          Navigator.of(context).pop();
                        },
                      ),
                    ])
                  : Text(r.status.name),
            ),
          );
        },
      ),
    );
  }
}
