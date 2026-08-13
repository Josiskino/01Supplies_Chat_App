import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

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
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final String userName;

  /// Place réservée aux boutons système de macOS quand le contenu s'étend sous la
  /// barre de titre.
  final double topInset;

  final VoidCallback? onToggleTheme;
  final bool isDarkMode;

  /// Largeur du rail.
  ///
  /// Doit rester >= [WindowGlass.windowButtonsWidth] : sur macOS, les trois
  /// boutons système flottent au-dessus de cette colonne, et un rail plus étroit
  /// les laisserait déborder sur la navigation — où ils capteraient le clic.
  static const double width = 64;

  static const List<({IconData icon, String tooltip, bool hasDot})> _entries = [
    (icon: Iconsax.home_2, tooltip: 'Accueil', hasDot: false),
    (icon: Iconsax.message_text, tooltip: 'Discussions', hasDot: true),
    (icon: Iconsax.task_square, tooltip: 'Demandes', hasDot: false),
    (icon: Iconsax.calendar_1, tooltip: 'Planning', hasDot: false),
    (icon: Iconsax.chart_2, tooltip: 'Supervision', hasDot: false),
    (icon: Iconsax.folder_2, tooltip: 'Documents', hasDot: false),
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
                          icon: _entries[i].icon,
                          tooltip: _entries[i].tooltip,
                          hasDot: _entries[i].hasDot,
                          isSelected: selectedIndex == i,
                          onTap: () => onSelected(i),
                        ),
                    ],
                  ),
                ),
              ),

              // Bascule clair/sombre. Ce n'est pas sur la maquette, mais l'effet de
              // verre change radicalement d'aspect entre les deux thèmes : y accéder
              // en un clic évite de passer par les réglages pour comparer.
              if (onToggleTheme != null)
                _RailIcon(
                  icon: isDarkMode ? Iconsax.sun_1 : Iconsax.moon,
                  tooltip: isDarkMode ? 'Thème clair' : 'Thème sombre',
                  isSelected: false,
                  onTap: onToggleTheme!,
                ),

              // Réglages et compte, ancrés en bas comme sur la maquette.
              _RailIcon(
                icon: Iconsax.setting_2,
                tooltip: 'Réglages',
                isSelected: false,
                onTap: () {},
              ),
              const SizedBox(height: DesignTokens.spaceS),
              Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.spaceM),
                child: PresenceAvatar(
                  name: userName.isEmpty ? 'Agent' : userName,
                  size: DesignTokens.avatarS,
                  presence: PresenceStatus.online,
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
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onTap,
    this.hasDot = false,
  });

  final IconData icon;
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
                  if (hasDot)
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
