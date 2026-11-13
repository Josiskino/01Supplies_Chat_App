// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'desktop_call_alerts.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Null outside macOS and Windows.

@ProviderFor(desktopCallAlerts)
final desktopCallAlertsProvider = DesktopCallAlertsProvider._();

/// Null outside macOS and Windows.

final class DesktopCallAlertsProvider
    extends
        $FunctionalProvider<
          DesktopCallAlerts?,
          DesktopCallAlerts?,
          DesktopCallAlerts?
        >
    with $Provider<DesktopCallAlerts?> {
  /// Null outside macOS and Windows.
  DesktopCallAlertsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'desktopCallAlertsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$desktopCallAlertsHash();

  @$internal
  @override
  $ProviderElement<DesktopCallAlerts?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DesktopCallAlerts? create(Ref ref) {
    return desktopCallAlerts(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DesktopCallAlerts? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DesktopCallAlerts?>(value),
    );
  }
}

String _$desktopCallAlertsHash() => r'842397d1a0538163421474f6e5c8dea1b058da1a';

/// Agent preference: ring silently (notification and focus still happen).

@ProviderFor(DesktopRingtoneMuted)
final desktopRingtoneMutedProvider = DesktopRingtoneMutedProvider._();

/// Agent preference: ring silently (notification and focus still happen).
final class DesktopRingtoneMutedProvider
    extends $NotifierProvider<DesktopRingtoneMuted, bool> {
  /// Agent preference: ring silently (notification and focus still happen).
  DesktopRingtoneMutedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'desktopRingtoneMutedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$desktopRingtoneMutedHash();

  @$internal
  @override
  DesktopRingtoneMuted create() => DesktopRingtoneMuted();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$desktopRingtoneMutedHash() =>
    r'3e1e67feebdd240591c07f80989412583440b098';

/// Agent preference: ring silently (notification and focus still happen).

abstract class _$DesktopRingtoneMuted extends $Notifier<bool> {
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
