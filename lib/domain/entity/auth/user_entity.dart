import 'user_role.dart';

/// Un compte utilisateur, tel que l'application le manipule.
class UserEntity {
  const UserEntity({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.phones = const [],
    this.avatarUrl,
    this.isVerified = false,
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;

  /// Nul quand le serveur annonce un rôle que cette version ne connaît pas.
  ///
  /// Traité comme un refus d'accès plutôt que comme une valeur par défaut :
  /// cf. [UserRole.fromWire].
  final UserRole? role;

  final List<String> phones;
  final String? avatarUrl;
  final bool isVerified;

  /// Nom d'affichage, avec repli sur l'adresse e-mail.
  ///
  /// Un compte de service peut n'avoir ni prénom ni nom ; afficher une chaîne
  /// vide dans le fil de discussion serait pire qu'une adresse.
  String get displayName {
    final full = '$firstName $lastName'.trim();
    return full.isEmpty ? email : full;
  }

  /// Initiales pour l'avatar de repli.
  String get initials {
    final parts = [
      firstName,
      lastName,
    ].where((p) => p.trim().isNotEmpty).toList();
    if (parts.isEmpty) return email.isEmpty ? '?' : email[0].toUpperCase();
    return parts.map((p) => p.trim()[0].toUpperCase()).take(2).join();
  }

  /// Ce compte a-t-il le droit d'utiliser la messagerie interne ?
  bool get canAccessWorkspace => role?.canAccessWorkspace ?? false;

  UserEntity copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    UserRole? role,
    List<String>? phones,
    String? avatarUrl,
    bool? isVerified,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      phones: phones ?? this.phones,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

/// Un jeton et sa date d'expiration.
class AuthTokenEntity {
  const AuthTokenEntity({required this.token, required this.expiresAt});

  final String token;
  final DateTime? expiresAt;
}

/// Session ouverte : l'utilisateur et ses deux jetons.
class AuthSessionEntity {
  const AuthSessionEntity({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final UserEntity user;
  final AuthTokenEntity accessToken;
  final AuthTokenEntity refreshToken;
}
