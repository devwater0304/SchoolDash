import 'package:flutter/material.dart';

import '../models/school_profile.dart';
import '../repositories/school_profile_repository.dart';
import 'home_screen.dart';
import 'profile_setup_placeholder_screen.dart';

/// Checks for a saved profile before choosing the app's first screen.
/// A future setup flow can replace the placeholder without changing Home.
class AppStartGate extends StatelessWidget {
  const AppStartGate({required this.profileRepository, super.key});

  final SchoolProfileRepository profileRepository;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SchoolProfile?>(
      future: profileRepository.loadProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final profile = snapshot.data;
        if (profile == null) {
          return const ProfileSetupPlaceholderScreen();
        }
        return HomeScreen(profile: profile);
      },
    );
  }
}
