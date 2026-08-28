import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supplies_chat_app/flavors.dart';

/// Amorce l'environnement attendu par tout test qui monte un écran.
///
/// ## Pourquoi c'est nécessaire
///
/// Depuis que la session s'ouvre contre l'API, `authStatusProvider` construit la
/// chaîne complète — use case, repository, source distante, client HTTP — dès son
/// `build()`. Le client lit `BASE_URL` dans `dotenv`, que rien ne charge en test :
/// le provider partait alors en erreur et **tous** les écrans qui l'observent
/// échouaient, y compris ceux qui ne parlent pas au réseau.
///
/// Les valeurs sont volontairement fictives : aucun test unitaire ne doit
/// atteindre un vrai serveur, et une adresse inatteignable le garantit mieux
/// qu'une consigne.
void setUpTestEnvironment() {
  FlavorConfig.flavor = Flavor.development;
  SharedPreferences.setMockInitialValues({});
  dotenv.loadFromString(
    envString: '''
BASE_URL=https://tests.invalid
APP_ENV=test
X_API_KEY=test
SOCKET_URL=https://tests.invalid
PUSHER_APP_KEY=test
PUSHER_CLUSTER=eu
PUSHER_AUTH_PATH=/pusher/auth
''',
  );
}
