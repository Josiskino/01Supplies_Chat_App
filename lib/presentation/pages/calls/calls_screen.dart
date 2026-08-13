import 'package:flutter/widgets.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/utils/localization_helper.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/platform_page.dart';

/// Historique des appels passés depuis les conversations.
class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationHelper.of(context);

    return PlatformPage(
      title: l10n.callsTitle,
      body: EmptyStateWidget(
        icon: Iconsax.call,
        title: l10n.callsEmptyTitle,
        message: l10n.callsEmptyMessage,
      ),
    );
  }
}
