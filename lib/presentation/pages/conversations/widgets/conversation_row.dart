import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/theme/apple_type.dart';
import '../../../../config/theme/design_tokens.dart';
import '../../../widgets/common/context_actions_panel.dart';
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

    final row = isApple
        ? _CupertinoConversationRow(data: data, onTap: onTap)
        : _MaterialConversationRow(data: data, onTap: onTap);

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
            const SizedBox(width: DesignTokens.spaceS),
            PresenceAvatar(
              name: data.name,
              avatarUrl: data.avatarUrl,
              // Pas de pastille de présence dans la liste : elle se logeait sur
              // le bord de l'avatar, où l'œil la confondait avec le point de
              // non-lu. Le statut reste visible sur la fiche du contact et en
              // tête de conversation, là où il sert vraiment.
              presence: PresenceStatus.offline,
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
                          data.kindLabel == null
                              ? data.preview
                              : '${data.kindLabel} · ${data.preview}',
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
                        // L'heure se teinte quand il reste des non-lus : le
                        // compteur en dessous n'est plus la seule chose à
                        // remarquer dans une liste de trente lignes.
                        color: data.unreadCount > 0
                            ? theme.colorScheme.primary
                            : DesignTokens.getTextColorWithOpacity(
                                context,
                                0.45,
                              ),
                      ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (data.unreadCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: _UnreadBadge(count: data.unreadCount),
                      ),
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
                            data.kindLabel == null
                                ? data.preview
                                : '${data.kindLabel} · ${data.preview}',
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

/// Compteur de messages non lus.
///
/// Remplace le point de non-lu : à surface presque égale, il dit *combien* de
/// messages attendent, ce qu'un point ne pouvait pas.
///
/// La pastille est un rectangle très arrondi et non un cercle fixe : au-delà de
/// deux chiffres, un cercle force soit un texte rogné, soit un disque
/// disproportionné. La largeur suit le contenu, la hauteur reste constante.
class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  static const double _height = 20;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: _height,
      constraints: const BoxConstraints(minWidth: _height),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(_height / 2),
      ),
      child: Text(
        // Au-delà de 99, le nombre exact n'aide plus personne à décider quoi
        // ouvrir en premier.
        count > 99 ? '99+' : '$count',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontSize: 12,
          height: 1,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
