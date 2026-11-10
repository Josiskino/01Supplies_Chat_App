import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../config/theme/design_tokens.dart';
import '../../../config/theme/glass_surfaces.dart';
import '../../shared/models/conversation_view_data.dart';
import 'presence_avatar.dart';

/// Colonne 3 — liste des conversations.
class ConversationListPanel extends StatelessWidget {
  const ConversationListPanel({
    super.key,
    required this.conversations,
    required this.selectedId,
    required this.onSelected,
    this.statusFilterLabel = 'Discussions',
    this.onQueryChanged,
    this.searchFocusNode,
  });

  final List<ConversationListItemData> conversations;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final String statusFilterLabel;
  final ValueChanged<String>? onQueryChanged;
  final FocusNode? searchFocusNode;

  static const double width = 288;

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
          children: [
            Padding(
              padding: const EdgeInsets.all(DesignTokens.spaceM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(statusFilterLabel, style: theme.textTheme.titleMedium),
                  const SizedBox(height: DesignTokens.spaceS),
                  TextField(
                    focusNode: searchFocusNode,
                    onChanged: onQueryChanged,
                    decoration: const InputDecoration(
                      hintText: 'Rechercher une conversation',
                      prefixIcon: Icon(Iconsax.search_normal),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                // Marge haute explicite : la pastille de sélection de la première
                // conversation touchait sinon la barre de filtres, ce qui donnait
                // l'impression que les deux ne faisaient qu'un bloc.
                padding: const EdgeInsets.only(
                  left: DesignTokens.spaceS,
                  right: DesignTokens.spaceS,
                  top: DesignTokens.spaceS,
                  bottom: DesignTokens.spaceM,
                ),
                itemCount: conversations.length,
                itemBuilder: (context, index) {
                  final conversation = conversations[index];
                  return _ConversationTile(
                    data: conversation,
                    isSelected: conversation.id == selectedId,
                    onTap: () => onSelected(conversation.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  final ConversationListItemData data;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: DesignTokens.borderRadiusM,
        child: InkWell(
          onTap: onTap,
          borderRadius: DesignTokens.borderRadiusM,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceM,
              vertical: DesignTokens.spaceM,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: DesignTokens.borderRadiusM,
              border: isSelected
                  ? Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.25),
                      width: DesignTokens.borderWidthThin,
                    )
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PresenceAvatar(
                  name: data.name,
                  avatarUrl: data.avatarUrl,
                  presence: data.presence,
                  size: 30,
                ),
                const SizedBox(width: DesignTokens.spaceM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              data.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontSize: 13,
                                fontWeight: data.hasUnread
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (data.hasUnread)
                            Container(
                              margin: const EdgeInsets.only(left: 4),
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                        ],
                      ),
                      if (data.kindLabel != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            data.kindLabel!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (data.isMissedCall)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                Iconsax.call_slash,
                                size: 12,
                                color: theme.colorScheme.error,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              data.preview,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11.5,
                                color: data.isMissedCall
                                    ? theme.colorScheme.error
                                    : DesignTokens.getTextColorWithOpacity(
                                        context,
                                        0.55,
                                      ),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            data.timeLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10.5,
                              color: DesignTokens.getTextColorWithOpacity(
                                context,
                                0.4,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (data.isStarred)
                            Icon(
                              Iconsax.star1,
                              size: 12,
                              color: DesignTokens.getTextColorWithOpacity(
                                context,
                                0.35,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
