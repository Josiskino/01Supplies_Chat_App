import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../config/theme/design_tokens.dart';
import '../../../config/theme/glass_surfaces.dart';
import '../../../core/utils/localization_helper.dart';
import '../../shared/models/conversation_view_data.dart';
import '../../widgets/inbox/inbox_conversation_tile.dart';

/// Column 3: the conversation list of the desktop workspace.
class ConversationListPanel extends StatelessWidget {
  const ConversationListPanel({
    super.key,
    required this.conversations,
    required this.selectedId,
    required this.onSelected,
    this.statusFilterLabel = 'Discussions',
    this.onQueryChanged,
    this.searchFocusNode,
    this.isLoading = false,
  });

  final List<ConversationListItemData> conversations;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final String statusFilterLabel;
  final ValueChanged<String>? onQueryChanged;
  final FocusNode? searchFocusNode;

  /// First load only: skeleton rows hold the space of the future list.
  final bool isLoading;

  static const double width = 320;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = LocalizationHelper.of(context);
    final unread = conversations.where((c) => c.unreadCount > 0).length;

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
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      statusFilterLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  if (unread > 0) ...[
                    const SizedBox(width: DesignTokens.spaceS),
                    Text(
                      '$unread',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: _SearchField(
                focusNode: searchFocusNode,
                onChanged: onQueryChanged,
                hint: l10n.inboxSearchHint,
              ),
            ),
            Expanded(
              child: isLoading && conversations.isEmpty
                  ? const _SkeletonList()
                  : conversations.isEmpty
                  ? _EmptyList(label: l10n.inboxEmpty)
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 2, bottom: 12),
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        final conversation = conversations[index];
                        return InboxConversationTile(
                          // Keyed by conversation: a reorder keeps each row's
                          // hover state with its conversation.
                          key: ValueKey(conversation.id),
                          data: conversation,
                          density: InboxDensity.desktop,
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

class _SearchField extends StatelessWidget {
  const _SearchField({required this.hint, this.focusNode, this.onChanged});

  final String hint;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide.none,
    );

    return SizedBox(
      height: 34,
      child: TextField(
        focusNode: focusNode,
        onChanged: onChanged,
        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: DesignTokens.getTextColorWithOpacity(
            context,
            isDark ? 0.07 : 0.05,
          ),
          hintText: hint,
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            color: DesignTokens.getTextColorWithOpacity(
              context,
              DesignTokens.inboxFaintOpacity,
            ),
          ),
          prefixIcon: Icon(
            Iconsax.search_normal_1,
            size: 15,
            color: DesignTokens.getTextColorWithOpacity(context, 0.45),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 34),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: border,
          enabledBorder: border,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final muted = DesignTokens.getTextColorWithOpacity(
      context,
      DesignTokens.inboxFaintOpacity,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Icon(Iconsax.message, size: 28, color: muted),
          const SizedBox(height: DesignTokens.spaceS),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: 13, color: muted),
          ),
        ],
      ),
    );
  }
}

/// Static placeholders with the exact geometry of a desktop row, so the real
/// list replaces them without any jump.
class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    final fill = DesignTokens.getTextColorWithOpacity(context, 0.06);
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(4),
      ),
    );

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 2),
      itemCount: 8,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Row(
          children: [
            Container(
              width: DesignTokens.inboxAvatarDesktop,
              height: DesignTokens.inboxAvatarDesktop,
              decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(110.0 + (index % 3) * 24, 11),
                  const SizedBox(height: 8),
                  bar(170.0 - (index % 4) * 18, 9),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
