import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import 'package:go_router/go_router.dart';

import '../../../config/theme/design_tokens.dart';
import '../../../core/constants/app_ui_route.dart';
import '../../../core/platform/platform_ui.dart';
import '../../../core/platform/platform_ui_provider.dart';
import '../../../core/utils/localization_helper.dart';
import '../../desktop/widgets/presence_avatar.dart';
import '../../shared/fixtures/conversation_fixtures.dart';
import '../../shared/models/conversation_view_data.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/platform_page.dart';
import 'widgets/conversation_row.dart';

/// Liste des fils de discussion avec les clients.
///
/// ⚠️ Les données viennent de [ConversationFixtures] : la structure est réelle, le
/// contenu est une maquette. La feature messagerie remplacera la source par un
/// provider sans toucher à la présentation.
class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  bool _isEditing = false;

  /// Conversations mises en avant, présentées en pastilles au-dessus de la liste.
  ///
  /// Reprend les favoris : sur mobile, atteindre un contact fréquent en un tap
  /// vaut mieux que de le chercher dans une liste de trente fils.
  List<WorkspaceFavoriteData> get _pinned =>
      ConversationFixtures.favorites.take(4).toList();

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationHelper.of(context);
    final platformUi = ref.watch(platformUiProvider);
    final isApple = platformUi.platform.isApple;
    const conversations = ConversationFixtures.conversations;

    if (conversations.isEmpty) {
      return PlatformPage(
        title: l10n.conversationsTitle,
        body: EmptyStateWidget(
          icon: Iconsax.message,
          title: l10n.conversationsEmptyTitle,
          message: l10n.conversationsEmptyMessage,
        ),
      );
    }

    return PlatformPage(
      title: l10n.conversationsTitle,
      actions: [
        PlatformAction(
          icon: _isEditing ? Iconsax.tick_circle : Iconsax.edit_2,
          sfSymbol: _isEditing ? 'checkmark' : 'square.and.pencil',
          label: _isEditing ? 'Terminer' : 'Modifier',
          onPressed: () => setState(() => _isEditing = !_isEditing),
        ),
      ],
      body: ListView.separated(
        // Marge **interne** reprise du `MediaQuery` : la coquille y a annoncé la
        // hauteur de la tab bar. Le dernier élément reste donc atteignable, tout
        // en défilant sous le verre — c'est ce qui donne son effet à la barre.
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + DesignTokens.spaceM,
        ),
        // +1 pour la bande de contacts épinglés en tête de liste.
        itemCount: conversations.length + 1,
        separatorBuilder: (context, index) {
          // Pas de séparateur sous la bande d'épinglés : elle se détache déjà par
          // sa hauteur.
          if (index == 0) return const SizedBox.shrink();

          // iOS aligne le séparateur sur le texte et non sur le bord de l'écran :
          // c'est ce qui donne à la liste son rythme caractéristique.
          return Divider(
            height: DesignTokens.borderWidthThin,
            thickness: DesignTokens.borderWidthThin,
            indent: isApple ? 88 : DesignTokens.spaceL,
            endIndent: 0,
            color: DesignTokens.getBorderColor(
              Theme.of(context).brightness == Brightness.dark,
              opacity: 0.10,
            ),
          );
        },
        itemBuilder: (context, index) {
          if (index == 0) {
            return _PinnedStrip(favorites: _pinned);
          }

          final conversation = conversations[index - 1];
          return ConversationRow(
            data: conversation,
            onTap: () => context.push(
              AppUiRoute.conversationDetailPath(conversation.id),
              extra: {'contactName': conversation.name},
            ),
            onMarkRead: () {},
            onArchive: () {},
            onDelete: () {},
          );
        },
      ),
    );
  }
}

/// Bande horizontale de contacts épinglés.
class _PinnedStrip extends StatelessWidget {
  const _PinnedStrip({required this.favorites});

  final List<WorkspaceFavoriteData> favorites;

  @override
  Widget build(BuildContext context) {
    if (favorites.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Padding(
      // Marge haute généreuse : le compteur du `Badge` est dessiné en débordement
      // de l'avatar, et la zone de défilement le rogne — ce qui tronquait le haut
      // des pastilles. `Clip.none` seul ne suffit pas, il faut aussi la place.
      padding: const EdgeInsets.only(
        top: DesignTokens.spaceL,
        bottom: DesignTokens.spaceL,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceL),
        child: Row(
          children: [
            for (final favorite in favorites)
              Padding(
                padding: const EdgeInsets.only(right: DesignTokens.spaceL),
                child: SizedBox(
                  width: 68,
                  child: Column(
                    children: [
                      Badge(
                        isLabelVisible: favorite.badgeCount > 0,
                        backgroundColor: theme.colorScheme.primary,
                        textColor: theme.colorScheme.onPrimary,
                        label: Text(
                          favorite.badgeCount > 9
                              ? '9+'
                              : '${favorite.badgeCount}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: PresenceAvatar(
                          name: favorite.name,
                          avatarUrl: favorite.avatarUrl,
                          presence: favorite.presence,
                          size: DesignTokens.avatarXl,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spaceS),
                      Text(
                        // Prénom seul : un nom complet sous une pastille de 64 px
                        // se tronque systématiquement.
                        favorite.name.split(' ').first,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 12,
                          color: DesignTokens.getTextColorWithOpacity(
                            context,
                            0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
