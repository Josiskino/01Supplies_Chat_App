import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/theme/design_tokens.dart';
import '../../../../core/platform/platform_ui.dart';
import '../../../../core/platform/platform_ui_provider.dart';
import '../../../shared/models/conversation_view_data.dart';
import '../../../widgets/common/context_actions_panel.dart';
import '../../../widgets/inbox/inbox_conversation_tile.dart';

/// One row of the phone conversation list.
///
/// The layout is shared with the desktop column ([InboxConversationTile]);
/// iOS only adds its type ramp and the trailing chevron. This widget owns the
/// long-press actions.
class ConversationRow extends ConsumerWidget {
  const ConversationRow({
    super.key,
    required this.data,
    required this.onTap,
    this.onArchive,
    this.onMarkRead,
    this.onDelete,
    this.onTogglePin,
    this.isPinned = false,
  });

  final ConversationListItemData data;
  final VoidCallback onTap;
  final VoidCallback? onArchive;
  final VoidCallback? onMarkRead;
  final VoidCallback? onDelete;

  /// Épingle ou détache la conversation : les épinglées coiffent la liste.
  final VoidCallback? onTogglePin;
  final bool isPinned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platformUi = ref.watch(platformUiProvider);
    final isApple = platformUi.platform.isApple;

    final row = InboxConversationTile(
      data: data,
      onTap: onTap,
      showChevron: isApple,
      appleTypography: isApple,
    );

    final actions = <PlatformMenuAction>[
      PlatformMenuAction(
        label: data.hasUnread ? 'Marquer comme lu' : 'Marquer comme non lu',
        icon: data.hasUnread ? Iconsax.tick_circle : Iconsax.message_notif,
        sfSymbol: data.hasUnread ? 'envelope.open' : 'envelope.badge',
        onPressed: onMarkRead ?? () {},
      ),
      PlatformMenuAction(
        label: isPinned ? 'Retirer des épinglés' : 'Épingler',
        icon: isPinned ? Iconsax.arrow_down : Iconsax.arrow_up_2,
        sfSymbol: isPinned ? 'pin.slash' : 'pin',
        onPressed: onTogglePin ?? () {},
      ),
      PlatformMenuAction(
        label: 'Archiver',
        icon: Iconsax.archive_1,
        sfSymbol: 'archivebox',
        onPressed: onArchive ?? () {},
      ),
      PlatformMenuAction(
        label: 'Supprimer',
        icon: Iconsax.trash,
        sfSymbol: 'trash',
        isDestructive: true,
        onPressed: onDelete ?? () {},
      ),
    ];

    // Le même panneau que le fil de discussion, et non `CupertinoContextMenu` :
    // celui-ci extrait son enfant de l'arbre, ce qui lui fait perdre ses
    // contraintes de largeur et demandait un contournement par appelant. Un
    // seul panneau pour les deux écrans, c'est aussi un seul comportement à
    // tenir.
    return GestureDetector(
      onLongPress: () => showContextActions(
        context: context,
        preview: ConstrainedBox(
          // L'aperçu est borné : hors de la liste, la ligne n'a plus de largeur
          // imposée et s'étalerait sur tout l'écran.
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width - DesignTokens.spaceXxl,
          ),
          child: row,
        ),
        actions: actions,
      ),
      child: row,
    );
  }
}
