// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Gère le thème de l'application. L'état est persisté en SharedPreferences.
///
/// `keepAlive` : préférence globale, lue de façon asynchrone. En auto-dispose, la
/// lecture pourrait se terminer sur un provider déjà détruit, et le thème
/// repartirait sur `system` à chaque remontage de l'arbre.

@ProviderFor(ThemeNotifier)
final themeProvider = ThemeNotifierProvider._();

/// Gère le thème de l'application. L'état est persisté en SharedPreferences.
///
/// `keepAlive` : préférence globale, lue de façon asynchrone. En auto-dispose, la
/// lecture pourrait se terminer sur un provider déjà détruit, et le thème
/// repartirait sur `system` à chaque remontage de l'arbre.
final class ThemeNotifierProvider
    extends $NotifierProvider<ThemeNotifier, ThemeMode> {
  /// Gère le thème de l'application. L'état est persisté en SharedPreferences.
  ///
  /// `keepAlive` : préférence globale, lue de façon asynchrone. En auto-dispose, la
  /// lecture pourrait se terminer sur un provider déjà détruit, et le thème
  /// repartirait sur `system` à chaque remontage de l'arbre.
  ThemeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeNotifierHash();

  @$internal
  @override
  ThemeNotifier create() => ThemeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$themeNotifierHash() => r'edd1f8024711fb110b2807c0294fda5eced243a1';

/// Gère le thème de l'application. L'état est persisté en SharedPreferences.
///
/// `keepAlive` : préférence globale, lue de façon asynchrone. En auto-dispose, la
/// lecture pourrait se terminer sur un provider déjà détruit, et le thème
/// repartirait sur `system` à chaque remontage de l'arbre.

abstract class _$ThemeNotifier extends $Notifier<ThemeMode> {
  ThemeMode build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ThemeMode, ThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeMode, ThemeMode>,
              ThemeMode,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
