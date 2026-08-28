import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/data/models/auth/user_model.dart';
import 'package:supplies_chat_app/domain/entity/auth/user_role.dart';

/// La table de vérité de l'accès à la messagerie interne.
///
/// C'est la règle la plus sensible de l'application : elle seule empêche un
/// client, qui possède un compte valide sur la même API, d'ouvrir les échanges
/// internes de toute l'équipe logistique.
void main() {
  group('accès à la messagerie interne', () {
    test('les clients et vendeurs sont refusés', () {
      expect(UserRole.client.canAccessWorkspace, isFalse);
      expect(UserRole.vendor.canAccessWorkspace, isFalse);
    });

    test('les équipes 01Supplies sont admises', () {
      expect(UserRole.delivery.canAccessWorkspace, isTrue);
      expect(UserRole.admin.canAccessWorkspace, isTrue);
      expect(UserRole.support.canAccessWorkspace, isTrue);
      expect(UserRole.superAdmin.canAccessWorkspace, isTrue);
    });

    test('tout rôle est explicitement tranché', () {
      // Un rôle ajouté à l'enum sans décision d'accès ferait échouer ce test
      // plutôt que d'hériter silencieusement d'une autorisation.
      const decided = {
        UserRole.client: false,
        UserRole.vendor: false,
        UserRole.delivery: true,
        UserRole.admin: true,
        UserRole.support: true,
        UserRole.superAdmin: true,
      };
      expect(decided.keys.toSet(), UserRole.values.toSet());
      for (final entry in decided.entries) {
        expect(
          entry.key.canAccessWorkspace,
          entry.value,
          reason: '${entry.key}',
        );
      }
    });
  });

  group('traduction du rôle serveur', () {
    test('les noms de l’API sont reconnus tels quels', () {
      expect(UserRole.fromWire('admin'), UserRole.admin);
      // Le tiret compte : `superAdmin` ne s'écrit pas comme il se nomme.
      expect(UserRole.fromWire('super-admin'), UserRole.superAdmin);
    });

    test('un rôle inconnu n’ouvre aucun accès', () {
      // Un rôle ajouté côté backend ne doit pas hériter des droits d'un autre.
      expect(UserRole.fromWire('auditor'), isNull);
      expect(UserRole.fromWire(null), isNull);

      final user = UserModel.fromJson(const {
        'id': '1',
        'email': 'x@01supplies.com',
        'role': 'auditor',
      }).toEntity();
      expect(user.canAccessWorkspace, isFalse);
    });

    test('un utilisateur sans rôle est refusé', () {
      final user = UserModel.fromJson(const {
        'id': '1',
        'email': 'x@01supplies.com',
      }).toEntity();
      expect(user.role, isNull);
      expect(user.canAccessWorkspace, isFalse);
    });
  });

  group('lecture du JSON utilisateur', () {
    test('accepte _id comme id, et les téléphones sous leurs deux formes', () {
      final user = UserModel.fromJson(const {
        '_id': '507f1f77bcf86cd799439011',
        'email': 'agent@01supplies.com',
        'firstName': 'Awa',
        'lastName': 'Traoré',
        'role': 'admin',
        'phone': [
          '+22890000000',
          {'number': '+22891111111'},
        ],
      }).toEntity();

      expect(user.id, '507f1f77bcf86cd799439011');
      expect(user.phones, ['+22890000000', '+22891111111']);
      expect(user.displayName, 'Awa Traoré');
      expect(user.initials, 'AT');
    });

    test('replie le nom d’affichage sur l’e-mail quand il manque', () {
      final user = UserModel.fromJson(const {
        'id': '1',
        'email': 'service@01supplies.com',
        'role': 'support',
      }).toEntity();

      expect(user.displayName, 'service@01supplies.com');
      expect(user.initials, 'S');
    });

    test('lit l’avatar sous forme d’URL ou d’objet média', () {
      final direct = UserModel.fromJson(const {
        'id': '1',
        'email': 'a@b.c',
        'avatar': 'https://cdn/a.png',
      });
      final media = UserModel.fromJson(const {
        'id': '1',
        'email': 'a@b.c',
        'avatarMedia': {'url': 'https://cdn/b.png'},
      });

      expect(direct.toEntity().avatarUrl, 'https://cdn/a.png');
      expect(media.toEntity().avatarUrl, 'https://cdn/b.png');
    });
  });
}
