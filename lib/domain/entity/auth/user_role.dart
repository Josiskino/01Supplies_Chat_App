/// Rôle d'un compte sur la plateforme 01Supplies.
///
/// ## Pourquoi un enum et non la chaîne du serveur
///
/// C'est ce type qui décide **qui entre dans la messagerie interne**. Porter
/// cette décision par des comparaisons de chaînes disséminées dans les écrans
/// laisserait passer la première faute de frappe, et une faute de frappe donne
/// ici l'accès à un client — exactement ce que la règle doit empêcher.
///
/// Les valeurs suivent la casse du backend (`super-admin` avec un tiret) pour
/// que la traduction depuis le JSON reste triviale.
enum UserRole {
  client('client'),
  vendor('vendor'),
  delivery('delivery'),
  admin('admin'),
  support('support'),
  superAdmin('super-admin');

  const UserRole(this.wireName);

  /// Nom exact attendu et renvoyé par l'API.
  final String wireName;

  /// Traduit un rôle serveur, ou `null` s'il est inconnu.
  ///
  /// Un rôle inconnu n'est **pas** replié sur une valeur par défaut : un nouveau
  /// rôle ajouté côté backend doit se voir refuser l'entrée plutôt que d'hériter
  /// des droits de quelqu'un d'autre.
  static UserRole? fromWire(String? value) {
    if (value == null) return null;
    for (final role in values) {
      if (role.wireName == value) return role;
    }
    return null;
  }

  /// Rôles refusés à l'application.
  ///
  /// L'app est l'outil des équipes logistique. Clients et vendeurs possèdent
  /// pourtant de vrais comptes sur la même API : sans ce filtre, leurs
  /// identifiants ouvriraient la messagerie interne et leur montreraient les
  /// échanges de tous les autres clients.
  static const Set<UserRole> _deniedRoles = {UserRole.client, UserRole.vendor};

  /// Ce compte peut-il ouvrir la messagerie interne ?
  bool get canAccessWorkspace => !_deniedRoles.contains(this);

  /// Libellé affichable, pour le profil et le répertoire.
  String get label => switch (this) {
    UserRole.client => 'Client',
    UserRole.vendor => 'Partenaire',
    UserRole.delivery => 'Livreur',
    UserRole.admin => 'Administrateur',
    UserRole.support => 'Support',
    UserRole.superAdmin => 'Super administrateur',
  };
}
