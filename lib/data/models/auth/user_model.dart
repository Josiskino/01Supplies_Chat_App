import '../../../domain/entity/auth/user_entity.dart';
import '../../../domain/entity/auth/user_role.dart';

/// Représentation JSON d'un utilisateur.
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    this.firstName = '',
    this.lastName = '',
    this.role,
    this.phones = const [],
    this.avatar,
    this.isVerified = false,
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? role;
  final List<String> phones;
  final String? avatar;
  final bool isVerified;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      // Le backend renvoie `id`, mais Mongo expose parfois `_id` selon le
      // point d'entrée ; accepter les deux évite un identifiant vide qui ne se
      // manifesterait qu'au premier envoi de message.
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      role: json['role']?.toString(),
      phones: _parsePhones(json['phone']),
      // `avatar` peut être une URL directe ou un objet média selon l'endpoint.
      avatar: _parseAvatar(json),
      isVerified: json['isVerified'] == true,
    );
  }

  /// Le champ `phone` est un tableau côté API, mais son contenu varie : chaînes
  /// brutes ou objets `{number: …}` selon l'ancienneté du compte.
  static List<String> _parsePhones(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) {
          if (e is String) return e;
          if (e is Map) return (e['number'] ?? e['value'] ?? '').toString();
          return '';
        })
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static String? _parseAvatar(Map<String, dynamic> json) {
    final direct = json['avatar'];
    if (direct is String && direct.isNotEmpty) return direct;
    final media = json['avatarMedia'];
    if (media is Map) {
      final url = media['url'] ?? media['secureUrl'];
      if (url is String && url.isNotEmpty) return url;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'role': role,
    'phone': phones,
    'avatar': avatar,
    'isVerified': isVerified,
  };

  UserEntity toEntity() => UserEntity(
    id: id,
    email: email,
    firstName: firstName,
    lastName: lastName,
    role: UserRole.fromWire(role),
    phones: phones,
    avatarUrl: avatar,
    isVerified: isVerified,
  );
}
