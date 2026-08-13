import 'package:flutter/widgets.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/utils/localization_helper.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/platform_page.dart';

/// Annuaire des clients joignables par message.
class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationHelper.of(context);

    return PlatformPage(
      title: l10n.contactsTitle,
      body: EmptyStateWidget(
        icon: Iconsax.people,
        title: l10n.contactsEmptyTitle,
        message: l10n.contactsEmptyMessage,
      ),
    );
  }
}
