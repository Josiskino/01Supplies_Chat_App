/// Helper de formatage des dates/heures pour les écrans de conversation.
///
/// Fournit :
/// - [dayLabel] : un libellé de jour relatif façon WhatsApp
///   ("Aujourd'hui", "Hier", "Jeudi", ou "26 juin 2026" au-delà de 6 jours) ;
/// - [timeLabel] : l'heure au format 24h ("09:44") ;
/// - [dayKey] : une clé de regroupement par jour (pour insérer les séparateurs
///   de date dans la liste des messages).
///
/// Volontairement sans dépendance à l'initialisation des locales `intl` (noms de
/// jours/mois codés en français) pour éviter tout crash `LocaleDataException`
/// selon l'ordre d'initialisation de l'app.
class ChatDateFormatter {
  ChatDateFormatter._();

  static const List<String> _jours = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];

  static const List<String> _mois = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];

  /// Libellé de jour relatif. [now] permet d'injecter l'heure courante
  /// (tests + rafraîchissement via un provider d'horloge).
  static String dayLabel(DateTime date, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final d = DateTime(date.year, date.month, date.day);
    final today = DateTime(current.year, current.month, current.day);
    final diff = today.difference(d).inDays;

    if (diff == 0) return "Aujourd'hui";
    if (diff == 1) return 'Hier';
    // Dans la semaine écoulée (avant-hier → il y a 6 jours) : nom du jour.
    if (diff >= 2 && diff <= 6) return _jours[date.weekday - 1];
    // Au-delà (ou dans le futur) : date complète.
    return '${date.day} ${_mois[date.month - 1]} ${date.year}';
  }

  /// Libellé compact pour une **liste** de conversations.
  ///
  /// Distinct de [dayLabel] : dans une liste, l'entrée du jour doit montrer son
  /// heure — c'est ce qui permet de trier du regard les échanges de la matinée —
  /// alors qu'un séparateur de fil annonce « Aujourd'hui ».
  static String listLabel(DateTime date, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final d = DateTime(date.year, date.month, date.day);
    final today = DateTime(current.year, current.month, current.day);
    final diff = today.difference(d).inDays;

    if (diff == 0) return timeLabel(date);
    if (diff == 1) return 'Hier';
    if (diff >= 2 && diff <= 6) return _jours[date.weekday - 1];
    // L'année n'est rappelée que si elle diffère : « 12 août 2024 » dans une
    // liste de l'année courante n'apprend rien et allonge la colonne.
    final base = '${date.day} ${_mois[date.month - 1]}';
    return date.year == current.year ? base : '$base ${date.year}';
  }

  /// Heure "HH:mm" (24h).
  static String timeLabel(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';

  /// Clé de regroupement par jour (minuit du jour concerné).
  static DateTime dayKey(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
