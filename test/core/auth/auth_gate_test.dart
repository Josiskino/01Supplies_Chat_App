import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/core/auth/auth_gate.dart';
import 'package:supplies_chat_app/core/constants/app_ui_route.dart';

/// Table de vérité complète du garde d'authentification.
///
/// [AuthGate.redirectFor] étant une fonction pure, tout est couvert sans widget
/// tree ni conteneur Riverpod. C'est le test le plus rentable du socle : une
/// erreur ici enferme l'utilisateur sur un écran ou expose un écran protégé.
void main() {
  group('AuthGate.redirectFor', () {
    group('statut indéterminé', () {
      test('initial : ne redirige jamais, on attend de savoir', () {
        for (final location in [
          AppUiRoute.splash,
          AppUiRoute.login,
          AppUiRoute.main,
          AppUiRoute.settings,
        ]) {
          expect(
            AuthGate.redirectFor(
              status: AuthGateStatus.initial,
              location: location,
            ),
            isNull,
            reason: 'location=$location',
          );
        }
      });

      test('loading sur le splash : on reste', () {
        expect(
          AuthGate.redirectFor(
            status: AuthGateStatus.loading,
            location: AppUiRoute.splash,
          ),
          isNull,
        );
      });
    });

    group('splash non terminé', () {
      test('retient la navigation même si le statut est connu', () {
        expect(
          AuthGate.redirectFor(
            status: AuthGateStatus.authenticated,
            location: AppUiRoute.splash,
            splashCompleted: false,
          ),
          isNull,
        );
        expect(
          AuthGate.redirectFor(
            status: AuthGateStatus.unauthenticated,
            location: AppUiRoute.splash,
            splashCompleted: false,
          ),
          isNull,
        );
      });

      test('ne retient que le splash, pas les autres écrans', () {
        expect(
          AuthGate.redirectFor(
            status: AuthGateStatus.unauthenticated,
            location: AppUiRoute.main,
            splashCompleted: false,
          ),
          AppUiRoute.login,
        );
      });
    });

    group('non authentifié', () {
      test('quitte le splash vers le login', () {
        expect(
          AuthGate.redirectFor(
            status: AuthGateStatus.unauthenticated,
            location: AppUiRoute.splash,
          ),
          AppUiRoute.login,
        );
      });

      test('reste sur le login', () {
        expect(
          AuthGate.redirectFor(
            status: AuthGateStatus.unauthenticated,
            location: AppUiRoute.login,
          ),
          isNull,
        );
      });

      test('toute route protégée renvoie au login', () {
        for (final location in [
          AppUiRoute.main,
          AppUiRoute.settings,
          AppUiRoute.conversations,
          AppUiRoute.requests,
          AppUiRoute.contacts,
          AppUiRoute.profile,
          AppUiRoute.imageViewer,
        ]) {
          expect(
            AuthGate.redirectFor(
              status: AuthGateStatus.unauthenticated,
              location: location,
            ),
            AppUiRoute.login,
            reason: 'location=$location',
          );
        }
      });
    });

    group('authentifié', () {
      test('quitte le splash vers la coquille', () {
        expect(
          AuthGate.redirectFor(
            status: AuthGateStatus.authenticated,
            location: AppUiRoute.splash,
          ),
          AppUiRoute.main,
        );
      });

      test('ne peut pas revenir sur le login', () {
        expect(
          AuthGate.redirectFor(
            status: AuthGateStatus.authenticated,
            location: AppUiRoute.login,
          ),
          AppUiRoute.main,
        );
      });

      test('laisse passer les écrans applicatifs', () {
        for (final location in [
          AppUiRoute.main,
          AppUiRoute.settings,
          AppUiRoute.imageViewer,
        ]) {
          expect(
            AuthGate.redirectFor(
              status: AuthGateStatus.authenticated,
              location: location,
            ),
            isNull,
            reason: 'location=$location',
          );
        }
      });
    });

    group('isProtected', () {
      test('splash et login sont publics, tout le reste est protégé', () {
        expect(AuthGate.isProtected(AppUiRoute.splash), isFalse);
        expect(AuthGate.isProtected(AppUiRoute.login), isFalse);
        expect(AuthGate.isProtected(AppUiRoute.main), isTrue);
        expect(AuthGate.isProtected(AppUiRoute.settings), isTrue);
        // Aucun mode invité dans cette app interne : une route inconnue est
        // protégée par défaut, jamais l'inverse.
        expect(AuthGate.isProtected('/route-inconnue'), isTrue);
      });
    });
  });
}
