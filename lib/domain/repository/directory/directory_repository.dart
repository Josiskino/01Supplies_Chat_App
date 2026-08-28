import 'package:fpdart/fpdart.dart';

import '../../../core/abstract/failure.dart';
import '../../entity/auth/user_entity.dart';
import '../../entity/auth/user_role.dart';

/// Répertoire des interlocuteurs joignables.
abstract interface class DirectoryRepository {
  Future<Either<Failure, DirectoryPage>> fetchContacts(FetchContactsParams p);
}

/// Une page du répertoire, avec de quoi savoir s'il en reste.
class DirectoryPage {
  const DirectoryPage({
    required this.contacts,
    required this.total,
    required this.pages,
  });

  final List<UserEntity> contacts;
  final int total;
  final int pages;
}

class FetchContactsParams {
  const FetchContactsParams({
    this.roles = defaultRoles,
    this.query,
    this.page = 1,
    this.limit = maxPageSize,
  });

  /// Plafond imposé par l'API : au-delà, elle répond 400.
  static const int maxPageSize = 100;

  /// Les interlocuteurs de la logistique : clients et partenaires.
  ///
  /// Ce sont eux qui écrivent, par le support ou en direct ; les collègues se
  /// trouvent par l'annuaire interne, pas ici.
  static const List<UserRole> defaultRoles = [UserRole.client, UserRole.vendor];

  final List<UserRole> roles;

  /// Recherche côté serveur. Nulle, la page complète est renvoyée.
  final String? query;

  final int page;
  final int limit;
}
