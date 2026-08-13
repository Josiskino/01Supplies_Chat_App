// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locale_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Langue de l'application. Persistée en SharedPreferences.
///
/// Le français est la langue par défaut : les équipes logistique 01Supplies
/// sont francophones.
///
/// `keepAlive` pour la même raison que le thème : préférence globale chargée de
/// façon asynchrone.

@ProviderFor(LocaleNotifier)
final localeProvider = LocaleNotifierProvider._();

/// Langue de l'application. Persistée en SharedPreferences.
///
/// Le français est la langue par défaut : les équipes logistique 01Supplies
/// sont francophones.
///
/// `keepAlive` pour la même raison que le thème : préférence globale chargée de
/// façon asynchrone.
final class LocaleNotifierProvider
    extends $NotifierProvider<LocaleNotifier, Locale> {
  /// Langue de l'application. Persistée en SharedPreferences.
  ///
  /// Le français est la langue par défaut : les équipes logistique 01Supplies
  /// sont francophones.
  ///
  /// `keepAlive` pour la même raison que le thème : préférence globale chargée de
  /// façon asynchrone.
  LocaleNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localeNotifierHash();

  @$internal
  @override
  LocaleNotifier create() => LocaleNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Locale value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Locale>(value),
    );
  }
}

String _$localeNotifierHash() => r'a4a61f51cc7bb41564c49dbe5d2e1e5079cdc4d0';

/// Langue de l'application. Persistée en SharedPreferences.
///
/// Le français est la langue par défaut : les équipes logistique 01Supplies
/// sont francophones.
///
/// `keepAlive` pour la même raison que le thème : préférence globale chargée de
/// façon asynchrone.

abstract class _$LocaleNotifier extends $Notifier<Locale> {
  Locale build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Locale, Locale>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Locale, Locale>,
              Locale,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
