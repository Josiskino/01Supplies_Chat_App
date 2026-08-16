import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/design_tokens.dart';
import '../../../core/providers/splash_completed_provider.dart';
import '../../../core/utils/localization_helper.dart';
import '../../../flavors.dart';
import '../../widgets/pulsing_logo.dart';

/// Écran de démarrage.
///
/// Joue une courte animation puis lève le verrou `splashCompleted`, ce qui
/// déclenche la redirection du routeur. Sans ce signal explicite, l'app resterait
/// bloquée ici : c'est le défaut du splash de l'app management, dont l'écran ne
/// navigue jamais.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const Duration _minimumDisplay = Duration(milliseconds: 900);

  @override
  void initState() {
    super.initState();
    _completeAfterAnimation();
  }

  Future<void> _completeAfterAnimation() async {
    await Future<void>.delayed(_minimumDisplay);
    if (!mounted) return;
    ref.read(splashCompletedProvider.notifier).complete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const PulsingLogo(),
            const SizedBox(height: DesignTokens.spaceXxl),
            Text(FlavorConfig.appName, style: theme.textTheme.headlineSmall),
            const SizedBox(height: DesignTokens.spaceS),
            Text(
              LocalizationHelper.of(context).appTagline,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
