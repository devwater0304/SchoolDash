import 'package:flutter/material.dart';

import '../models/school_profile.dart';
import '../repositories/school_profile_repository.dart';
import 'home_screen.dart';
import 'school_onboarding_screen.dart';

/// Checks for a saved profile before choosing the app's first screen.
/// A future setup flow can replace the placeholder without changing Home.
class AppStartGate extends StatefulWidget {
  const AppStartGate({required this.profileRepository, super.key});

  final SchoolProfileRepository profileRepository;

  @override
  State<AppStartGate> createState() => _AppStartGateState();
}

class _AppStartGateState extends State<AppStartGate> {
  SchoolProfile? _profile;
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _reloadProfile();
  }

  Future<void> _reloadProfile() async {
    final profile = await widget.profileRepository.loadProfile();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profile = _profile;
    if (profile == null) {
      return SchoolOnboardingScreen(
        profileRepository: widget.profileRepository,
        onProfileSaved: _reloadProfile,
      );
    }
    return HomeScreen(profile: profile);
  }
}
