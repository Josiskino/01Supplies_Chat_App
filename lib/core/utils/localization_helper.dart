import 'package:flutter/widgets.dart';

import '../l10n/generated/app_localizations.dart';

// Re-export pour que les widgets n'aient à importer que ce fichier.
export '../l10n/generated/app_localizations.dart';

/// Accès aux traductions.
///
/// `AppLocalizations.of(context)` est nullable ; ce helper garantit une instance
/// non nulle et échoue tôt, avec un message clair, si les delegates n'ont pas
/// été branchés sur le `MaterialApp`.
class LocalizationHelper {
  LocalizationHelper._();

  static AppLocalizations of(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    assert(
      l10n != null,
      'AppLocalizations introuvable. Vérifiez que localizationsDelegates et '
      'supportedLocales sont bien passés à MaterialApp.router.',
    );
    return l10n!;
  }
}
