import 'package:iconsax/iconsax.dart';

import '../../shared/models/conversation_view_data.dart';

/// Données de démonstration de l'espace de travail desktop.
///
/// **À supprimer avec l'arrivée de la feature messagerie.** Ce fichier existe pour
/// que la structure à cinq colonnes soit visible et jugeable avant d'écrire la
/// couche data — et il est isolé précisément pour que sa suppression soit un
/// `rm` sans conséquence sur les widgets.
///
/// Les noms sont des clients et agents fictifs de la zone d'activité 01Supplies.
abstract final class ConversationFixtures {
  /// Sections de navigation.
  ///
  /// « Demandes » ne figure pas sur la maquette d'origine, mais les demandes de
  /// livraison sont la raison d'être de l'app : les retirer priverait les agents
  /// de leur écran de travail principal. À arbitrer.
  static const List<WorkspaceSectionData> sections = [
    WorkspaceSectionData(
      id: 'chats',
      icon: Iconsax.message,
      label: 'Discussions',
      badgeCount: 32,
    ),
    WorkspaceSectionData(
      id: 'requests',
      icon: Iconsax.box,
      label: 'Demandes',
      badgeCount: 7,
    ),
    WorkspaceSectionData(
      id: 'groups',
      icon: Iconsax.people,
      label: 'Groupes',
      badgeLabel: 'Nouveau',
    ),
    WorkspaceSectionData(
      id: 'mentions',
      icon: Iconsax.direct_notification,
      label: 'Mentions',
    ),
    WorkspaceSectionData(
      id: 'contacts',
      icon: Iconsax.profile_2user,
      label: 'Contacts',
    ),
  ];

  static const List<WorkspaceFavoriteData> favorites = [
    WorkspaceFavoriteData(
      name: 'Awa Traoré',
      badgeCount: 23,
      presence: PresenceStatus.online,
    ),
    WorkspaceFavoriteData(name: 'Kwame Mensah'),
    WorkspaceFavoriteData(
      name: 'Fatou Diallo',
      badgeCount: 4,
      presence: PresenceStatus.online,
    ),
    WorkspaceFavoriteData(name: 'Yao Kouassi'),
    WorkspaceFavoriteData(name: 'Adjoa Bamba', presence: PresenceStatus.away),
    WorkspaceFavoriteData(name: 'Ibrahim Sow'),
  ];

  static const List<WorkspaceShortcutData> shortcuts = [
    WorkspaceShortcutData(label: 'Livraisons du jour', icon: Iconsax.folder_2),
    WorkspaceShortcutData(label: 'Litiges ouverts', icon: Iconsax.folder_2),
  ];

  static const List<ConversationListItemData> conversations = [
    ConversationListItemData(
      id: 'c1',
      name: 'Kofi Adjei',
      preview: 'Kofi : Parfait, ça me convient. Il me faudrait…',
      timeLabel: '12:10',
      presence: PresenceStatus.online,
      hasUnread: true,
      unreadCount: 3,
    ),
    ConversationListItemData(
      id: 'c2',
      name: 'Awa Traoré',
      preview: 'Vous : Je pense qu\'on devrait simplifier l\'itin…',
      timeLabel: '10:21',
      presence: PresenceStatus.online,
      hasUnread: true,
      unreadCount: 12,
    ),
    ConversationListItemData(
      id: 'c3',
      name: 'Fatou Diallo',
      preview: 'Vous : Avez-vous essayé les filtres ? C\'est…',
      timeLabel: '08:43',
      isStarred: true,
    ),
    ConversationListItemData(
      id: 'c4',
      name: 'Yao Kouassi',
      preview: 'Yao : Bien reçu. Je recontacte le client pour…',
      timeLabel: 'Hier',
      presence: PresenceStatus.online,
      isStarred: true,
    ),
    ConversationListItemData(
      id: 'c5',
      name: 'Adjoa Bamba',
      preview: 'Appel manqué',
      timeLabel: '12 août',
      isMissedCall: true,
    ),
    ConversationListItemData(
      id: 'c6',
      name: 'Ibrahim Sow',
      preview: 'Vous : Pas trop mal, je voulais juste faire le…',
      timeLabel: '12 août',
      presence: PresenceStatus.online,
    ),
    ConversationListItemData(
      id: 'c7',
      name: 'Mariam Cissé',
      preview: 'Mariam : Bonne idée. Je vais tester ça et…',
      timeLabel: '11 août',
    ),
    ConversationListItemData(
      id: 'c8',
      name: 'Seydou Koné',
      preview: 'Seydou : En fait, je viens d\'en parler avec…',
      timeLabel: '11 août',
    ),
    ConversationListItemData(
      id: 'c9',
      name: 'Aminata Barry',
      preview: 'Aminata : Le colis est bien arrivé, merci !',
      timeLabel: '10 août',
    ),
  ];

  static const ContactProfileData activeContact = ContactProfileData(
    name: 'Kofi Adjei',
    role: 'Responsable logistique',
    presence: PresenceStatus.online,
    phone: '+228 90 12 34 56',
    email: 'kofi.adjei@exemple.com',
    location: 'Lomé, Togo',
    memberSince: '8 septembre 2024',
    website: 'kofiadjei.co',
  );

  static const List<ChatThreadEntry> thread = [
    ChatMessageEntry(
      ChatMessageData(
        id: 'm1',
        text: 'Ça me paraît bien',
        timeLabel: '09:28',
        isMine: false,
        reaction: '❤️',
      ),
    ),
    ChatMessageEntry(
      ChatMessageData(
        id: 'm2',
        text: 'Mais il faudrait revérifier les frais de livraison',
        timeLabel: '09:29',
        isMine: false,
      ),
    ),
    ChatMessageEntry(
      ChatMessageData(
        id: 'm3',
        text: 'Très juste, je vérifie ça. D\'autres remarques ?',
        timeLabel: '09:29',
        isMine: true,
      ),
    ),
    ChatMessageEntry(
      ChatMessageData(
        id: 'm4',
        text: 'Rien pour le moment',
        timeLabel: '09:29',
        isMine: false,
      ),
    ),
    ChatMessageEntry(
      ChatMessageData(
        id: 'm5',
        text: 'mais je vous fais un retour si besoin',
        timeLabel: '09:30',
        isMine: false,
      ),
    ),
    ChatMessageEntry(
      ChatMessageData(
        id: 'm6',
        text: 'Merci pour votre retour, Kofi',
        timeLabel: '09:31',
        isMine: true,
      ),
    ),
    ChatMessageEntry(
      ChatMessageData(
        id: 'm7',
        text: 'On avance ensemble pour que cette livraison se passe bien',
        timeLabel: '09:32',
        isMine: true,
      ),
    ),
    ChatSeparatorEntry(ChatDaySeparator('Aujourd\'hui')),
    ChatMessageEntry(
      ChatMessageData(
        id: 'm8',
        text: 'Bonjour',
        timeLabel: '12:32',
        isMine: false,
      ),
    ),
    ChatMessageEntry(
      ChatMessageData(
        id: 'm9',
        text: 'Je voulais faire le point sur la tournée de cet après-midi. '
            'Avez-vous eu le temps de regarder les adresses ?',
        timeLabel: '12:33',
        isMine: false,
      ),
    ),
    ChatMessageEntry(
      ChatMessageData(
        id: 'm10',
        text: 'Oui, c\'est fait. Dans l\'ensemble tout est cohérent',
        timeLabel: '12:33',
        isMine: true,
      ),
    ),
    ChatMessageEntry(
      ChatMessageData(
        id: 'm11',
        text: 'Mais je pense qu\'on devrait regrouper les deux derniers '
            'points de dépôt',
        timeLabel: '12:33',
        isMine: true,
      ),
    ),
    ChatMessageEntry(
      ChatMessageData(
        id: 'm12',
        text: '',
        timeLabel: '',
        isMine: false,
        isTyping: true,
      ),
    ),
  ];
}
