// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'platform_ui_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Plateforme courante.
///
/// Exposée comme provider — et non lue directement depuis `dart:io` — pour être
/// surchargeable :
///
/// ```dart
/// ProviderScope(
///   overrides: [appPlatformProvider.overrideWithValue(AppPlatform.ios)],
///   child: ...,
/// )
/// ```
///
/// C'est ce qui permet de vérifier les trois rendus depuis une seule machine.
/// `PlatformInfo` du package `adaptive_platform_ui` ne l'autorise pas : il lit
/// `Platform.isIOS` en statique.

@ProviderFor(appPlatform)
final appPlatformProvider = AppPlatformProvider._();

/// Plateforme courante.
///
/// Exposée comme provider — et non lue directement depuis `dart:io` — pour être
/// surchargeable :
///
/// ```dart
/// ProviderScope(
///   overrides: [appPlatformProvider.overrideWithValue(AppPlatform.ios)],
///   child: ...,
/// )
/// ```
///
/// C'est ce qui permet de vérifier les trois rendus depuis une seule machine.
/// `PlatformInfo` du package `adaptive_platform_ui` ne l'autorise pas : il lit
/// `Platform.isIOS` en statique.

final class AppPlatformProvider
    extends $FunctionalProvider<AppPlatform, AppPlatform, AppPlatform>
    with $Provider<AppPlatform> {
  /// Plateforme courante.
  ///
  /// Exposée comme provider — et non lue directement depuis `dart:io` — pour être
  /// surchargeable :
  ///
  /// ```dart
  /// ProviderScope(
  ///   overrides: [appPlatformProvider.overrideWithValue(AppPlatform.ios)],
  ///   child: ...,
  /// )
  /// ```
  ///
  /// C'est ce qui permet de vérifier les trois rendus depuis une seule machine.
  /// `PlatformInfo` du package `adaptive_platform_ui` ne l'autorise pas : il lit
  /// `Platform.isIOS` en statique.
  AppPlatformProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appPlatformProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appPlatformHash();

  @$internal
  @override
  $ProviderElement<AppPlatform> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppPlatform create(Ref ref) {
    return appPlatform(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppPlatform value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppPlatform>(value),
    );
  }
}

String _$appPlatformHash() => r'6b282a16af8acd5bb75ea6f09ccd9ea6e0f6e46e';

/// Implémentation d'interface correspondant à la plateforme courante.
///
/// Point d'entrée unique : aucun écran ne doit tester la plateforme lui-même.
/// Un `if (Platform.isIOS)` dans un widget est le début de la divergence
/// incontrôlée — quatre interfaces dont trois jamais testées.

@ProviderFor(platformUi)
final platformUiProvider = PlatformUiProvider._();

/// Implémentation d'interface correspondant à la plateforme courante.
///
/// Point d'entrée unique : aucun écran ne doit tester la plateforme lui-même.
/// Un `if (Platform.isIOS)` dans un widget est le début de la divergence
/// incontrôlée — quatre interfaces dont trois jamais testées.

final class PlatformUiProvider
    extends $FunctionalProvider<PlatformUi, PlatformUi, PlatformUi>
    with $Provider<PlatformUi> {
  /// Implémentation d'interface correspondant à la plateforme courante.
  ///
  /// Point d'entrée unique : aucun écran ne doit tester la plateforme lui-même.
  /// Un `if (Platform.isIOS)` dans un widget est le début de la divergence
  /// incontrôlée — quatre interfaces dont trois jamais testées.
  PlatformUiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'platformUiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$platformUiHash();

  @$internal
  @override
  $ProviderElement<PlatformUi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlatformUi create(Ref ref) {
    return platformUi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlatformUi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlatformUi>(value),
    );
  }
}

String _$platformUiHash() => r'40a1acb0e587aed306c8829dc3071ef54ef0414b';
