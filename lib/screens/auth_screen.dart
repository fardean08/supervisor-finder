import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../widgets/area_chips_editor.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.authService,
    required this.firebaseReady,
  });

  final AuthService authService;
  final bool firebaseReady;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  String? _errorMessage;
  UserRole _role = UserRole.student;
  List<String> _interests = [];

  bool get _showSignUpShortcut {
    if (_isSignUp || _errorMessage == null) {
      return false;
    }

    return _errorMessage!.toLowerCase().contains('please sign up first');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        await widget.authService.signUp(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _role,
          interests: _role == UserRole.student ? _interests : const [],
        );
      } else {
        await widget.authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } catch (error) {
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.school_outlined, size: 56, color: Color(0xFF2E5AAC)),
                    const SizedBox(height: 12),
                    Text(
                      'FYP Supervisor Finder',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isSignUp ? 'Create an account' : 'Welcome back',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (!widget.firebaseReady) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7E6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Firebase isn\'t configured yet, so this demo runs on local, in-memory accounts. Data resets when the app restarts.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF92610C)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (_isSignUp) ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Full name'),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty) ? 'Enter your name' : null,
                      ),
                      const SizedBox(height: 12),
                      Text('I am a...', style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 6),
                      SegmentedButton<UserRole>(
                        segments: const [
                          ButtonSegment(
                            value: UserRole.student,
                            label: Text('Student'),
                            icon: Icon(Icons.backpack_outlined),
                          ),
                          ButtonSegment(
                            value: UserRole.staff,
                            label: Text('Staff'),
                            icon: Icon(Icons.badge_outlined),
                          ),
                        ],
                        selected: {_role},
                        onSelectionChanged: (selection) {
                          setState(() => _role = selection.first);
                        },
                      ),
                      if (_role == UserRole.student) ...[
                        const SizedBox(height: 16),
                        Text('Areas of interest', style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 4),
                        const Text(
                          'Used to rank supervisors with matching interests for you.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        AreaChipsEditor(
                          areas: _interests,
                          onAdd: (area) => setState(() => _interests = [..._interests, area]),
                          onRemove: (area) => setState(
                            () => _interests = _interests.where((item) => item != area).toList(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          (value == null || !value.contains('@')) ? 'Enter a valid email' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: (value) =>
                          (value == null || value.length < 6) ? 'At least 6 characters' : null,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (_showSignUpShortcut) ...[
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () => setState(() {
                          _isSignUp = true;
                          _errorMessage = null;
                        }),
                        child: const Text('Create an account instead'),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isSignUp ? 'Sign up' : 'Log in'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() {
                                _isSignUp = !_isSignUp;
                                _errorMessage = null;
                              }),
                      child: Text(
                        _isSignUp
                            ? 'Already have an account? Log in'
                            : 'New here? Create an account',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
