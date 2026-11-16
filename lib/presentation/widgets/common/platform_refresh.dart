import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/platform_ui_provider.dart';

/// Top-anchored scroll view with the platform's pull-to-refresh control:
/// `CupertinoSliverRefreshControl` on iOS, `RefreshIndicator` elsewhere.
///
/// [onRefresh] must complete once the data has arrived, and must not throw:
/// screens report failures through `PlatformOverlays.notify`.
class PlatformRefreshScrollView extends ConsumerWidget {
  const PlatformRefreshScrollView({
    super.key,
    required this.onRefresh,
    required this.slivers,
    this.controller,
    this.restorationId,
  });

  final Future<void> Function() onRefresh;
  final List<Widget> slivers;
  final ScrollController? controller;
  final String? restorationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(platformUiProvider)
        .controls
        .refreshableScrollView(
          onRefresh: onRefresh,
          slivers: slivers,
          controller: controller,
          restorationId: restorationId,
        );
  }
}

/// Pull-to-refresh around a bottom-anchored (`reverse: true`) list, fired by
/// a pull-down at the visual top. See `PlatformControls.reversedRefresh`.
class PlatformReversedRefresh extends ConsumerWidget {
  const PlatformReversedRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(platformUiProvider)
        .controls
        .reversedRefresh(onRefresh: onRefresh, child: child);
  }
}
