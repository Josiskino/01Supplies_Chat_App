import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supplies_chat_app/core/constants/app_ui_route.dart';
import 'package:supplies_chat_app/core/utils/localization_helper.dart';
import 'package:supplies_chat_app/presentation/widgets/profile_photo/profile_photo_viewer.dart';

/// Wraps a chat avatar so that tapping it opens the person's profile photo
/// full screen (with a Hero animation from the avatar).
///
/// Without a usable [photoUrl] the avatar is shown as is: no tap, no ripple,
/// so the user never lands on an empty or broken viewer. The box keeps at
/// least [minTapTarget] in both directions either way, so rows with and
/// without a photo line up.
///
/// [heroTag] must be unique within the screen (e.g. derived from the
/// message id for bubble avatars): Flutter asserts on duplicate Hero tags.
class TappableAvatar extends StatelessWidget {
  const TappableAvatar({
    super.key,
    required this.photoUrl,
    required this.name,
    required this.heroTag,
    required this.child,
    this.roleLabel,
    this.alignment = Alignment.center,
    this.enabled = true,
  });

  static const double minTapTarget = 44;

  final String? photoUrl;
  final String name;
  final String heroTag;
  final String? roleLabel;
  final Widget child;

  /// Position of the avatar inside its tap target.
  final AlignmentGeometry alignment;

  /// False to keep the avatar inert (e.g. while messages are being selected).
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim();
    final target = ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: minTapTarget,
        minHeight: minTapTarget,
      ),
      child: Align(
        alignment: alignment,
        widthFactor: 1,
        heightFactor: 1,
        child: isViewablePhotoUrl(url)
            ? Hero(
                tag: heroTag,
                flightShuttleBuilder: profilePhotoFlightShuttle,
                child: child,
              )
            : child,
      ),
    );
    if (!enabled || !isViewablePhotoUrl(url)) return target;
    void open() => context.push(
      AppUiRoute.profilePhotoViewer,
      extra: ProfilePhotoViewerArgs(
        photoUrl: url!,
        name: name,
        heroTag: heroTag,
        roleLabel: roleLabel,
      ).toExtra(),
    );
    return Semantics(
      button: true,
      label: LocalizationHelper.of(context).profilePhotoViewLabel(name),
      onTap: open,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: open,
        child: target,
      ),
    );
  }
}

/// Label shown under the name in the viewer for a backend role list
/// (`driver`, `client`, `support`…); null when no role is recognised.
String? profilePhotoRoleLabel(AppLocalizations l10n, Iterable<String> roles) {
  final normalized = roles.map((r) => r.trim().toLowerCase()).toSet();
  if (normalized.any(
    (r) => r.contains('driver') || r == 'delivery' || r == 'livreur',
  )) {
    return l10n.profilePhotoRoleDriver;
  }
  if (normalized.any(
    (r) => r.contains('support') || r.contains('admin') || r == 'agent',
  )) {
    return l10n.profilePhotoRoleSupport;
  }
  if (normalized.any(
    (r) =>
        r.contains('vendor') ||
        r.contains('store') ||
        r.contains('manager') ||
        r.contains('seller'),
  )) {
    return l10n.profilePhotoRoleVendor;
  }
  if (normalized.any((r) => r == 'client' || r == 'customer' || r == 'user')) {
    return l10n.profilePhotoRoleClient;
  }
  return null;
}
