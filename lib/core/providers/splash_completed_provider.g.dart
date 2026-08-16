// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'splash_completed_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Indique si l'écran de démarrage a fini de jouer son animation.
///
/// Sans ce verrou, le splash ne serait jamais visible : `bootstrap()` précharge
/// les providers avant `runApp()`, donc le redirect de GoRouter tranche dès le
/// premier frame et quitte l'écran aussitôt.
///
/// `keepAlive` : le splash ne doit se jouer qu'une fois par lancement. En
/// auto-dispose, le démontage de l'écran remettrait le drapeau à `false` et
/// rejouerait l'animation à la première redirection suivante.

@ProviderFor(SplashCompletedNotifier)
final splashCompletedProvider = SplashCompletedNotifierProvider._();

/// Indique si l'écran de démarrage a fini de jouer son animation.
///
/// Sans ce verrou, le splash ne serait jamais visible : `bootstrap()` précharge
/// les providers avant `runApp()`, donc le redirect de GoRouter tranche dès le
/// premier frame et quitte l'écran aussitôt.
///
/// `keepAlive` : le splash ne doit se jouer qu'une fois par lancement. En
/// auto-dispose, le démontage de l'écran remettrait le drapeau à `false` et
/// rejouerait l'animation à la première redirection suivante.
final class SplashCompletedNotifierProvider
    extends $NotifierProvider<SplashCompletedNotifier, bool> {
  /// Indique si l'écran de démarrage a fini de jouer son animation.
  ///
  /// Sans ce verrou, le splash ne serait jamais visible : `bootstrap()` précharge
  /// les providers avant `runApp()`, donc le redirect de GoRouter tranche dès le
  /// premier frame et quitte l'écran aussitôt.
  ///
  /// `keepAlive` : le splash ne doit se jouer qu'une fois par lancement. En
  /// auto-dispose, le démontage de l'écran remettrait le drapeau à `false` et
  /// rejouerait l'animation à la première redirection suivante.
  SplashCompletedNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'splashCompletedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$splashCompletedNotifierHash();

  @$internal
  @override
  SplashCompletedNotifier create() => SplashCompletedNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$splashCompletedNotifierHash() =>
    r'3ca7d7d6fb9302eb7bc69529a3fd76f044aaa437';

/// Indique si l'écran de démarrage a fini de jouer son animation.
///
/// Sans ce verrou, le splash ne serait jamais visible : `bootstrap()` précharge
/// les providers avant `runApp()`, donc le redirect de GoRouter tranche dès le
/// premier frame et quitte l'écran aussitôt.
///
/// `keepAlive` : le splash ne doit se jouer qu'une fois par lancement. En
/// auto-dispose, le démontage de l'écran remettrait le drapeau à `false` et
/// rejouerait l'animation à la première redirection suivante.

abstract class _$SplashCompletedNotifier extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
