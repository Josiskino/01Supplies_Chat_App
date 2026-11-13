import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../config/theme/app_icons.dart';
import '../../../config/theme/design_tokens.dart';
import '../../../config/theme/glass_surfaces.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/platform/window_glass.dart';
import '../../shared/models/conversation_view_data.dart';
import 'presence_avatar.dart';

/// Colonne 1 — rail d'icônes vertical.
///
/// Navigation de premier niveau entre les grands espaces de l'app. Volontairement
/// très étroit et sans libellés : les destinations sont peu nombreuses et
/// permanentes, l'infobulle suffit à les nommer.
class WorkspaceIconRail extends StatelessWidget {
  const WorkspaceIconRail({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    this.userName = '',
    this.topInset = 0,
    this.onToggleTheme,
    this.isDarkMode = false,
    this.visibleIndices,
    this.onSettings,
    this.onContacts,
    this.onCalls,
    this.callsBadgeCount = 0,
    this.callsTooltip = '',
    this.presence = PresenceStatus.offline,
    this.presenceTooltip,
    this.onPresenceTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final String userName;

  /// Place réservée aux boutons système de macOS quand le contenu s'étend sous la
  /// barre de titre.
  final double topInset;

  final VoidCallback? onToggleTheme;
  final bool isDarkMode;
  final Set<int>? visibleIndices;
  final VoidCallback? onSettings;
  final VoidCallback? onContacts;

  /// Calls history entry. Selected when [selectedIndex] is -2.
  final VoidCallback? onCalls;
  final int callsBadgeCount;
  final String callsTooltip;

  /// Call availability of the signed-in agent, shown on the avatar.
  final PresenceStatus presence;
  final String? presenceTooltip;
  final VoidCallback? onPresenceTap;

  /// Largeur du rail.
  ///
  /// Doit rester >= [WindowGlass.windowButtonsWidth] : sur macOS, les trois
  /// boutons système flottent au-dessus de cette colonne, et un rail plus étroit
  /// les laisserait déborder sur la navigation — où ils capteraient le clic.
  static const double width = 64;

  /// Icônes prises dans la table des rôles, en variante Apple.
  ///
  /// macOS partage le langage visuel d'iOS : un rail en icônes Material à côté
  /// d'un iPhone en Cupertino donnait deux dessins pour la même destination.
  static const List<({AppIconPair icon, String tooltip, bool hasDot})>
  _entries = [
    (icon: AppIcons.home, tooltip: 'Accueil', hasDot: false),
    (icon: AppIcons.messages, tooltip: 'Discussions', hasDot: true),
    (icon: AppIcons.requests, tooltip: 'Demandes', hasDot: false),
    (icon: AppIcons.planning, tooltip: 'Planning', hasDot: false),
    (icon: AppIcons.supervision, tooltip: 'Supervision', hasDot: false),
    (icon: AppIcons.documents, tooltip: 'Documents', hasDot: false),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Plus de taches de couleur sous le verre : leur dégradé se lisait comme un
    // accident de rendu plutôt que comme une matière, et il débordait du rail sur
    // la colonne voisine — le `Stack` ne les rognait pas, et une tache de 420 px
    // dans un rail de 64 en dépassait largement. Le rail est désormais du même
    // verre que les quatre autres colonnes.
    return SizedBox(
      width: width,
      child: GlassPanel(
        width: width,
        color: GlassSurfaces.surface(isDark),
        border: BorderDirectional(
          end: BorderSide(
            color: GlassSurfaces.divider(isDark),
            width: DesignTokens.borderWidthThin,
          ),
        ),
        child: SafeArea(
          right: false,
          child: Column(
            children: [
              SizedBox(height: DesignTokens.spaceM + topInset),
              // Logo de l'app, en tête de rail.
              //
              // Affiché sans pastille de couleur derrière : le logo porte déjà ses
              // deux teintes de marque, et un fond violet les aurait mises en
              // concurrence. Sa marge transparente est en revanche compensée par
              // une taille de boîte plus grande — le dessin utile n'occupe que
              // ~71 % du PNG (cf. `assets/icon/app_icon.png`).
              Image.asset(
                AppImages.appIcon,
                // 46 px de boîte pour ~33 px de dessin utile : à 38, le logo
                // paraissait plus petit que les icônes de navigation situées
                // juste en dessous, alors qu'il doit les dominer.
                width: 46,
                height: 46,
                filterQuality: FilterQuality.medium,
              ),
              const SizedBox(height: DesignTokens.spaceXl),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (var i = 0; i < _entries.length; i++)
                        _RailIcon(
                          icon: AppIcons.of(_entries[i].icon, isApple: true),
                          tooltip: _entries[i].tooltip,
                          hasDot: _entries[i].hasDot,
                          isSelected: selectedIndex == i,
                          onTap: () => onSelected(i),
                        ),
                    ],
                  ),
                ),
              ),

              if (onCalls != null)
                _RailIcon(
                  key: const ValueKey('rail-calls'),
                  icon: CupertinoIcons.phone,
                  tooltip: callsTooltip,
                  isSelected: selectedIndex == -2,
                  badgeCount: callsBadgeCount,
                  onTap: onCalls!,
                ),
              if (onContacts != null)
                _RailIcon(
                  icon: CupertinoIcons.person_2,
                  tooltip: 'Contacts',
                  isSelected: selectedIndex == -1,
                  onTap: onContacts!,
                ),
              // Bascule clair/sombre. Ce n'est pas sur la maquette, mais l'effet de
              // verre change radicalement d'aspect entre les deux thèmes : y accéder
              // en un clic évite de passer par les réglages pour comparer.
              if (onToggleTheme != null)
                _RailIcon(
                  icon: isDarkMode
                      ? CupertinoIcons.sun_max
                      : AppIcons.of(AppIcons.theme, isApple: true),
                  tooltip: isDarkMode ? 'Thème clair' : 'Thème sombre',
                  isSelected: false,
                  onTap: onToggleTheme!,
                ),

              // Réglages et compte, ancrés en bas comme sur la maquette.
              if (onSettings != null)
                _RailIcon(
                  icon: AppIcons.of(AppIcons.settings, isApple: true),
                  tooltip: 'Réglages',
                  isSelected: false,
                  onTap: onSettings!,
                ),
              const SizedBox(height: DesignTokens.spaceS),
              Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.spaceM),
                child: Tooltip(
                  message: presenceTooltip ?? '',
                  child: InkWell(
                    key: const ValueKey('rail-presence'),
                    customBorder: const CircleBorder(),
                    onTap: onPresenceTap,
                    child: PresenceAvatar(
                      name: userName.isEmpty ? 'Agent' : userName,
                      size: DesignTokens.avatarS,
                      presence: presence,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailIcon extends StatelessWidget {
  const _RailIcon({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onTap,
    this.hasDot = false,
    this.badgeCount = 0,
  });

  final IconData icon;
  final int badgeCount;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onTap;

  /// Point de notification, sans compteur : à cette largeur, un nombre serait
  /// illisible.
  final bool hasDot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
      child: Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 400),
        child: Material(
          color: Colors.transparent,
          borderRadius: DesignTokens.borderRadiusS,
          child: InkWell(
            onTap: onTap,
            borderRadius: DesignTokens.borderRadiusS,
            child: AnimatedContainer(
              duration: DesignTokens.durationFast,
              padding: const EdgeInsets.all(DesignTokens.spaceS),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.16)
                    : Colors.transparent,
                borderRadius: DesignTokens.borderRadiusS,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: DesignTokens.iconS,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : DesignTokens.getTextColorWithOpacity(context, 0.55),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -8,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        constraints: const BoxConstraints(minWidth: 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.colorScheme.onError,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  else if (hasDot)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.secondary,
                          border: Border.all(
                            color: theme.scaffoldBackgroundColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
