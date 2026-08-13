import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme/design_tokens.dart';
import '../../config/theme/glass_surfaces.dart';
import '../../config/theme/theme.dart';
import '../../core/platform/window_glass.dart';
import '../shared/fixtures/conversation_fixtures.dart';
import '../shared/models/conversation_view_data.dart';
import 'widgets/contact_profile_panel.dart';
import 'widgets/conversation_list_panel.dart';
import 'widgets/chat_thread_panel.dart';
import 'widgets/workspace_icon_rail.dart';
import 'widgets/workspace_sidebar.dart';

/// Seuils de repli des colonnes.
///
/// Les colonnes ne disparaissent pas toutes en même temps : on retire d'abord ce
/// qui n'est que de la consultation (le profil), puis la navigation secondaire.
/// La liste et le fil sont conservés le plus longtemps possible, parce que ce sont
/// les deux seules colonnes avec lesquelles un agent travaille réellement.
abstract final class WorkspaceBreakpoints {
  /// En dessous : le profil est masqué.
  static const double profileMin = 1360;

  /// En dessous : la barre latérale de navigation est masquée.
  static const double sidebarMin = 1080;

  /// En dessous : la liste des conversations est masquée (fil seul).
  static const double listMin = 820;
}

/// Espace de travail desktop, à cinq colonnes.
///
/// ```
/// ┌────┬──────────┬────────────┬──────────────┬─────────┐
/// │rail│ sections │   liste    │     fil      │ profil  │
/// └────┴──────────┴────────────┴──────────────┴─────────┘
///  56     216         288        flexible        296
/// ```
///
/// Seul le fil est flexible : les colonnes latérales gardent une largeur fixe, ce
/// qui évite que l'aperçu des conversations change de longueur à chaque
/// redimensionnement de fenêtre.
///
/// ⚠️ Les données affichées viennent de [ConversationFixtures] : la structure est
/// réelle, le contenu est une maquette. La feature messagerie remplacera la source
/// sans toucher aux widgets, qui reçoivent tous leurs données en paramètre.
class DesktopWorkspaceShell extends ConsumerStatefulWidget {
  const DesktopWorkspaceShell({super.key});

  @override
  ConsumerState<DesktopWorkspaceShell> createState() =>
      _DesktopWorkspaceShellState();
}

class _DesktopWorkspaceShellState
    extends ConsumerState<DesktopWorkspaceShell> {
  int _railIndex = 1; // Discussions
  String _sectionId = 'chats';
  String _conversationId = ConversationFixtures.conversations.first.id;
  bool _isProfileOpen = true;

  ConversationListItemData get _activeConversation {
    return ConversationFixtures.conversations.firstWhere(
      (c) => c.id == _conversationId,
      orElse: () => ConversationFixtures.conversations.first,
    );
  }

  /// Le contact affiché suit la conversation sélectionnée.
  ///
  /// Seule la première a une fiche complète dans les fixtures ; les autres
  /// reprennent son gabarit avec leur propre nom, plutôt que d'afficher un
  /// panneau vide qui laisserait croire à un bug.
  ContactProfileData get _activeContact {
    final conversation = _activeConversation;
    const base = ConversationFixtures.activeContact;
    if (conversation.name == base.name) return base;

    return ContactProfileData(
      name: conversation.name,
      role: 'Client',
      presence: conversation.presence,
      phone: base.phone,
      email:
          '${conversation.name.toLowerCase().replaceAll(' ', '.')}@exemple.com',
      location: base.location,
      memberSince: base.memberSince,
    );
  }

  @override
  Widget build(BuildContext context) {

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final showSidebar = width >= WorkspaceBreakpoints.sidebarMin;
        final showList = width >= WorkspaceBreakpoints.listMin;
        final showProfile =
            _isProfileOpen && width >= WorkspaceBreakpoints.profileMin;

        // En clair, on ne peint rien quand le vibrancy est actif : c'est le bureau
        // qui doit apparaître à travers.
        //
        // En sombre, on peint **toujours** : le matériau vibrancy de macOS y rend
        // un gris moyen qui délave l'interface entière. L'app impose donc son fond
        // violet nuit, et les panneaux deviennent du verre sur ce fond — rendu
        // maîtrisé, indépendant du fond d'écran.
        return GlassBackdrop(
          enabled: isDark || !WindowGlass.isEnabled,
          child: Row(
            children: [
              WorkspaceIconRail(
                selectedIndex: _railIndex,
                onSelected: (index) => setState(() => _railIndex = index),
                topInset: WindowGlass.titleBarInset,
                isDarkMode: isDark,
                onToggleTheme: () {
                  ref.read(themeProvider.notifier).setThemeMode(
                    isDark ? ThemeMode.light : ThemeMode.dark,
                  );
                  // Le matériau de la fenêtre porte sa propre variante : sans ce
                  // réalignement, un verre clair resterait derrière une interface
                  // sombre.
                  WindowGlass.updateForTheme(isDark: !isDark);
                },
              ),

              if (showSidebar)
                WorkspaceSidebar(
                  sections: ConversationFixtures.sections,
                  selectedSectionId: _sectionId,
                  onSectionSelected: (id) => setState(() => _sectionId = id),
                  favorites: ConversationFixtures.favorites,
                  shortcuts: ConversationFixtures.shortcuts,
                ),

              if (showList)
                ConversationListPanel(
                  conversations: ConversationFixtures.conversations,
                  selectedId: _conversationId,
                  onSelected: (id) => setState(() => _conversationId = id),
                ),

              Expanded(
                child: ChatThreadPanel(
                  contact: _activeContact,
                  entries: ConversationFixtures.thread,
                  isProfileOpen: showProfile,
                  // Le bouton reste actif même quand la fenêtre est trop étroite
                  // pour afficher le panneau : l'état est mémorisé et le profil
                  // réapparaît à l'élargissement.
                  onToggleProfile: () =>
                      setState(() => _isProfileOpen = !_isProfileOpen),
                ),
              ),

              if (showProfile)
                ContactProfilePanel(
                  contact: _activeContact,
                  onClose: () => setState(() => _isProfileOpen = false),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Largeur minimale sous laquelle l'espace de travail n'est plus tenable.
///
/// Exposée pour que la coquille de plateforme puisse retomber sur la disposition
/// mobile plutôt que de comprimer cinq colonnes dans une fenêtre de téléphone.
const double kWorkspaceMinWidth = DesignTokens.railWidth * 2 + 480;
