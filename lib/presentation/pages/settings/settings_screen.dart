import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../../config/locale/locale_provider.dart';
import '../../../config/theme/design_tokens.dart';
import '../../../config/theme/theme.dart';
import '../../../core/providers/auth/auth_status_provider.dart';
import '../../../core/utils/localization_helper.dart';
import '../../../flavors.dart';
import '../../widgets/common/platform_page.dart';
import '../../widgets/settings/settings_widgets.dart';

/// Réglages de l'application et compte de l'agent.
///
/// Sert à la fois d'onglet de la coquille et de destination poussée sur
/// `AppUiRoute.settings` : c'est le même contenu, il n'y a pas lieu d'en tenir
/// deux versions. Un onglet « Réglages » dont le premier élément serait une ligne
/// « Réglages » menant ailleurs ne serait qu'un détour.
///
/// Seul onglet réellement fonctionnel du socle : il exerce la persistance du
/// thème et de la langue et la fermeture de session, ce qui rend le socle
/// vérifiable de bout en bout sans attendre la feature messagerie.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = LocalizationHelper.of(context);
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return PlatformPage(
      title: l10n.settingsTitle,
      body: ListView(
        // Marge annoncée par la coquille : sur iOS, la barre d'onglets est en
        // verre et le contenu défile dessous. Sans cette reprise, le dernier
        // élément resterait inatteignable.
        padding: EdgeInsets.only(
          top: DesignTokens.spaceL,
          bottom: MediaQuery.paddingOf(context).bottom + DesignTokens.spaceL,
        ),
        children: [
          SettingsCard(
            children: [
              for (final entry in <(ThemeMode, String, IconData)>[
                (ThemeMode.system, l10n.themeSystem, Iconsax.mobile),
                (ThemeMode.light, l10n.themeLight, Iconsax.sun_1),
                (ThemeMode.dark, l10n.themeDark, Iconsax.moon),
              ])
                SettingsItem(
                  icon: entry.$3,
                  title: entry.$2,
                  trailing: SettingsCheckmark(
                    isSelected: themeMode == entry.$1,
                  ),
                  onTap: () =>
                      ref.read(themeProvider.notifier).setThemeMode(entry.$1),
                ),
            ],
          ),
          SettingsCard(
            children: [
              for (final entry in <(String, String)>[
                ('fr', l10n.languageFrench),
                ('en', l10n.languageEnglish),
              ])
                SettingsItem(
                  icon: Iconsax.global,
                  title: entry.$2,
                  trailing: SettingsCheckmark(
                    isSelected: locale.languageCode == entry.$1,
                  ),
                  onTap: () => ref
                      .read(localeProvider.notifier)
                      .setLocale(Locale(entry.$1)),
                ),
            ],
          ),
          SettingsCard(
            children: [
              SettingsItem(
                icon: Iconsax.logout,
                title: l10n.signOut,
                isDestructive: true,
                onTap: () => ref.read(authStatusProvider.notifier).signOut(),
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
