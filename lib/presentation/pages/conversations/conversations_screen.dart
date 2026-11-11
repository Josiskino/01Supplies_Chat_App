import 'package:flutter/material.dart';
import '../../../core/platform/app_platform.dart';
import '../../widgets/search/custom_search_bar.dart';
import 'widgets/inbox_kind_tabs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import 'package:go_router/go_router.dart';

import '../../../config/theme/design_tokens.dart';
import '../../../core/constants/app_ui_route.dart';
import '../../../core/platform/platform_ui.dart';
import '../../../core/platform/platform_ui_provider.dart';
import '../../../core/providers/messaging/pinned_provider.dart';
import '../../../core/providers/messaging/support_provider.dart';
import '../../../core/utils/chat_date_formatter.dart';
import '../../../core/utils/localization_helper.dart';
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
/// La bande du haut montre les conversations épinglées — vide tant qu'on n'en a
/// épinglé aucune. La feature messagerie remplacera la source par un
/// provider sans toucher à la présentation.
class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen>
    with RestorationMixin {
  bool _isEditing = false;
  final _support = RestorableBool(true);
  final _search = RestorableString('');
  final _searchController = TextEditingController();
  bool get _supportSelected => _support.value;
  set _supportSelected(bool value) => _support.value = value;
  String get _query => _search.value;
  set _query(String value) => _search.value = value;

  @override
  String get restorationId => 'chat-inbox';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_support, 'support-tab');
    registerForRestoration(_search, 'query');
    _searchController.text = _search.value;
  }

  @override
  void dispose() {
    _support.dispose();
    _search.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Conversations mises en avant, présentées en pastilles au-dessus de la liste.
  ///
  /// Les conversations épinglées, telles que la bande du haut les montre.
  ///
  /// Auparavant remplie de contacts fictifs, elle ne portait rien de réel : ce
  /// sont désormais les fils qu'on a soi-même épinglés, et elle disparaît tant
  /// qu'il n'y en a aucun.
  List<WorkspaceFavoriteData> _pinnedStrip(
    List<ConversationListItemData> conversations,
    Set<String> pinnedIds,
  ) => [
    for (final c in conversations)
      if (pinnedIds.contains(c.id))
        WorkspaceFavoriteData(
          name: c.name,
          avatarUrl: c.avatarUrl,
          presence: c.presence,
          badgeCount: c.unreadCount,
        ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationHelper.of(context);
    final platformUi = ref.watch(platformUiProvider);
    final isApple = platformUi.platform.isApple;
    final isAndroid = platformUi.platform == AppPlatform.android;
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

    final pinnedIds = ref.watch(pinnedConversationsProvider);

    final conversations = [
      for (final entry in async.value ?? const [])
        if (!isAndroid ||
            ((entry.isSupport || entry.ticketId != null) == _supportSelected &&
                '${entry.title} ${entry.preview} ${entry.peerRoleLabel ?? ""}'
                    .toLowerCase()
                    .contains(_query.toLowerCase().trim())))
          ConversationListItemData.fromEntry(
            entry,
            // La date du dernier message, non celle du ticket : ce dernier ne
            // bouge pas au fil des échanges et figeait l'heure affichée.
            timeLabel: ChatDateFormatter.listLabel(entry.date),
            showPeerRole: isAndroid,
          ),
    ];

    // Les épinglées coiffent la liste, les plus récentes en tête à l'intérieur
    // de chaque groupe.
    //
    // Les deux critères sont comparés dans le **même** tri : `List.sort` n'est
    // pas stable en Dart, et trier sur le seul épinglage rebattait l'ordre
    // chronologique établi en amont — une conversation où l'on venait
    // d'écrire restait au milieu de la liste.
    final order = {
      for (var i = 0; i < conversations.length; i++) conversations[i].id: i,
    };
    conversations.sort((a, b) {
      final ap = pinnedIds.contains(a.id) ? 0 : 1;
      final bp = pinnedIds.contains(b.id) ? 0 : 1;
      if (ap != bp) return ap.compareTo(bp);
      // À épinglage égal, on conserve l'ordre reçu, déjà trié par date.
      return order[a.id]!.compareTo(order[b.id]!);
    });

    final pinned = _pinnedStrip(conversations, pinnedIds);

    if (conversations.isEmpty && !isAndroid) {
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
        restorationId: 'chat-inbox-scroll',
        slivers: [
          if (isAndroid)
            SliverToBoxAdapter(
              child: Column(
                children: [
                  InboxKindTabs(
                    supportSelected: _supportSelected,
                    supportUnread: (async.value ?? const []).any(
                      (e) =>
                          (e.isSupport || e.ticketId != null) &&
                          e.unreadCount > 0,
                    ),
                    directUnread: (async.value ?? const []).any(
                      (e) =>
                          !e.isSupport &&
                          e.ticketId == null &&
                          e.unreadCount > 0,
                    ),
                    onChanged: (value) =>
                        setState(() => _supportSelected = value),
                  ),
                  CustomSearchBar(
                    controller: _searchController,
                    hintText: 'Rechercher une conversation',
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: DesignTokens.spaceM),
                ],
              ),
            ),
          if (isAndroid && conversations.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateWidget(
                icon: Iconsax.message,
                title: l10n.conversationsEmptyTitle,
                message: l10n.conversationsEmptyMessage,
              ),
            ),
          if (pinned.isNotEmpty)
            SliverPersistentHeader(
              pinned: true,
              delegate: PinnedStripHeader(
                favorites: pinned,
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
                  isPinned: pinnedIds.contains(conversation.id),
                  onTogglePin: () => ref
                      .read(pinnedConversationsProvider.notifier)
                      .toggle(conversation.id),
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
