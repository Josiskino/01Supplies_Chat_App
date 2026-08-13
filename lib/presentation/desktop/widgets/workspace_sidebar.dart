import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../config/theme/design_tokens.dart';
import '../../../config/theme/glass_surfaces.dart';
import '../../../flavors.dart';
import '../../shared/models/conversation_view_data.dart';
import 'presence_avatar.dart';

/// Colonne 2 — navigation de l'espace de travail.
///
/// Recherche, sélecteur d'espace, sections, favoris et raccourcis. Défile en
/// entier : sur un portable, favoris et raccourcis passent sous la ligne de
/// flottaison, et ils doivent rester atteignables.
class WorkspaceSidebar extends StatelessWidget {
  const WorkspaceSidebar({
    super.key,
    required this.sections,
    required this.selectedSectionId,
    required this.onSectionSelected,
    this.favorites = const [],
    this.shortcuts = const [],
    // Le nom vient du flavor : « 01 Chat Dev » en recette, « 01 Chat » en
    // production. En dur, il affichait le nom de la plateforme (« 01 Supplies »)
    // et non celui de cette app.
    this.workspaceName,
    this.onSearchTap,
  });

  final List<WorkspaceSectionData> sections;
  final String selectedSectionId;
  final ValueChanged<String> onSectionSelected;
  final List<WorkspaceFavoriteData> favorites;
  final List<WorkspaceShortcutData> shortcuts;

  /// Nom affiché en tête de colonne. `null` retombe sur `FlavorConfig.appName`.
  final String? workspaceName;
  final VoidCallback? onSearchTap;

  static const double width = 216;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassPanel(
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: DesignTokens.spaceM),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spaceM,
              ),
              child: _SearchField(onTap: onSearchTap),
            ),
            const SizedBox(height: DesignTokens.spaceL),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spaceM,
              ),
              child: _WorkspaceSelector(
                name: workspaceName ?? FlavorConfig.appName,
              ),
            ),
            const SizedBox(height: DesignTokens.spaceM),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceS,
                ),
                children: [
                  for (final section in sections)
                    _SectionTile(
                      section: section,
                      isSelected: section.id == selectedSectionId,
                      onTap: () => onSectionSelected(section.id),
                    ),

                  if (favorites.isNotEmpty) ...[
                    const _GroupHeader(label: 'Favoris'),
                    for (final favorite in favorites)
                      _FavoriteTile(favorite: favorite),
                  ],

                  if (shortcuts.isNotEmpty) ...[
                    const _GroupHeader(label: 'Raccourcis'),
                    for (final shortcut in shortcuts)
                      _ShortcutTile(shortcut: shortcut),
                  ],

                  const SizedBox(height: DesignTokens.spaceL),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 32,
      child: TextField(
        onTap: onTap,
        style: theme.textTheme.bodySmall,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Rechercher',
          hintStyle: theme.textTheme.bodySmall?.copyWith(
            color: DesignTokens.getTextColorWithOpacity(context, 0.4),
          ),
          prefixIcon: Icon(
            Iconsax.search_normal_1,
            size: DesignTokens.iconXs,
            color: DesignTokens.getTextColorWithOpacity(context, 0.45),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          filled: true,
          fillColor: DesignTokens.getSubtleBackground(context, opacity: 0.04),
          border: OutlineInputBorder(
            borderRadius: DesignTokens.borderRadiusS,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: DesignTokens.borderRadiusS,
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _WorkspaceSelector extends StatelessWidget {
  const _WorkspaceSelector({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Icon(
            Iconsax.flash_1,
            size: 10,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        const SizedBox(width: DesignTokens.spaceS),
        Expanded(
          child: Text(
            name,
            style: theme.textTheme.labelLarge?.copyWith(fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Icon(
          Iconsax.arrow_down_1,
          size: DesignTokens.iconXs,
          color: DesignTokens.getTextColorWithOpacity(context, 0.45),
        ),
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(
        left: DesignTokens.spaceS,
        right: DesignTokens.spaceS,
        top: DesignTokens.spaceL,
        bottom: DesignTokens.spaceXs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: DesignTokens.getTextColorWithOpacity(context, 0.45),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
          Icon(
            Iconsax.add,
            size: DesignTokens.iconXs,
            color: DesignTokens.getTextColorWithOpacity(context, 0.4),
          ),
        ],
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.section,
    required this.isSelected,
    required this.onTap,
  });

  final WorkspaceSectionData section;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SidebarRow(
      isSelected: isSelected,
      onTap: onTap,
      leading: Icon(
        section.icon,
        size: DesignTokens.iconXs,
        color: isSelected
            ? theme.colorScheme.primary
            : DesignTokens.getTextColorWithOpacity(context, 0.6),
      ),
      label: section.label,
      isEmphasised: isSelected,
      trailing: WorkspaceBadge(
        count: section.badgeCount,
        label: section.badgeLabel,
      ),
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({required this.favorite});

  final WorkspaceFavoriteData favorite;

  @override
  Widget build(BuildContext context) {
    return _SidebarRow(
      isSelected: false,
      onTap: () {},
      leading: PresenceAvatar(
        name: favorite.name,
        avatarUrl: favorite.avatarUrl,
        presence: favorite.presence,
        size: 20,
      ),
      label: favorite.name,
      trailing: WorkspaceBadge(count: favorite.badgeCount),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({required this.shortcut});

  final WorkspaceShortcutData shortcut;

  @override
  Widget build(BuildContext context) {
    return _SidebarRow(
      isSelected: false,
      onTap: () {},
      leading: Icon(
        shortcut.icon,
        size: DesignTokens.iconXs,
        color: DesignTokens.getTextColorWithOpacity(context, 0.5),
      ),
      label: shortcut.label,
    );
  }
}

/// Ligne de la barre latérale.
///
/// Factorisée pour que sections, favoris et raccourcis partagent exactement la
/// même hauteur, le même retrait et le même état de survol — trois implémentations
/// séparées dériveraient au premier ajustement.
class _SidebarRow extends StatelessWidget {
  const _SidebarRow({
    required this.leading,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.trailing,
    this.isEmphasised = false,
  });

  final Widget leading;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool isEmphasised;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: DesignTokens.borderRadiusS,
        child: InkWell(
          onTap: onTap,
          borderRadius: DesignTokens.borderRadiusS,
          child: Container(
            height: 30,
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceS,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: DesignTokens.borderRadiusS,
            ),
            child: Row(
              children: [
                SizedBox(width: 20, child: Center(child: leading)),
                const SizedBox(width: DesignTokens.spaceS),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12.5,
                      color: isEmphasised
                          ? theme.colorScheme.primary
                          : DesignTokens.getTextColorWithOpacity(context, 0.8),
                      fontWeight: isEmphasised
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
