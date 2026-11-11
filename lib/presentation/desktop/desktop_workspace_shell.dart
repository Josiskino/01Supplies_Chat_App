import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../config/theme/design_tokens.dart';
import '../../config/theme/glass_surfaces.dart';
import '../../config/theme/theme.dart';
import '../../core/constants/app_ui_route.dart';
import '../../core/platform/window_glass.dart';
import '../../core/providers/auth/auth_provider.dart';
import '../../core/providers/messaging/pinned_provider.dart';
import '../../core/providers/messaging/support_provider.dart';
import '../../core/utils/chat_date_formatter.dart';
import '../pages/contacts/contacts_screen.dart';
import '../pages/conversation_detail/conversation_detail_screen.dart';
import '../shared/models/conversation_view_data.dart';
import 'widgets/contact_profile_panel.dart';
import 'widgets/conversation_list_panel.dart';
import 'widgets/workspace_icon_rail.dart';
import 'widgets/workspace_sidebar.dart';

abstract final class WorkspaceBreakpoints {
  static const double profileMin = 1360;
  static const double sidebarMin = 1080;
  static const double listMin = 820;
}

/// The desktop workspace shares its queue, thread and sending behavior with
/// the compact layout. Selection stays local to this side-by-side workspace.
class DesktopWorkspaceShell extends ConsumerStatefulWidget {
  const DesktopWorkspaceShell({super.key});

  @override
  ConsumerState<DesktopWorkspaceShell> createState() =>
      _DesktopWorkspaceShellState();
}

class _DesktopWorkspaceShellState extends ConsumerState<DesktopWorkspaceShell> {
  String _sectionId = 'chats';
  String? _conversationId;
  String _query = '';
  bool _isProfileOpen = true;
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  void _select(String id) => setState(() {
    _conversationId = id;
    _isProfileOpen = true;
  });

  void _section(String id) => setState(() {
    _sectionId = id;
    _conversationId = null;
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final queue = ref.watch(supportQueueProvider);
    final pins = ref.watch(pinnedConversationsProvider);
    final entries = [...?queue.value];
    entries.sort((a, b) {
      final pinned = (pins.contains(a.conversationId) ? 0 : 1).compareTo(
        pins.contains(b.conversationId) ? 0 : 1,
      );
      if (pinned != 0) return pinned;
      final date = b.date.compareTo(a.date);
      return date != 0 ? date : a.conversationId.compareTo(b.conversationId);
    });
    final filtered = entries.where((entry) {
      final matchesSection = switch (_sectionId) {
        'support' => entry.isSupport,
        'direct' => !entry.isSupport,
        'unread' => entry.unreadCount > 0,
        'pinned' => pins.contains(entry.conversationId),
        _ => true,
      };
      final needle = _query.trim().toLowerCase();
      return matchesSection &&
          (needle.isEmpty ||
              entry.title.toLowerCase().contains(needle) ||
              entry.preview.toLowerCase().contains(needle));
    }).toList();
    final active = entries
        .where((e) => e.conversationId == _conversationId)
        .firstOrNull;
    final contacts = _sectionId == 'contacts';

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final showSidebar = width >= WorkspaceBreakpoints.sidebarMin;
        final showList =
            !contacts &&
            (width >= WorkspaceBreakpoints.listMin || active == null);
        final showProfile =
            !contacts &&
            active != null &&
            _isProfileOpen &&
            width >= WorkspaceBreakpoints.profileMin;
        final sections = <WorkspaceSectionData>[
          WorkspaceSectionData(
            id: 'chats',
            icon: Iconsax.message,
            label: 'Discussions',
            badgeCount: entries.length,
          ),
          WorkspaceSectionData(
            id: 'support',
            icon: Iconsax.support,
            label: 'Support',
            badgeCount: entries.where((e) => e.isSupport).length,
          ),
          WorkspaceSectionData(
            id: 'direct',
            icon: Iconsax.messages,
            label: 'Directes',
            badgeCount: entries.where((e) => !e.isSupport).length,
          ),
          WorkspaceSectionData(
            id: 'unread',
            icon: Iconsax.direct_notification,
            label: 'Non lues',
            badgeCount: entries.where((e) => e.unreadCount > 0).length,
          ),
          WorkspaceSectionData(
            id: 'pinned',
            icon: Iconsax.star,
            label: 'Épinglées',
            badgeCount: entries
                .where((e) => pins.contains(e.conversationId))
                .length,
          ),
          const WorkspaceSectionData(
            id: 'contacts',
            icon: Iconsax.profile_2user,
            label: 'Contacts',
          ),
        ];
        return GlassBackdrop(
          enabled: isDark || !WindowGlass.isEnabled,
          child: Row(
            children: [
              WorkspaceIconRail(
                selectedIndex: contacts ? -1 : 1,
                visibleIndices: const {1},
                userName: ref.watch(currentUserProvider)?.displayName ?? '',
                onSelected: (_) => _section('chats'),
                onContacts: () => _section('contacts'),
                onSettings: () => context.push(AppUiRoute.settings),
                topInset: WindowGlass.titleBarInset,
                isDarkMode: isDark,
                onToggleTheme: () {
                  ref
                      .read(themeProvider.notifier)
                      .setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
                  WindowGlass.updateForTheme(isDark: !isDark);
                },
              ),
              if (showSidebar)
                WorkspaceSidebar(
                  sections: sections,
                  selectedSectionId: _sectionId,
                  onSectionSelected: _section,
                  onSearchTap: () {
                    _section('chats');
                    _searchFocus.requestFocus();
                  },
                ),
              if (showList)
                SizedBox(
                  width: width < WorkspaceBreakpoints.listMin
                      ? width - WorkspaceIconRail.width
                      : ConversationListPanel.width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (queue.hasError)
                        MaterialBanner(
                          content: const Text(
                            'Actualisation impossible. Réessayez.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  ref.invalidate(supportQueueProvider),
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      if (queue.isLoading) const LinearProgressIndicator(),
                      Expanded(
                        child: ConversationListPanel(
                          conversations: [
                            for (final entry in filtered)
                              ConversationListItemData.fromEntry(
                                entry,
                                timeLabel: ChatDateFormatter.listLabel(
                                  entry.date,
                                ),
                              ),
                          ],
                          selectedId: active?.conversationId,
                          onSelected: _select,
                          statusFilterLabel: sections
                              .firstWhere(
                                (s) => s.id == _sectionId,
                                orElse: () => sections.first,
                              )
                              .label,
                          onQueryChanged: (value) =>
                              setState(() => _query = value),
                          searchFocusNode: _searchFocus,
                        ),
                      ),
                      if (filtered.isEmpty &&
                          !queue.isLoading &&
                          !queue.hasError)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Aucune conversation'),
                        ),
                    ],
                  ),
                ),
              if (contacts)
                const Expanded(child: ContactsScreen())
              else if (width >= WorkspaceBreakpoints.listMin || active != null)
                Expanded(
                  child: active == null
                      ? const Center(
                          child: Text('Sélectionnez une conversation'),
                        )
                      : ConversationDetailScreen(
                          key: ValueKey(active.conversationId),
                          conversationId: active.conversationId,
                          contactName: active.title,
                          embedded: true,
                          onBack: width < WorkspaceBreakpoints.listMin
                              ? () => setState(() => _conversationId = null)
                              : null,
                        ),
                ),
              if (showProfile)
                ContactProfilePanel(
                  contact: ContactProfileData(
                    name: active.title,
                    avatarUrl: active.avatarUrl,
                    role: [
                      active.isSupport ? 'Support' : 'Conversation directe',
                      if (active.peerRoleLabel != null) active.peerRoleLabel!,
                    ].join(' · '),
                  ),
                  onClose: () => setState(() => _isProfileOpen = false),
                ),
            ],
          ),
        );
      },
    );
  }
}

const double kWorkspaceMinWidth = DesignTokens.railWidth * 2 + 480;
