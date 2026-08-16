import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/theme/apple_type.dart';
import '../../../../config/theme/design_tokens.dart';
import '../../../../core/platform/platform_ui.dart';
import '../../../../core/platform/platform_ui_provider.dart';
import '../../../desktop/widgets/presence_avatar.dart';
import '../../../shared/models/conversation_view_data.dart';

/// Une ligne de la liste des conversations sur mobile.
///
/// Adopte la présentation de Messages sur iOS — pastille bleue de non-lu à
/// gauche, aperçu sur deux lignes, heure et chevron à droite — et celle d'une
/// `ListTile` dense sur Android.
///
/// La divergence est ici justifiée : la liste de conversations est l'écran que
/// l'utilisateur connaît le mieux sur son téléphone, et c'est celui où un rendu
/// étranger à la plateforme se remarque immédiatement.
class ConversationRow extends ConsumerWidget {
  const ConversationRow({
    super.key,
    required this.data,
    required this.onTap,
    this.onArchive,
    this.onMarkRead,
    this.onDelete,
  });

  final ConversationListItemData data;
  final VoidCallback onTap;
  final VoidCallback? onArchive;
  final VoidCallback? onMarkRead;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platformUi = ref.watch(platformUiProvider);
    final isApple = platformUi.platform.isApple;

    final row = isApple
        ? _CupertinoConversationRow(data: data, onTap: onTap)
        : _MaterialConversationRow(data: data, onTap: onTap);

    // Le menu contextuel passe par l'abstraction : appui long et rendu iOS sur
    // iPhone, menu Material ancré ailleurs.
    return platformUi.overlays.contextMenu(
      actions: [
        PlatformMenuAction(
          label: data.hasUnread ? 'Marquer comme lu' : 'Marquer comme non lu',
          icon: data.hasUnread ? Iconsax.tick_circle : Iconsax.message_notif,
          sfSymbol: data.hasUnread ? 'envelope.open' : 'envelope.badge',
          onPressed: onMarkRead ?? () {},
        ),
        PlatformMenuAction(
          label: data.isStarred ? 'Retirer des favoris' : 'Ajouter aux favoris',
          icon: data.isStarred ? Iconsax.star_slash : Iconsax.star1,
          sfSymbol: data.isStarred ? 'star.slash' : 'star',
          onPressed: () {},
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
      ],
      child: row,
    );
  }
}

/// Présentation iOS, calquée sur l'app Messages.
class _CupertinoConversationRow extends StatelessWidget {
  const _CupertinoConversationRow({required this.data, required this.onTap});

  final ConversationListItemData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(
          left: DesignTokens.spaceS,
          right: DesignTokens.spaceL,
          // 8 pt comme iOS : à 10, la ligne dépassait de 8 pt celle de
          // Messages sans que rien ne le justifie.
          top: DesignTokens.spaceS,
          bottom: DesignTokens.spaceS,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pastille de non-lu à gauche de l'avatar : c'est la convention iOS,
            // là où Material la place à droite du nom.
            SizedBox(
              width: 20,
              child: data.hasUnread
                  ? Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
            PresenceAvatar(
              name: data.name,
              avatarUrl: data.avatarUrl,
              presence: data.presence,
              size: DesignTokens.avatarL,
            ),
            const SizedBox(width: DesignTokens.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.name,
                    style: theme.textTheme.bodyLarge?.merge(AppleType.headline),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Aucun écart entre le nom et l'aperçu : les interlignes
                  // d'iOS incluent déjà leur respiration, et 2 pt de plus
                  // suffisaient à faire dépasser la ligne de la référence.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data.isMissedCall)
                        Padding(
                          padding: const EdgeInsets.only(right: 4, top: 2),
                          child: Icon(
                            CupertinoIcons.phone_down_fill,
                            size: 13,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          data.preview,
                          // Deux lignes d'aperçu, comme Messages : une seule ligne
                          // tronque trop tôt pour juger de l'urgence d'un message.
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium
                              ?.merge(AppleType.subheadline)
                              .copyWith(
                                color: data.isMissedCall
                                    ? theme.colorScheme.error
                                    : DesignTokens.getTextColorWithOpacity(
                                        context,
                                        isDark ? 0.6 : 0.55,
                                      ),
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.spaceS),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  data.timeLabel,
                  style: theme.textTheme.bodySmall
                      ?.merge(AppleType.footnote)
                      .copyWith(
                        color: DesignTokens.getTextColorWithOpacity(
                          context,
                          0.45,
                        ),
                      ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (data.isStarred)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          CupertinoIcons.star_fill,
                          size: 12,
                          color: DesignTokens.getTextColorWithOpacity(
                            context,
                            0.35,
                          ),
                        ),
                      ),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 13,
                      color: DesignTokens.getTextColorWithOpacity(
                        context,
                        0.25,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Présentation Android : plus dense, pastille de non-lu à droite du nom.
class _MaterialConversationRow extends StatelessWidget {
  const _MaterialConversationRow({required this.data, required this.onTap});

  final ConversationListItemData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // `Material` explicite : `InkWell` exige un ancêtre Material pour dessiner son
    // onde. Compter sur le `Scaffold` de l'écran rend le widget dépendant de son
    // contexte d'utilisation — et le fait planter dès qu'on le place dans un
    // overlay, une feuille modale ou un test. L'app cliente a déjà connu ce crash.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spaceL,
            vertical: DesignTokens.spaceM,
          ),
          child: Row(
            children: [
              PresenceAvatar(
                name: data.name,
                avatarUrl: data.avatarUrl,
                presence: data.presence,
                size: DesignTokens.avatarL,
              ),
              const SizedBox(width: DesignTokens.spaceL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: data.hasUnread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          data.timeLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: data.hasUnread
                                ? theme.colorScheme.primary
                                : DesignTokens.getTextColorWithOpacity(
                                    context,
                                    0.45,
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (data.isMissedCall)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Iconsax.call_slash,
                              size: 13,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            data.preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: data.isMissedCall
                                  ? theme.colorScheme.error
                                  : DesignTokens.getTextColorWithOpacity(
                                      context,
                                      0.55,
                                    ),
                            ),
                          ),
                        ),
                        if (data.hasUnread)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        if (data.isStarred)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Icon(
                              Iconsax.star1,
                              size: 12,
                              color: DesignTokens.getTextColorWithOpacity(
                                context,
                                0.35,
                              ),
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
    );
  }
}
