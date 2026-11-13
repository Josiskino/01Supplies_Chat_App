import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supplies_calls/support.dart';

import '../../../../core/calls/agent_calls.dart';
import '../../../../core/constants/app_ui_route.dart';
import '../../../../core/utils/localization_helper.dart';
import '../../calls/widgets/agent_call_widgets.dart';

class SupportCallbackButton extends ConsumerWidget {
  const SupportCallbackButton({
    required this.conversationId,
    required this.eligible,
    super.key,
  });
  final String conversationId;
  final bool eligible;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!eligible ||
        !ref.watch(supportCallsEnabledProvider) ||
        !ref.watch(agentCallsProvider.select((s) => s.callsEnabled))) {
      return const SizedBox.shrink();
    }
    return IconButton(
      tooltip: LocalizationHelper.of(context).callCallbackTooltip,
      icon: const Icon(Icons.phone_outlined),
      onPressed: () async {
        final calls = ref.read(agentCallsProvider);
        final router = GoRouter.of(context);
        if (calls.active?.isActive != true) {
          if (!await prepareCallMicrophone(context, ref)) return;
          unawaited(
            ref.read(agentCallActionsProvider).callback(conversationId),
          );
        }
        unawaited(router.push(AppUiRoute.call));
      },
    );
  }
}
