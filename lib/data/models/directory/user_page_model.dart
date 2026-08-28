import '../auth/user_model.dart';

/// Une page du répertoire.
///
/// `GET /users` n'enveloppe pas sa liste comme le reste de l'API : au lieu d'un
/// `data` tableau et d'un `meta`, il renvoie `data: {users, total, pages}`. Ce
/// modèle absorbe cette irrégularité pour que les appelants n'aient pas à la
/// connaître.
class UserPageModel {
  const UserPageModel({
    required this.users,
    required this.total,
    required this.pages,
  });

  final List<UserModel> users;
  final int total;
  final int pages;

  factory UserPageModel.fromJson(Map<String, dynamic> json) {
    final raw = json['users'];
    return UserPageModel(
      users: raw is List
          ? raw
                .whereType<Map>()
                .map((e) => UserModel.fromJson(e.cast<String, dynamic>()))
                .toList()
          : const [],
      total: (json['total'] as num?)?.toInt() ?? 0,
      pages: (json['pages'] as num?)?.toInt() ?? 0,
    );
  }
}
