import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import 'package:go_router/go_router.dart';

import '../../../config/theme/design_tokens.dart';
import '../../../core/constants/app_ui_route.dart';
import '../../../core/platform/platform_ui.dart';
import '../../../core/platform/platform_ui_provider.dart';
import '../../../core/providers/messaging/support_provider.dart';
import '../../../core/utils/chat_date_formatter.dart';
import '../../../core/utils/localization_helper.dart';
import '../../shared/fixtures/conversation_fixtures.dart';
import '../../shared/models/conversation_view_data.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/platform_page.dart';
import 'widgets/conversation_row.dart';
import 'widgets/pinned_strip_header.dart';

/// Liste des fils de discussion avec les clients.
///
/// Affiche la **file d'attente commune** du support : tous les admins voient les
/// mêmes demandes, et le premier qui répond s'en saisit. Cf. `supportQueue`.
///
/// ⚠️ La bande d'épinglés vient encore de [ConversationFixtures] : la structure est réelle, le
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
    final async = ref.watch(supportQueueProvider);

    // La file est la seule source : tant qu'elle n'a pas répondu, l'écran ne
    // peut rien afficher de vrai.
    if (async.isLoading && !async.hasValue) {
      return PlatformPage(
        title: l10n.conversationsTitle,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (async.hasError && !async.hasValue) {
      return PlatformPage(
        title: l10n.conversationsTitle,
        body: EmptyStateWidget(
          icon: Iconsax.cloud_cross,
          title: 'File indisponible',
          message: async.error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }

    final conversations = [
      for (final ticket in async.value ?? const [])
        ConversationListItemData.fromTicket(
          ticket,
          // La date du dernier message, non celle du ticket : ce dernier ne
          // bouge pas au fil des échanges et figeait l'heure affichée.
          timeLabel: ChatDateFormatter.listLabel(ticket.displayDate),
        ),
    ];

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
      // `CustomScrollView` et non `ListView` : la bande d'épinglés doit rester
      // accrochée en haut tout en se repliant, ce qu'un simple premier élément
      // de liste ne sait pas faire — il défile et disparaît.
      body: CustomScrollView(
        slivers: [
          if (_pinned.isNotEmpty)
            SliverPersistentHeader(
              pinned: true,
              delegate: PinnedStripHeader(
                favorites: _pinned,
                background: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
          SliverPadding(
            // Marge **interne** reprise du `MediaQuery` : la coquille y a
            // annoncé la hauteur de la tab bar. Le dernier élément reste donc
            // atteignable, tout en défilant sous le verre — c'est ce qui donne
            // son effet à la barre.
            padding: EdgeInsets.only(
              bottom:
                  MediaQuery.paddingOf(context).bottom + DesignTokens.spaceM,
            ),
            sliver: SliverList.separated(
              itemCount: conversations.length,
              separatorBuilder: (context, index) {
                // iOS aligne le séparateur sur le texte et non sur le bord de
                // l'écran : c'est ce qui donne à la liste son rythme
                // caractéristique.
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
                final conversation = conversations[index];
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
          ),
        ],
      ),
    );
  }
}
