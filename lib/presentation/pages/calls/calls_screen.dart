import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../config/theme/design_tokens.dart';
import '../../../core/constants/app_ui_route.dart';
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
      body: Column(
        children: [
          Expanded(
            child: EmptyStateWidget(
              icon: Iconsax.call,
              title: l10n.callsEmptyTitle,
              message: l10n.callsEmptyMessage,
            ),
          ),
          // Point d'entrée provisoire vers l'écran d'appel, le temps que
          // l'historique existe. Sans lui, l'écran d'appel ne serait
          // atteignable que depuis une conversation.
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spaceL),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push(AppUiRoute.call),
                icon: const Icon(Iconsax.call, size: DesignTokens.iconS),
                label: const Text('Démarrer un appel d’équipe'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
