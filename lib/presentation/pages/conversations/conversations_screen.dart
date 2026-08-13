import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/utils/localization_helper.dart';
import '../../widgets/common/empty_state_widget.dart';

/// Liste des fils de discussion avec les clients.
///
/// Écran vide du socle : la feature messagerie y branchera la liste paginée, la
/// recherche et le canal temps réel.
class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationHelper.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.conversationsTitle)),
      body: EmptyStateWidget(
        icon: Iconsax.message,
        title: l10n.conversationsEmptyTitle,
        message: l10n.conversationsEmptyMessage,
      ),
    );
  }
}
