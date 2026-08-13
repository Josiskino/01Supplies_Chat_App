/// Environnements de build (flavors) de l'application.
///
/// Le flavor est figé à la compilation via le point d'entrée
/// (`lib/main_<flavor>.dart`), puis exposé globalement par [FlavorConfig].
///
/// C'est le seul mécanisme de flavor qui fonctionne sur les quatre plateformes
/// cibles : Android et iOS ont des flavors/schemes natifs, mais Windows n'en a
/// aucun. Passer par le point d'entrée uniformise le comportement.
enum Flavor { development, staging, production }

class FlavorConfig {
  FlavorConfig._();

  /// Flavor courant. Affecté par `bootstrap()` au démarrage.
  static late final Flavor flavor;

  static String get envFile => switch (flavor) {
    Flavor.development => '.env.development',
    Flavor.staging => '.env.staging',
    Flavor.production => '.env.production',
  };

  static String get appName => switch (flavor) {
    Flavor.development => '01 Chat Dev',
    Flavor.staging => '01 Chat Stg',
    Flavor.production => '01 Chat',
  };

  static bool get isProduction => flavor == Flavor.production;
}
