import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../config/theme/apple_type.dart';
import '../../../config/theme/design_tokens.dart';
import '../../../core/constants/app_ui_route.dart';
import '../../../core/platform/platform_ui.dart';
import '../../../core/platform/platform_ui_provider.dart';
import '../../../core/utils/localization_helper.dart';
import '../../shared/models/call_view_data.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/platform_page.dart';
import 'widgets/call_log_row.dart';

/// Historique des appels.
///
/// ## Écran volontairement vide
///
/// L'appel n'est pas implémenté : ni signalisation, ni transport audio, ni
/// endpoint d'historique côté API. La présentation — lignes, filtre, icônes —
/// est prête et testée, mais afficher un faux historique laisserait croire à
/// une fonctionnalité qui n'existe pas, et ferait chercher pourquoi rappeler ne
/// marche pas.
///
/// Les fixtures restent dans `CallFixtures` pour les tests de présentation.
class CallsScreen extends ConsumerStatefulWidget {
  const CallsScreen({super.key});

  @override
  ConsumerState<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends ConsumerState<CallsScreen> {
  /// Filtre « manqués » du sélecteur segmenté.
  bool _missedOnly = false;

  /// Vide tant que la fonctionnalité d'appel n'existe pas.
  List<CallLogEntry> get _entries => const [];

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationHelper.of(context);
    final platformUi = ref.watch(platformUiProvider);

    return PlatformPage(
      title: l10n.callsTitle,
      // Aucun bouton « Nouvel appel » : il ouvrirait un écran d'appel qui ne
      // compose rien.
      actions: const [],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.spaceL,
              DesignTokens.spaceS,
              DesignTokens.spaceL,
              DesignTokens.spaceM,
            ),
            child: _MissedFilter(
              missedOnly: _missedOnly,
              onChanged: (value) => setState(() => _missedOnly = value),
            ),
          ),
          Expanded(
            child: _entries.isEmpty
                ? const EmptyStateWidget(
                    icon: Iconsax.call,
                    title: 'Appels indisponibles',
                    message:
                        'Les appels audio et vidéo ne sont pas encore '
                        'disponibles dans 01 Chat.',
                  )
                : ListView.separated(
                    padding: EdgeInsets.only(
                      // Marge annoncée par la coquille : sur iOS, la barre
                      // d'onglets est en verre et le contenu défile dessous.
                      bottom:
                          MediaQuery.paddingOf(context).bottom +
                          DesignTokens.spaceM,
                    ),
                    itemCount: _entries.length,
                    separatorBuilder: (context, index) => Divider(
                      height: DesignTokens.borderWidthThin,
                      thickness: DesignTokens.borderWidthThin,
                      // Aligné sur le texte, comme dans les listes iOS.
                      indent: 72,
                      color: DesignTokens.getBorderColor(
                        Theme.of(context).brightness == Brightness.dark,
                        opacity: 0.10,
                      ),
                    ),
                    itemBuilder: (context, index) {
                      final entry = _entries[index];
                      return CallLogRow(
                        entry: entry,
                        isApple: platformUi.platform.isApple,
                        // Toucher la ligne rappelle : c'est le geste attendu
                        // dans un historique, et il évite un menu pour l'action
                        // que tout le monde vient chercher.
                        onTap: () =>
                            context.push(AppUiRoute.call, extra: entry.name),
                        onInfo: () => _showInfo(context, platformUi, entry),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showInfo(
    BuildContext context,
    PlatformUi platformUi,
    CallLogEntry entry,
  ) async {
    final choice = await platformUi.overlays.pickOption(
      context: context,
      title: entry.name,
      labels: const ['Appel vocal', 'Appel vidéo', 'Ouvrir la conversation'],
    );
    if (choice == null || !context.mounted) return;
    if (choice == 2) {
      context.push(AppUiRoute.conversationDetailPath('c1'));
    } else {
      context.push(AppUiRoute.call, extra: entry.name);
    }
  }
}

/// Sélecteur « Tous / Manqués ».
///
/// Deux segments plutôt qu'un menu de filtres : c'est le seul tri que l'on
/// cherche dans un historique d'appels, et il doit coûter un geste.
class _MissedFilter extends StatelessWidget {
  const _MissedFilter({required this.missedOnly, required this.onChanged});

  final bool missedOnly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: DesignTokens.getSubtleBackground(context, opacity: 0.07),
        borderRadius: DesignTokens.borderRadiusS,
      ),
      child: Row(
        children: [
          for (final segment in [(false, 'Tous'), (true, 'Manqués')])
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(segment.$1),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: DesignTokens.durationFast,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: missedOnly == segment.$1
                        ? (isDark ? const Color(0xFF3A3A3F) : Colors.white)
                        : Colors.transparent,
                    borderRadius: DesignTokens.borderRadiusXs,
                    boxShadow: missedOnly == segment.$1
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    segment.$2,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.merge(AppleType.subheadline)
                        .copyWith(
                          fontWeight: missedOnly == segment.$1
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: DesignTokens.getTextColorWithOpacity(
                            context,
                            missedOnly == segment.$1 ? 0.95 : 0.55,
                          ),
                        ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
