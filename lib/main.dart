import 'dart:async';

import 'package:flutter/material.dart';

import 'ads/interstitial_ad_service.dart';
import 'models/onboarding_store.dart';
import 'theme/studio_theme.dart';
import 'screens/app_shell.dart';
import 'screens/onboarding_screen.dart';

void main() {
  runApp(const SkinStudioApp());
}

class SkinStudioApp extends StatelessWidget {
  const SkinStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Block Skin Studio',
      theme: StudioTheme.dark,
      home: const _AppLaunchGate(),
    );
  }
}

class _AppLaunchGate extends StatefulWidget {
  const _AppLaunchGate();

  @override
  State<_AppLaunchGate> createState() => _AppLaunchGateState();
}

class _AppLaunchGateState extends State<_AppLaunchGate> {
  bool? _onboardingComplete;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final complete = await OnboardingStore.hasCompleted();
    if (complete) unawaited(InterstitialAdService.instance.initialize());
    if (mounted) setState(() => _onboardingComplete = complete);
  }

  Future<void> _completeOnboarding() async {
    try {
      await OnboardingStore.markCompleted();
    } finally {
      unawaited(InterstitialAdService.instance.initialize());
      if (mounted) setState(() => _onboardingComplete = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_onboardingComplete) {
      null => const _LaunchLoadingView(),
      true => const AppShell(),
      false => OnboardingScreen(onComplete: _completeOnboarding),
    };
  }
}

class _LaunchLoadingView extends StatelessWidget {
  const _LaunchLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFB8F34A),
                borderRadius: BorderRadius.all(Radius.circular(18)),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Icon(
                  Icons.view_in_ar,
                  color: Color(0xFF171A21),
                  size: 32,
                ),
              ),
            ),
            SizedBox(height: 18),
            SizedBox(width: 88, child: LinearProgressIndicator(minHeight: 3)),
          ],
        ),
      ),
    );
  }
}
