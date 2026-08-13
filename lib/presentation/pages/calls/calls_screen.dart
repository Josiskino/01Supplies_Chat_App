import 'package:flutter/widgets.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/utils/localization_helper.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/platform_page.dart';

/// Demandes de livraison rattachées aux conversations.
class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationHelper.of(context);

    return PlatformPage(
      title: l10n.requestsTitle,
      body: EmptyStateWidget(
        icon: Iconsax.receipt_item,
        title: l10n.requestsEmptyTitle,
        message: l10n.requestsEmptyMessage,
      ),
    );
  }
}
