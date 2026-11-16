import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../config/theme/app_colors.dart';
import '../../../core/utils/localization_helper.dart';
import '../../../domain/entity/auth/user_role.dart';
import '../../desktop/widgets/presence_avatar.dart';
import '../../shared/models/conversation_view_data.dart';

/// Avatar of a conversation row, with a role indicator on its edge.
///
/// The indicator replaces the role text the rows used to repeat in their
/// preview line: customer, driver and vendor each get a color and an icon,
/// readable at a glance in a long list. Staff accounts get no indicator.
///
/// Presence is deliberately not drawn here: the API does not expose it, and a
/// dot on the avatar edge was read as an unread marker.
class InboxAvatar extends StatelessWidget {
  const InboxAvatar({
    super.key,
    required this.name,
    required this.size,
    required this.badgeSize,
    required this.ringColor,
    this.avatarUrl,
    this.role,
  });

  final String name;
  final String? avatarUrl;
  final UserRole? role;
  final double size;
  final double badgeSize;

  /// Background behind the avatar: the badge ring takes it to look cut out.
  final Color ringColor;

  static Color? colorFor(UserRole? role, {required bool isDark}) =>
      switch (role) {
        UserRole.client =>
          isDark ? AppColors.roleClientDark : AppColors.roleClientLight,
        UserRole.delivery =>
          isDark ? AppColors.roleDeliveryDark : AppColors.roleDeliveryLight,
        UserRole.vendor =>
          isDark ? AppColors.roleVendorDark : AppColors.roleVendorLight,
        _ => null,
      };

  static IconData? iconFor(UserRole? role) => switch (role) {
    UserRole.client => Iconsax.user,
    // Drivers ride motorbikes: Iconsax has no two-wheeler, so the Material
    // glyph is used (filled, readable at badge size).
    UserRole.delivery => Icons.two_wheeler,
    UserRole.vendor => Iconsax.shop,
    _ => null,
  };

  static String? labelFor(BuildContext context, UserRole? role) {
    final l10n = LocalizationHelper.of(context);
    return switch (role) {
      UserRole.client => l10n.inboxRoleClient,
      UserRole.delivery => l10n.inboxRoleDelivery,
      UserRole.vendor => l10n.inboxRoleVendor,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = colorFor(role, isDark: isDark);
    final icon = iconFor(role);
    final avatar = PresenceAvatar(
      name: name,
      avatarUrl: avatarUrl,
      presence: PresenceStatus.offline,
      size: size,
    );
    if (color == null || icon == null) return avatar;

    const ring = 2.0;
    return Semantics(
      label: labelFor(context, role),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            avatar,
            Positioned(
              right: -ring,
              bottom: -ring,
              child: Container(
                width: badgeSize + ring * 2,
                height: badgeSize + ring * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: Border.all(color: ringColor, width: ring),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: badgeSize * 0.62,
                  color: isDark ? const Color(0xFF14121F) : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
