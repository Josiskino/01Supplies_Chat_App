import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../../config/locale/locale_provider.dart';
import '../../../config/theme/apple_type.dart';
import '../../../config/theme/design_tokens.dart';
import '../../../core/providers/auth/auth_provider.dart';
import '../../../domain/entity/auth/user_entity.dart';
import '../../../config/theme/theme.dart';
import '../../../core/platform/platform_ui_provider.dart';
import '../../../core/providers/auth/auth_status_provider.dart';
import '../../../core/utils/localization_helper.dart';
import '../../../flavors.dart';
import '../../desktop/widgets/presence_avatar.dart';
import '../../widgets/common/platform_page.dart';
import 'widgets/settings_group.dart';

/// Réglages de l'application et compte de l'agent.
///
/// Sert à la fois d'onglet de la coquille et de destination poussée sur
/// `AppUiRoute.settings` : c'est le même contenu, il n'y a pas lieu d'en tenir
/// deux versions.
///
/// Présentation *inset grouped* d'iOS : des cartes arrondies sur un fond mat,
/// chacune réunissant des lignes de même nature. Le regroupement remplace les
/// titres de section — c'est ce qui rend la page lisible d'un coup d'œil malgré
/// une douzaine d'entrées.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = LocalizationHelper.of(context);
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    final overlays = ref.watch(platformUiProvider).overlays;
    final user = ref.watch(currentUserProvider);

    final themeLabels = [l10n.themeSystem, l10n.themeLight, l10n.themeDark];
    const themeModes = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];
    final localeLabels = [l10n.languageFrench, l10n.languageEnglish];
    const localeCodes = ['fr', 'en'];

    return PlatformPage(
      title: l10n.settingsTitle,
      body: ListView(
        padding: EdgeInsets.only(
          top: DesignTokens.spaceL,
          left: DesignTokens.spaceL,
          right: DesignTokens.spaceL,
          // Marge annoncée par la coquille : sur iOS, la barre d'onglets est en
          // verre et le contenu défile dessous.
          bottom: MediaQuery.paddingOf(context).bottom + DesignTokens.spaceXxl,
        ),
        children: [
          _ProfileHeader(user: user),
          const SizedBox(height: DesignTokens.spaceXl),

          // Carte d'affectation, à la place de la bannière promotionnelle de la
          // maquette : sur une app interne, ce qui mérite d'être mis en avant
          // n'est pas une offre, c'est le rôle qui décide de ce qu'on voit.
          _AssignmentCard(user: user),
          const SizedBox(height: DesignTokens.spaceXl),

          SettingsGroup(
            children: [
              SettingsRow(
                icon: Iconsax.moon,
                title: l10n.themeLabel,
                value: themeLabels[themeModes.indexOf(themeMode)],
                onTap: () async {
                  final choice = await overlays.pickOption(
                    context: context,
                    title: l10n.themeLabel,
                    labels: themeLabels,
                    selectedIndex: themeModes.indexOf(themeMode),
                  );
                  if (choice == null) return;
                  ref
                      .read(themeProvider.notifier)
                      .setThemeMode(themeModes[choice]);
                },
              ),
              SettingsRow(
                icon: Iconsax.global,
                title: l10n.languageLabel,
                value: localeLabels[localeCodes.indexOf(locale.languageCode)],
                onTap: () async {
                  final choice = await overlays.pickOption(
                    context: context,
                    title: l10n.languageLabel,
                    labels: localeLabels,
                    selectedIndex: localeCodes.indexOf(locale.languageCode),
                  );
                  if (choice == null) return;
                  ref
                      .read(localeProvider.notifier)
                      .setLocale(Locale(localeCodes[choice]));
                },
              ),
              SettingsRow(
                icon: Iconsax.notification,
                title: 'Notifications',
                // Interrupteur de plateforme : sur iOS, un Switch Material se
                // remarque immédiatement comme étranger au système.
                trailing: ref
                    .watch(platformUiProvider)
                    .controls
                    .switchToggle(value: true, onChanged: (_) {}),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceXl),

          SettingsGroup(
            children: [
              SettingsRow(
                icon: Iconsax.message_question,
                title: 'Centre d’aide',
                onTap: () {},
              ),
              SettingsRow(
                icon: Iconsax.warning_2,
                title: 'Signaler un problème',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceXl),

          SettingsGroup(
            children: [
              SettingsRow(
                icon: Iconsax.info_circle,
                title: 'À propos',
                onTap: () {},
              ),
              SettingsRow(
                icon: Iconsax.document_text,
                title: 'Conditions d’utilisation',
                onTap: () {},
              ),
              SettingsRow(
                icon: Iconsax.shield_tick,
                title: 'Confidentialité',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceXl),

          SettingsGroup(
            children: [
              SettingsRow(
                icon: Iconsax.logout,
                title: l10n.signOut,
                isDestructive: true,
                onTap: () => ref.read(authStatusProvider.notifier).signOut(),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceL),

          Center(
            child: Text(
              // Le flavor est affiché en clair : sans repère visible, un agent
              // ne peut pas distinguer une app de recette de la production.
              '${FlavorConfig.appName} · version 1.0.0',
              style: theme.textTheme.labelSmall
                  ?.merge(AppleType.caption1)
                  .copyWith(
                    color: DesignTokens.getTextColorWithOpacity(context, 0.4),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// En-tête : avatar, nom, adresse du compte connecté.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  /// Nul pendant la restauration de session, au tout premier affichage.
  final UserEntity? user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Un tiret plutôt qu'un nom inventé : afficher une identité qui n'est pas
    // celle du connecté est pire que d'admettre qu'on ne la connaît pas encore.
    final name = user?.displayName ?? '—';

    return Column(
      children: [
        PresenceAvatar(name: name, avatarUrl: user?.avatarUrl, size: 88),
        const SizedBox(height: DesignTokens.spaceM),
        Text(
          name,
          style: theme.textTheme.headlineSmall
              ?.merge(AppleType.title3)
              .copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          user?.email ?? '',
          style: theme.textTheme.bodyMedium
              ?.merge(AppleType.subheadline)
              .copyWith(
                color: DesignTokens.getTextColorWithOpacity(context, 0.5),
              ),
        ),
      ],
    );
  }
}

/// Carte colorée rappelant le rôle du compte connecté.
class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.user});

  final UserEntity? user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceL),
      decoration: BoxDecoration(
        borderRadius: DesignTokens.borderRadiusL,
        // Dégradé de marque plutôt qu'un aplat : c'est le seul bloc coloré de
        // la page, il doit se détacher des cartes blanches sans crier.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.75),
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.role?.label ?? 'Équipe 01Supplies',
                  style: theme.textTheme.titleMedium
                      ?.merge(AppleType.headline)
                      .copyWith(color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  // L'affectation (secteur, équipe) n'est pas encore exposée par
                  // l'API : on affiche ce qu'on sait, l'adresse du compte.
                  user?.email ?? '',
                  style: theme.textTheme.bodySmall
                      ?.merge(AppleType.subheadline)
                      .copyWith(color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.spaceM),
          Container(
            padding: const EdgeInsets.all(DesignTokens.spaceM),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.person_badge_plus,
              size: 20,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
