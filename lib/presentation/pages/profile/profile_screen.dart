import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../../config/theme/design_tokens.dart';
import '../../../core/constants/app_ui_route.dart';
import '../../../core/providers/auth/auth_status_provider.dart';
import '../../../core/utils/localization_helper.dart';
import '../../../flavors.dart';
import '../../widgets/settings/settings_widgets.dart';
import 'package:go_router/go_router.dart';

/// Compte de l'agent et accès aux réglages.
///
/// Seul onglet réellement fonctionnel du socle : il exerce la persistance du
/// thème et de la langue et la fermeture de session, ce qui rend le socle
/// vérifiable de bout en bout sans attendre la feature messagerie.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = LocalizationHelper.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceL),
        children: [
          SettingsCard(
            children: [
              SettingsItem(
                icon: Iconsax.setting_2,
                title: l10n.settingsTitle,
                onTap: () => context.push(AppUiRoute.settings),
              ),
            ],
          ),
          SettingsCard(
            children: [
              SettingsItem(
                icon: Iconsax.logout,
                title: l10n.signOut,
                isDestructive: true,
                onTap: () =>
                    ref.read(authStatusProvider.notifier).signOut(),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spaceL),
            child: Text(
              // Le flavor est affiché en clair : sans repère visible, un agent
              // ne peut pas distinguer une app de recette de la production.
              FlavorConfig.appName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
