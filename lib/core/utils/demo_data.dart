import '../../domain/entity/messaging/conversation_list_entry.dart';

/// Substitution de données d'exemple pour les captures de fiches de store.
///
/// Les copies d'écran d'une messagerie montrent, par nature, l'écran le plus
/// parlant de l'app : la liste des conversations. Or celle-ci porte des noms,
/// des photos de profil et des extraits de messages de **clients réels** —
/// impubliables sur une page publique. Les apps de messagerie répondent toutes
/// à ce problème de la même façon : des conversations d'exemple, dans
/// l'interface authentique.
///
/// Le drapeau est une constante de compilation : hors captures, l'appel à
/// [maskEntries] est éliminé par l'arbre mort, et rien de tout ceci n'existe
/// dans le binaire distribué.
///
/// ```
/// flutter build apk --dart-define=DEMO_DATA=true …
/// ```
abstract final class DemoData {
  static const bool enabled = bool.fromEnvironment('DEMO_DATA');

  /// Agent qui répond, tel qu'il apparaît dans les citations du fil.
  static const String agentName = 'Kodjo A.';

  /// Noms d'exemple, choisis dans l'aire où l'app est utilisée pour que la
  /// capture reste plausible.
  static const List<String> _names = [
    'Aline Kponton',
    'Service Livraison Nord',
    'Marc Aveti',
    'Boutique Adidogomé',
    'Nadia Sowah',
    'Komi Dossou',
    'Restaurant Le Baobab',
    'Fatou Diarra',
    'Entrepôt Akodesséwa',
    'Yao Mensah',
    'Épicerie Bè-Kpota',
    'Sylvie Amegan',
  ];

  static const List<String> _previews = [
    'Bonjour, ma commande est-elle partie ?',
    'Le livreur est en route, il arrive dans 10 min.',
    'Merci beaucoup pour votre réactivité !',
    'Je vous confirme l\'adresse de retrait.',
    'Pouvez-vous vérifier la référence 4821 ?',
    'C\'est noté, je m\'en occupe tout de suite.',
    'La commande a bien été récupérée.',
    'Photo du colis reçu, tout est conforme.',
    'Je vous rappelle dès que le point est fait.',
    'Bonne journée et merci !',
    'Le créneau de 14 h vous convient-il ?',
    'Tout est réglé de notre côté.',
  ];

  /// Remplace nom, avatar et aperçu de chaque ligne, en conservant dates,
  /// compteurs et ordre : la capture doit montrer la disposition réelle.
  static List<ConversationListEntry> maskEntries(
    List<ConversationListEntry> entries,
  ) {
    if (!enabled) return entries;
    return [
      for (final (i, e) in entries.indexed)
        ConversationListEntry(
          conversationId: e.conversationId,
          title: _names[i % _names.length],
          preview: e.preview.isEmpty
              ? e.preview
              : _previews[i % _previews.length],
          date: e.date,
          unreadCount: e.unreadCount,
          ticketId: e.ticketId,
          isSupport: e.isSupport,
          assigneeId: e.assigneeId,
          assigneeName: e.assigneeName,
          isUnclaimed: e.isUnclaimed,
        ),
    ];
  }
}
