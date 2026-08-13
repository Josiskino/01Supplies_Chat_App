import 'bootstrap.dart';
import 'flavors.dart';

/// Point d'entrée par défaut (= production).
///
/// Les flavors ont leurs propres entrypoints : `main_development.dart`,
/// `main_staging.dart`, `main_production.dart`. Ce fichier est conservé pour la
/// compatibilité des outils qui ciblent `lib/main.dart` par défaut.
Future<void> main() => bootstrap(Flavor.production);
