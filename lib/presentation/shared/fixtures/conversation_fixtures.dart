import 'package:iconsax/iconsax.dart';

import '../../../core/utils/chat_date_formatter.dart';
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

  static const List<ContactProfileData> employees = [
    ContactProfileData(
      name: 'Awa Traoré',
      role: 'Superviseure logistique',
      presence: PresenceStatus.online,
      phone: '+228 90 11 20 31',
      email: 'awa.traore@01supplies.com',
      location: 'Lomé - Agoè',
      memberSince: '12 janvier 2024',
    ),
    ContactProfileData(
      name: 'Kofi Adjei',
      role: 'Responsable opérations',
      presence: PresenceStatus.online,
      phone: '+228 91 42 18 77',
      email: 'kofi.adjei@01supplies.com',
      location: 'Lomé - Centre',
      memberSince: '8 septembre 2024',
    ),
    ContactProfileData(
      name: 'Fatou Diallo',
      role: 'Coordinatrice support client',
      presence: PresenceStatus.away,
      phone: '+228 92 03 44 19',
      email: 'fatou.diallo@01supplies.com',
      location: 'Lomé - Bè',
      memberSince: '3 mars 2024',
    ),
    ContactProfileData(
      name: 'Yao Kouassi',
      role: 'Agent dispatch',
      presence: PresenceStatus.online,
      phone: '+228 93 56 12 08',
      email: 'yao.kouassi@01supplies.com',
      location: 'Lomé - Tokoin',
      memberSince: '19 février 2024',
    ),
    ContactProfileData(
      name: 'Adjoa Bamba',
      role: 'Chargée des litiges',
      phone: '+228 94 21 67 35',
      email: 'adjoa.bamba@01supplies.com',
      location: 'Lomé - Adidogomé',
      memberSince: '27 avril 2024',
    ),
    ContactProfileData(
      name: 'Ibrahim Sow',
      role: 'Coordinateur livreurs',
      presence: PresenceStatus.online,
      phone: '+228 95 89 30 41',
      email: 'ibrahim.sow@01supplies.com',
      location: 'Lomé - Hedzranawoé',
      memberSince: '6 mai 2024',
    ),
    ContactProfileData(
      name: 'Mariam Cissé',
      role: 'Assistante opérations',
      phone: '+228 96 14 52 63',
      email: 'mariam.cisse@01supplies.com',
      location: 'Lomé - Avédji',
      memberSince: '14 juin 2024',
    ),
    ContactProfileData(
      name: 'Seydou Koné',
      role: 'Agent terrain',
      presence: PresenceStatus.away,
      phone: '+228 97 33 09 24',
      email: 'seydou.kone@01supplies.com',
      location: 'Lomé - Nyékonakpoè',
      memberSince: '22 juillet 2024',
    ),
    ContactProfileData(
      name: 'Aminata Barry',
      role: 'Chargée de suivi commandes',
      presence: PresenceStatus.online,
      phone: '+228 98 74 16 52',
      email: 'aminata.barry@01supplies.com',
      location: 'Lomé - Kodjoviakopé',
      memberSince: '5 août 2024',
    ),
    ContactProfileData(
      name: 'Komlan Mensah',
      role: 'Gestionnaire stock',
      phone: '+228 99 28 45 10',
      email: 'komlan.mensah@01supplies.com',
      location: 'Lomé - Akodesséwa',
      memberSince: '11 août 2024',
    ),
    ContactProfileData(
      name: 'Nadia Tchalla',
      role: 'Responsable qualité',
      presence: PresenceStatus.online,
      phone: '+228 90 66 38 12',
      email: 'nadia.tchalla@01supplies.com',
      location: 'Lomé - Kégué',
      memberSince: '18 août 2024',
    ),
    ContactProfileData(
      name: 'Essi Amouzou',
      role: 'Agent support',
      phone: '+228 91 70 24 88',
      email: 'essi.amouzou@01supplies.com',
      location: 'Lomé - Attiégou',
      memberSince: '2 septembre 2024',
    ),
    ContactProfileData(
      name: 'Mawuli Dzifa',
      role: 'Planificateur tournées',
      presence: PresenceStatus.online,
      phone: '+228 92 48 73 05',
      email: 'mawuli.dzifa@01supplies.com',
      location: 'Lomé - Hédzranawoé',
      memberSince: '9 septembre 2024',
    ),
    ContactProfileData(
      name: 'Akouvi Lawson',
      role: 'Chargée partenaires',
      presence: PresenceStatus.away,
      phone: '+228 93 81 29 64',
      email: 'akouvi.lawson@01supplies.com',
      location: 'Lomé - Cacavéli',
      memberSince: '16 septembre 2024',
    ),
    ContactProfileData(
      name: 'Kodjo Agbeko',
      role: 'Assistant dispatch',
      phone: '+228 94 15 60 33',
      email: 'kodjo.agbeko@01supplies.com',
      location: 'Lomé - Agoè',
      memberSince: '23 septembre 2024',
    ),
    ContactProfileData(
      name: 'Sika Johnson',
      role: 'Analyste opérations',
      presence: PresenceStatus.online,
      phone: '+228 95 52 84 21',
      email: 'sika.johnson@01supplies.com',
      location: 'Lomé - Djidjolé',
      memberSince: '1 octobre 2024',
    ),
    ContactProfileData(
      name: 'Fabrice Dogbé',
      role: 'Agent onboarding livreurs',
      phone: '+228 96 44 18 90',
      email: 'fabrice.dogbe@01supplies.com',
      location: 'Lomé - Totsi',
      memberSince: '8 octobre 2024',
    ),
    ContactProfileData(
      name: 'Abla Gbadamassi',
      role: 'Gestionnaire restaurants',
      presence: PresenceStatus.online,
      phone: '+228 97 62 71 43',
      email: 'abla.gbadamassi@01supplies.com',
      location: 'Lomé - Baguida',
      memberSince: '15 octobre 2024',
    ),
    ContactProfileData(
      name: 'Moussa Diarra',
      role: 'Agent contrôle livraison',
      phone: '+228 98 37 26 59',
      email: 'moussa.diarra@01supplies.com',
      location: 'Lomé - Adakpamé',
      memberSince: '22 octobre 2024',
    ),
    ContactProfileData(
      name: 'Eyram Kpodar',
      role: 'Chargé formation interne',
      presence: PresenceStatus.away,
      phone: '+228 99 73 08 14',
      email: 'eyram.kpodar@01supplies.com',
      location: 'Lomé - Nukafu',
      memberSince: '29 octobre 2024',
    ),
    ContactProfileData(
      name: 'Grace Ayité',
      role: 'Assistante commerciale',
      presence: PresenceStatus.online,
      phone: '+228 90 24 91 68',
      email: 'grace.ayite@01supplies.com',
      location: 'Lomé - Gbossimé',
      memberSince: '4 novembre 2024',
    ),
    ContactProfileData(
      name: 'Patrick Amegnran',
      role: 'Technicien support app',
      phone: '+228 91 58 33 27',
      email: 'patrick.amegnran@01supplies.com',
      location: 'Lomé - Klikamé',
      memberSince: '11 novembre 2024',
    ),
    ContactProfileData(
      name: 'Viviane Eklu',
      role: 'Chargée facturation',
      presence: PresenceStatus.online,
      phone: '+228 92 69 47 86',
      email: 'viviane.eklu@01supplies.com',
      location: 'Lomé - Tokoin',
      memberSince: '18 novembre 2024',
    ),
    ContactProfileData(
      name: 'Basile Hounkpati',
      role: 'Agent vérification commandes',
      phone: '+228 93 17 58 42',
      email: 'basile.hounkpati@01supplies.com',
      location: 'Lomé - Agoè',
      memberSince: '25 novembre 2024',
    ),
    ContactProfileData(
      name: 'Clarisse Amavi',
      role: 'Responsable relation clients',
      presence: PresenceStatus.away,
      phone: '+228 94 82 05 76',
      email: 'clarisse.amavi@01supplies.com',
      location: 'Lomé - Bè',
      memberSince: '2 décembre 2024',
    ),
    ContactProfileData(
      name: 'Didier N\'Guessan',
      role: 'Coordinateur nuit',
      phone: '+228 95 31 79 20',
      email: 'didier.nguessan@01supplies.com',
      location: 'Lomé - Adidogomé',
      memberSince: '9 décembre 2024',
    ),
    ContactProfileData(
      name: 'Reine Akakpo',
      role: 'Agent support prioritaire',
      presence: PresenceStatus.online,
      phone: '+228 96 57 40 13',
      email: 'reine.akakpo@01supplies.com',
      location: 'Lomé - Kégué',
      memberSince: '16 décembre 2024',
    ),
    ContactProfileData(
      name: 'Serge Mawussi',
      role: 'Référent livreurs',
      phone: '+228 97 04 82 65',
      email: 'serge.mawussi@01supplies.com',
      location: 'Lomé - Akodesséwa',
      memberSince: '23 décembre 2024',
    ),
    ContactProfileData(
      name: 'Rosine Dossou',
      role: 'Chargée retours clients',
      presence: PresenceStatus.online,
      phone: '+228 98 46 11 92',
      email: 'rosine.dossou@01supplies.com',
      location: 'Lomé - Cacavéli',
      memberSince: '30 décembre 2024',
    ),
    ContactProfileData(
      name: 'Jean-Marie Houngbo',
      role: 'Admin systèmes',
      phone: '+228 99 19 64 38',
      email: 'jean-marie.houngbo@01supplies.com',
      location: 'Lomé - Centre',
      memberSince: '6 janvier 2025',
    ),
    ContactProfileData(
      name: 'Linda Tété',
      role: 'Assistante RH',
      presence: PresenceStatus.away,
      phone: '+228 90 73 55 44',
      email: 'linda.tete@01supplies.com',
      location: 'Lomé - Djidjolé',
      memberSince: '13 janvier 2025',
    ),
    ContactProfileData(
      name: 'Alain Gnimadi',
      role: 'Agent inventaire',
      phone: '+228 91 36 27 51',
      email: 'alain.gnimadi@01supplies.com',
      location: 'Lomé - Totsi',
      memberSince: '20 janvier 2025',
    ),
    ContactProfileData(
      name: 'Chantal Afangbedji',
      role: 'Superviseure commandes',
      presence: PresenceStatus.online,
      phone: '+228 92 85 69 17',
      email: 'chantal.afangbedji@01supplies.com',
      location: 'Lomé - Avédji',
      memberSince: '27 janvier 2025',
    ),
    ContactProfileData(
      name: 'Ismaël Salifou',
      role: 'Agent livraison express',
      phone: '+228 93 40 92 28',
      email: 'ismael.salifou@01supplies.com',
      location: 'Lomé - Baguida',
      memberSince: '3 février 2025',
    ),
    ContactProfileData(
      name: 'Bénédicte Kossi',
      role: 'Chargée reporting',
      presence: PresenceStatus.online,
      phone: '+228 94 66 03 79',
      email: 'benedicte.kossi@01supplies.com',
      location: 'Lomé - Nukafu',
      memberSince: '10 février 2025',
    ),
    ContactProfileData(
      name: 'Raoul Tchakala',
      role: 'Responsable sécurité terrain',
      phone: '+228 95 22 48 06',
      email: 'raoul.tchakala@01supplies.com',
      location: 'Lomé - Hédzranawoé',
      memberSince: '17 février 2025',
    ),
    ContactProfileData(
      name: 'Carine Azia',
      role: 'Agent suivi restaurants',
      presence: PresenceStatus.away,
      phone: '+228 96 91 35 72',
      email: 'carine.azia@01supplies.com',
      location: 'Lomé - Agoè',
      memberSince: '24 février 2025',
    ),
    ContactProfileData(
      name: 'Gilbert Sossou',
      role: 'Coordinateur stock central',
      phone: '+228 97 18 74 39',
      email: 'gilbert.sossou@01supplies.com',
      location: 'Lomé - Akodesséwa',
      memberSince: '3 mars 2025',
    ),
    ContactProfileData(
      name: 'Nathalie Yovo',
      role: 'Chargée communication interne',
      presence: PresenceStatus.online,
      phone: '+228 98 54 20 83',
      email: 'nathalie.yovo@01supplies.com',
      location: 'Lomé - Kodjoviakopé',
      memberSince: '10 mars 2025',
    ),
    ContactProfileData(
      name: 'Oumar Ba',
      role: 'Agent contrôle qualité',
      phone: '+228 99 62 37 18',
      email: 'oumar.ba@01supplies.com',
      location: 'Lomé - Bè',
      memberSince: '17 mars 2025',
    ),
    ContactProfileData(
      name: 'Eunice Adjovi',
      role: 'Gestionnaire comptes pros',
      presence: PresenceStatus.online,
      phone: '+228 90 47 83 56',
      email: 'eunice.adjovi@01supplies.com',
      location: 'Lomé - Cacavéli',
      memberSince: '24 mars 2025',
    ),
    ContactProfileData(
      name: 'Roland Assogba',
      role: 'Agent support technique',
      phone: '+228 91 05 61 94',
      email: 'roland.assogba@01supplies.com',
      location: 'Lomé - Centre',
      memberSince: '31 mars 2025',
    ),
    ContactProfileData(
      name: 'Dédévi Komi',
      role: 'Assistante dispatch',
      presence: PresenceStatus.away,
      phone: '+228 92 76 14 30',
      email: 'dedevi.komi@01supplies.com',
      location: 'Lomé - Adakpamé',
      memberSince: '7 avril 2025',
    ),
    ContactProfileData(
      name: 'Henriette Savi',
      role: 'Responsable expérience client',
      presence: PresenceStatus.online,
      phone: '+228 93 29 88 45',
      email: 'henriette.savi@01supplies.com',
      location: 'Lomé - Tokoin',
      memberSince: '14 avril 2025',
    ),
    ContactProfileData(
      name: 'Martial Soglo',
      role: 'Agent approvisionnement',
      phone: '+228 94 51 39 70',
      email: 'martial.soglo@01supplies.com',
      location: 'Lomé - Gbossimé',
      memberSince: '21 avril 2025',
    ),
    ContactProfileData(
      name: 'Laetitia Napo',
      role: 'Chargée onboarding marchands',
      presence: PresenceStatus.online,
      phone: '+228 95 67 12 58',
      email: 'laetitia.napo@01supplies.com',
      location: 'Lomé - Klikamé',
      memberSince: '28 avril 2025',
    ),
    ContactProfileData(
      name: 'Samuel Aklobessi',
      role: 'Coordinateur service client',
      phone: '+228 96 30 75 11',
      email: 'samuel.aklobessi@01supplies.com',
      location: 'Lomé - Adidogomé',
      memberSince: '5 mai 2025',
    ),
    ContactProfileData(
      name: 'Mireille Akouete',
      role: 'Agent suivi paiements',
      presence: PresenceStatus.away,
      phone: '+228 97 44 26 89',
      email: 'mireille.akouete@01supplies.com',
      location: 'Lomé - Agoè',
      memberSince: '12 mai 2025',
    ),
    ContactProfileData(
      name: 'Arnaud Dabla',
      role: 'Superviseur terrain',
      presence: PresenceStatus.online,
      phone: '+228 98 83 57 04',
      email: 'arnaud.dabla@01supplies.com',
      location: 'Lomé - Baguida',
      memberSince: '19 mai 2025',
    ),
    ContactProfileData(
      name: 'Prisca Tossa',
      role: 'Chargée conformité',
      phone: '+228 99 35 94 62',
      email: 'prisca.tossa@01supplies.com',
      location: 'Lomé - Kégué',
      memberSince: '26 mai 2025',
    ),
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

  /// Fil de démonstration, horodaté par rapport à **l'heure courante**.
  ///
  /// Des dates figées afficheraient « 26 juin 2026 » au lieu d'« Aujourd'hui »,
  /// et les séparateurs relatifs ne se distingueraient plus les uns des autres.
  static List<ChatMessageData> get datedThread {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    ChatMessageData at(
      DateTime day,
      int hour,
      int minute, {
      required String id,
      required String text,
      required bool isMine,
      String? reaction,
      ChatReplyPreview? replyTo,
      VoiceNoteData? voice,
      MessageStatus status = MessageStatus.read,
    }) {
      final sentAt = day.add(Duration(hours: hour, minutes: minute));
      return ChatMessageData(
        id: id,
        text: text,
        timeLabel: ChatDateFormatter.timeLabel(sentAt),
        isMine: isMine,
        sentAt: sentAt,
        reaction: reaction,
        replyTo: replyTo,
        voice: voice,
        status: status,
      );
    }

    return [
      at(
        yesterday,
        9,
        28,
        id: 'm1',
        text: 'Ça me paraît bien',
        isMine: false,
        reaction: '❤️',
      ),
      at(
        yesterday,
        9,
        29,
        id: 'm2',
        text: 'Mais il faudrait revérifier les frais de livraison',
        isMine: false,
      ),
      at(
        yesterday,
        9,
        29,
        id: 'm3',
        text: "Très juste, je vérifie ça. D'autres remarques ?",
        isMine: true,
      ),
      at(
        yesterday,
        9,
        29,
        id: 'm4',
        text: 'Rien pour le moment',
        isMine: false,
      ),
      at(
        yesterday,
        9,
        30,
        id: 'm5',
        text: 'mais je vous fais un retour si besoin',
        isMine: false,
      ),
      at(
        yesterday,
        9,
        31,
        id: 'm6',
        text: 'Merci pour votre retour, Kofi',
        isMine: true,
      ),
      at(
        yesterday,
        9,
        32,
        id: 'm7',
        text: 'On avance ensemble pour que cette livraison se passe bien',
        isMine: true,
      ),
      at(today, 12, 32, id: 'm8', text: 'Bonjour', isMine: false),
      at(
        today,
        12,
        33,
        id: 'm9',
        text:
            'Je voulais faire le point sur la tournée de cet après-midi. '
            'Avez-vous eu le temps de regarder les adresses ?',
        isMine: false,
      ),
      // Note vocale : la forme d'onde est pré-calculée, comme le ferait le
      // backend à l'envoi.
      at(
        today,
        12,
        33,
        id: 'm10',
        text: 'Note vocale',
        isMine: true,
        voice: const VoiceNoteData(
          duration: Duration(seconds: 14),
          waveform: _sampleWaveform,
        ),
      ),
      // Réponse citée : la citation est figée au moment de l'envoi.
      at(
        today,
        12,
        34,
        id: 'm11',
        text: "Oui, c'est fait. Dans l'ensemble tout est cohérent",
        isMine: true,
        replyTo: const ChatReplyPreview(
          // Désigne m9 : sans identifiant, la citation s'affiche mais reste
          // inerte au toucher.
          messageId: 'm9',
          author: 'Kofi Adjei',
          text: 'Avez-vous eu le temps de regarder les adresses ?',
        ),
      ),
      at(
        today,
        12,
        35,
        id: 'm12',
        text:
            "Mais je pense qu'on devrait regrouper les deux derniers "
            'points de dépôt',
        isMine: true,
      ),
    ];
  }

  /// Forme d'onde d'exemple : une enveloppe qui monte puis retombe, plutôt que
  /// des valeurs au hasard, pour ressembler à une phrase prononcée.
  static const List<double> _sampleWaveform = [
    0.20,
    0.35,
    0.55,
    0.72,
    0.85,
    0.94,
    0.80,
    0.65,
    0.50,
    0.62,
    0.78,
    0.90,
    0.72,
    0.55,
    0.40,
    0.52,
    0.68,
    0.82,
    0.70,
    0.48,
    0.35,
    0.45,
    0.60,
    0.75,
    0.58,
    0.42,
    0.30,
    0.38,
    0.50,
    0.28,
  ];

  /// Vue à séparateurs, pour l'espace de travail desktop.
  ///
  /// Dérivée de [datedThread] plutôt que tenue en parallèle : deux listes
  /// divergeraient dès le premier message ajouté.
  static List<ChatThreadEntry> get thread {
    final out = <ChatThreadEntry>[];
    DateTime? lastDay;
    for (final message in datedThread) {
      final day = ChatDateFormatter.dayKey(message.sentAt!);
      if (lastDay != day) {
        out.add(
          ChatSeparatorEntry(
            ChatDaySeparator(ChatDateFormatter.dayLabel(message.sentAt!)),
          ),
        );
        lastDay = day;
      }
      out.add(ChatMessageEntry(message));
    }
    return out;
  }
}
